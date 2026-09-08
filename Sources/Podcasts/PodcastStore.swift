/*****************************************************************************
 * PodcastStore.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import VLCMediaLibraryKit

@objc protocol PodcastStoreObserver {
    func podcastStore(_ store: PodcastStore, didUpdateEpisodeWithId episodeId: String)
}

final class PodcastStore: NSObject {
    static let shared = PodcastStore()

    private let episodeObservable = VLCObservable<PodcastStoreObserver>()

    private var subscriptionModel: PodcastSubscriptionModel?
    private var mediaLibraryService: MediaLibraryService?

    private var pendingCacheMediaIds: Set<VLCMLIdentifier> = []
    private var requestedArtworkEpisodeIds: Set<String> = []
    private var requestedArtworkShowIds: Set<String> = []
    private var pendingArtworkEpisodeIds: Set<String> = []
    private var artworkFlushScheduled = false
    private var artworkReloadScheduled = false

    private var refreshInFlight = false
    private var refreshSawBusy = false
    private var refreshTimeout: DispatchWorkItem?

    private var cacheInFlight = false
    private var cacheSawBusy = false
    private var cacheStartTimeout: DispatchWorkItem?

    private var playbackRequest: (episodeId: String, showId: String, startPosition: Float)?
    private var lastPlayedEpisodeId: String?

    private var cachedContinueListeningEpisodes: [PodcastEpisode]?
    private var cachedResumeEpisode: [PodcastEpisode]?
    private var cachedLatestEpisodes: [PodcastEpisode]?
    private var cachedShows: [PodcastShow]?
    private var cachedShowsById: [String: PodcastShow] = [:]

    private static let latestEpisodesPerShow = 3
    private static let historyPageSize = 50
    private static let prefetchedArtworkEpisodes = 10
    private static let subscriptionRefreshInterval: TimeInterval = 30 * 60
    private static let subscriptionRefreshTimeout: TimeInterval = 30
    private static let cacheStartTimeout: TimeInterval = 30
    private static let maxCachedEpisodesPerShow: UInt32 = 2
    private static let playbackStartFraction: Float = 0.2
    private static let lastSubscriptionRefreshKey = "VLCPodcastsLastSubscriptionRefresh"

    private override init() {
        super.init()
    }

    func configure(mediaLibraryService: MediaLibraryService) {
        guard subscriptionModel == nil else {
            return
        }
        self.mediaLibraryService = mediaLibraryService
        mediaLibraryService.medialib.subscriptionMaxCachedMedia = PodcastStore.maxCachedEpisodesPerShow
        mediaLibraryService.subscriptionCacher.delegate = self
        subscriptionModel = PodcastSubscriptionModel(medialibrary: mediaLibraryService)
        subscriptionModel?.delegate = self
        mediaLibraryService.observable.addObserver(self)

        let notificationCenter = NotificationCenter.default
        for name in [VLCPlaybackServicePlaybackDidStart,
                     VLCPlaybackServicePlaybackDidPause,
                     VLCPlaybackServicePlaybackDidResume,
                     VLCPlaybackServicePlaybackDidStop] {
            notificationCenter.addObserver(self,
                                           selector: #selector(playbackStateDidChange),
                                           name: Notification.Name(name),
                                           object: nil)
        }
        notificationCenter.addObserver(self,
                                       selector: #selector(refreshAllSubscriptionsIfNeeded),
                                       name: UIApplication.willEnterForegroundNotification,
                                       object: nil)

        refreshAllSubscriptionsIfNeeded()
    }

    @objc private func playbackStateDidChange() {
        if let nowPlayingEpisodeId = nowPlayingEpisodeId {
            lastPlayedEpisodeId = nowPlayingEpisodeId
        }

        guard let episodeId = lastPlayedEpisodeId else {
            return
        }

        invalidateDerivedEpisodeCaches()
        notifyEpisodeChanged(episodeId)
        notifyReload()
    }

    func addObserver(_ observer: MediaLibraryBaseModelObserver) {
        subscriptionModel?.observable.addObserver(observer)
    }

    func removeObserver(_ observer: MediaLibraryBaseModelObserver) {
        subscriptionModel?.observable.removeObserver(observer)
    }

    func addEpisodeObserver(_ observer: PodcastStoreObserver) {
        episodeObservable.addObserver(observer)
    }

    func removeEpisodeObserver(_ observer: PodcastStoreObserver) {
        episodeObservable.removeObserver(observer)
    }

    // MARK: - Queries

    var shows: [PodcastShow] {
        return rebuildShowsCacheIfNeeded()
    }

    var continueListeningEpisodes: [PodcastEpisode] {
        if let cachedContinueListeningEpisodes = cachedContinueListeningEpisodes {
            return cachedContinueListeningEpisodes
        }

        let unfinished = unfinishedEpisodesFromHistory(limit: .max)
        cachedContinueListeningEpisodes = unfinished
        return unfinished
    }

    var latestEpisodes: [PodcastEpisode] {
        if let cachedLatestEpisodes = cachedLatestEpisodes {
            return cachedLatestEpisodes
        }

        var result = (subscriptionModel?.subscriptions ?? []).flatMap(newestEpisodes(forSubscription:))
        result.sort { $0.releaseDate > $1.releaseDate }

        cachedLatestEpisodes = result
        return result
    }

    private func unfinishedEpisodesFromHistory(limit: Int) -> [PodcastEpisode] {
        guard let mediaLibraryService = mediaLibraryService,
              subscriptionModel?.subscriptions.isEmpty == false else {
            return []
        }

        let pageSize = PodcastStore.historyPageSize
        var result: [PodcastEpisode] = []
        var offset = 0

        while result.count < limit {
            let page = mediaLibraryService.medialib.history(of: .global,
                                                            UInt32(pageSize),
                                                            UInt32(offset)) ?? []
            for media in page where PodcastStore.isUnfinished(media) {
                guard let showId = PodcastStore.showId(for: media) else {
                    continue
                }
                result.append(PodcastStore.podcastEpisode(from: media, showId: showId))
                if result.count >= limit {
                    return result
                }
            }
            guard page.count >= pageSize else {
                return result
            }
            offset += page.count
        }

        return result
    }

    private static func showId(for media: VLCMLMedia) -> String? {
        guard media.nbSubscriptions() > 0,
              let subscription = media.linkedSubscriptions(with: .alpha, desc: false)?.first else {
            return nil
        }
        return String(subscription.identifier())
    }

    private func newestEpisodes(forSubscription subscription: VLCMLSubscription) -> [PodcastEpisode] {
        guard let subscriptionModel = subscriptionModel else {
            return []
        }

        let showId = String(subscription.identifier())
        let pageSize = PodcastStore.latestEpisodesPerShow
        var result: [PodcastEpisode] = []
        var offset = 0

        while result.count < PodcastStore.latestEpisodesPerShow {
            let page = subscriptionModel.media(for: subscription,
                                               sortedBy: .releaseDate,
                                               desc: true,
                                               items: UInt32(pageSize),
                                               offset: UInt32(offset))
            for media in page where !PodcastStore.isUnfinished(media) {
                result.append(PodcastStore.podcastEpisode(from: media, showId: showId))
            }
            guard page.count >= pageSize else {
                break
            }
            offset += page.count
        }

        return Array(result.prefix(PodcastStore.latestEpisodesPerShow))
    }

    private static func isUnfinished(_ media: VLCMLMedia) -> Bool {
        return media.progress > 0 && media.progress < 1
    }

    var resumeEpisode: PodcastEpisode? {
        if let cachedContinueListeningEpisodes = cachedContinueListeningEpisodes {
            return cachedContinueListeningEpisodes.first
        }
        if let cachedResumeEpisode = cachedResumeEpisode {
            return cachedResumeEpisode.first
        }

        let resume = unfinishedEpisodesFromHistory(limit: 1)
        cachedResumeEpisode = resume
        return resume.first
    }

    func show(withId showId: String) -> PodcastShow? {
        rebuildShowsCacheIfNeeded()
        return cachedShowsById[showId]
    }

    func episodeCount(forShowId showId: String) -> Int {
        return Int(subscription(withId: showId)?.nbMedia() ?? 0)
    }

    func episodes(forShowId showId: String,
                  sortedBy criteria: PodcastEpisodeSortCriteria,
                  descending: Bool,
                  matching query: String,
                  offset: Int,
                  count: Int) -> [PodcastEpisode] {
        guard let subscriptionModel = subscriptionModel,
              let subscription = subscription(withId: showId) else {
            return []
        }

        let sort = PodcastStore.sortingCriteria(for: criteria)
        let media: [VLCMLMedia]
        if query.isEmpty {
            media = subscriptionModel.media(for: subscription,
                                            sortedBy: sort,
                                            desc: descending,
                                            items: UInt32(count),
                                            offset: UInt32(offset))
        } else {
            media = subscriptionModel.searchMedia(for: subscription,
                                                  pattern: query,
                                                  sortedBy: sort,
                                                  desc: descending,
                                                  items: UInt32(count),
                                                  offset: UInt32(offset))
        }
        return media.map { PodcastStore.podcastEpisode(from: $0, showId: showId) }
    }

    func episode(withId episodeId: String, showId: String) -> PodcastEpisode? {
        guard let media = media(forEpisodeId: episodeId) else {
            return nil
        }
        return PodcastStore.podcastEpisode(from: media, showId: showId)
    }

    private static func sortingCriteria(for criteria: PodcastEpisodeSortCriteria) -> VLCMLSortingCriteria {
        switch criteria {
        case .releaseDate:
            return .releaseDate
        case .title:
            return .alpha
        case .duration:
            return .duration
        }
    }

    // MARK: - Mutations

    func addSubscription(mrl: URL, completion: @escaping (Result<Void, PodcastAddSubscriptionError>) -> Void) {
        guard let subscriptionModel = subscriptionModel else {
            completion(.failure(.unknown))
            return
        }
        subscriptionModel.addSubscription(mrl: mrl, completion: completion)
    }

    @discardableResult
    func refreshAllSubscriptions() -> Bool {
        guard let mediaLibraryService = mediaLibraryService, !shows.isEmpty else {
            return false
        }

        if mediaLibraryService.medialib.refreshAllSubscriptions() == false {
            APLog("podcast refresh: not every subscription could be queued")
        }
        UserDefaults.standard.set(Date().timeIntervalSinceReferenceDate,
                                  forKey: PodcastStore.lastSubscriptionRefreshKey)
        beginRefresh()
        return true
    }

    @discardableResult
    func refreshSubscription(showId: String) -> Bool {
        guard let subscription = subscription(withId: showId) else {
            return false
        }
        guard subscription.refresh() else {
            APLog("podcast refresh: failed to queue show \(showId)")
            return false
        }
        beginRefresh()
        return true
    }

    @objc private func refreshAllSubscriptionsIfNeeded() {
        let last = UserDefaults.standard.double(forKey: PodcastStore.lastSubscriptionRefreshKey)
        guard Date().timeIntervalSinceReferenceDate - last >= PodcastStore.subscriptionRefreshInterval else {
            return
        }
        refreshAllSubscriptions()
    }

    // A refresh task has no completion callback, so this ends on the parser going busy and idle
    // again. Waiting for that edge keeps an unrelated task settling from ending the refresh early.
    private func beginRefresh() {
        refreshTimeout?.cancel()
        refreshInFlight = true
        refreshSawBusy = false

        let timeout = DispatchWorkItem { [weak self] in
            self?.endRefresh()
        }
        refreshTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + PodcastStore.subscriptionRefreshTimeout,
                                      execute: timeout)
    }

    private func endRefresh() {
        guard refreshInFlight else {
            return
        }
        refreshTimeout?.cancel()
        refreshTimeout = nil
        refreshInFlight = false
        refreshSawBusy = false
        NotificationCenter.default.post(name: .VLCPodcastsRefreshDidEnd, object: nil)
    }

    // MARK: - Automatic downloads

    var automaticDownloadsEnabled: Bool {
        return UserDefaults.standard.bool(forKey: kVLCSettingPodcastAutomaticDownloads)
    }

    // A pass marks every episode of a subscription as cache-handled even when it downloaded
    // nothing, so one started off Wi-Fi would burn them for good.
    @discardableResult
    func cacheNewEpisodes() -> Bool {
        guard automaticDownloadsEnabled,
              let mediaLibraryService = mediaLibraryService,
              mediaLibraryService.subscriptionCacher.automaticCachingAllowed,
              !shows.isEmpty else {
            return false
        }

        mediaLibraryService.medialib.cacheNewSubscriptionMedia()
        beginCaching()
        return true
    }

    func interruptCaching() {
        mediaLibraryService?.subscriptionCacher.interruptCaching()
    }

    private func beginCaching() {
        cacheStartTimeout?.cancel()
        cacheInFlight = true
        cacheSawBusy = false

        let timeout = DispatchWorkItem { [weak self] in
            guard let self = self, !self.cacheSawBusy else {
                return
            }
            self.endCaching()
        }
        cacheStartTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + PodcastStore.cacheStartTimeout, execute: timeout)
    }

    private func endCaching() {
        guard cacheInFlight else {
            return
        }
        cacheStartTimeout?.cancel()
        cacheStartTimeout = nil
        cacheInFlight = false
        cacheSawBusy = false
        NotificationCenter.default.post(name: .VLCPodcastsCachingDidEnd, object: nil)
    }

    func unsubscribe(showId: String) {
        guard let subscriptionModel = subscriptionModel, let subscription = subscription(withId: showId) else {
            return
        }
        subscriptionModel.removeSubscription(subscription)
    }

    func markAllEpisodes(ofShowId showId: String, played: Bool) {
        guard let subscriptionModel = subscriptionModel, let subscription = subscription(withId: showId) else {
            return
        }

        for media in subscriptionModel.media(for: subscription) {
            media.removeFromHistory()
            media.isNew = !played
            if played {
                media.setPlayCount(1)
            }
        }

        invalidateCaches()
        notifyReload()
    }

    func markEpisodeAsPlayed(episodeId: String, showId: String) {
        guard let media = media(forEpisodeId: episodeId) else {
            return
        }

        media.removeFromHistory()
        media.isNew = false
        media.setPlayCount(1)

        invalidateCaches()
        notifyEpisodeChanged(episodeId)
        notifyReload()
    }

    // An episode that has yet to be downloaded is fetched to the cache first and starts playing off
    // the partial file, which by then is far enough ahead for the rest to arrive in time.
    func playEpisode(episodeId: String, showId: String, startPosition: Float = -1) {
        guard downloadedFileURL(episodeId: episodeId, showId: showId) == nil else {
            playbackRequest = nil
            play(episodeId: episodeId, showId: showId, startPosition: startPosition)
            return
        }

        guard isDownloading(episodeId: episodeId) || downloadEpisode(episodeId: episodeId, showId: showId) else {
            playbackRequest = nil
            return
        }
        playbackRequest = (episodeId, showId, startPosition)
        notifyEpisodeChanged(episodeId)
        notifyReload()
    }

    func play(episodeId: String, showId: String) {
        play(episodeId: episodeId, showId: showId, startPosition: -1)
    }

    private func play(episodeId: String, showId: String, startPosition: Float, partialFileURL: URL? = nil) {
        guard let subscriptionModel = subscriptionModel, let subscription = subscription(withId: showId) else {
            return
        }
        if let show = show(withId: showId) {
            requestArtwork(for: show)
        }
        PlaybackService.sharedInstance().startPosition = startPosition
        subscriptionModel.play(episodeId: episodeId, subscription: subscription, partialFileURL: partialFileURL)
    }

    var nowPlayingEpisodeId: String? {
        let playbackService = PlaybackService.sharedInstance()
        guard playbackService.playerIsSetup,
              let currentMedia = playbackService.currentlyPlayingMedia,
              let media = VLCMLMedia(forPlaying: currentMedia) else {
            return nil
        }
        return String(media.identifier())
    }

    var isPlaying: Bool {
        return PlaybackService.sharedInstance().isPlaying
    }

    func togglePlayPause() {
        PlaybackService.sharedInstance().playPause()
    }

    func appendEpisodeToQueue(episodeId: String, showId: String) {
        guard let media = media(forEpisodeId: episodeId) else {
            return
        }
        PlaybackService.sharedInstance().appendMediaToQueue(media)
    }

    func requestArtwork(for episode: PodcastEpisode) {
        guard episode.artworkURL?.isFileURL != true,
              requestedArtworkEpisodeIds.insert(episode.id).inserted else {
            return
        }
        pendingArtworkEpisodeIds.insert(episode.id)
        scheduleArtworkFlush()
    }

    func prefetchArtwork(forShowId showId: String) {
        if let show = show(withId: showId) {
            requestArtwork(for: show)
        }
        let latest = episodes(forShowId: showId,
                              sortedBy: .releaseDate,
                              descending: true,
                              matching: "",
                              offset: 0,
                              count: PodcastStore.prefetchedArtworkEpisodes)
        for episode in latest {
            requestArtwork(for: episode)
        }
    }

    private func scheduleArtworkFlush() {
        guard !artworkFlushScheduled else {
            return
        }
        artworkFlushScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.artworkFlushScheduled = false
            self.flushArtworkRequests()
        }
    }

    private func flushArtworkRequests() {
        let pending = pendingArtworkEpisodeIds
        pendingArtworkEpisodeIds.removeAll()

        guard let mediaLibraryService = mediaLibraryService else {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            for episodeId in pending {
                guard let identifier = VLCMLIdentifier(episodeId),
                      let media = mediaLibraryService.media(for: identifier) else {
                    continue
                }
                media.requestThumbnail(of: .thumbnail, desiredWidth: 0, desiredHeight: 0, atPosition: 0)
            }
        }
    }

    func requestArtwork(for show: PodcastShow) {
        guard show.artworkURL?.isFileURL != true,
              requestedArtworkShowIds.insert(show.id).inserted else {
            return
        }
        guard let subscription = subscription(withId: show.id) else {
            APLog("podcast artwork: no subscription found for show \(show.id)")
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            if subscription.requestArtwork() == false {
                APLog("podcast artwork: failed to queue show \(show.id)")
            }
        }
    }

    func isDownloading(episodeId: String) -> Bool {
        guard let mediaId = VLCMLIdentifier(episodeId) else {
            return false
        }
        return pendingCacheMediaIds.contains(mediaId)
    }

    func downloadedFileURL(episodeId: String, showId: String) -> URL? {
        guard let media = media(forEpisodeId: episodeId) else {
            return nil
        }
        return media.files.first { $0.type() == .cache }?.mrl
    }

    @discardableResult
    func downloadEpisode(episodeId: String, showId: String) -> Bool {
        guard let mediaLibraryService = mediaLibraryService,
              let media = media(forEpisodeId: episodeId) else {
            return false
        }

        let cacher = mediaLibraryService.subscriptionCacher
        cacher.addManualRequestForMedia(withIdentifier: media.identifier())
        guard mediaLibraryService.medialib.cacheMedia(media) else {
            cacher.removeManualRequestForMedia(withIdentifier: media.identifier())
            return false
        }
        pendingCacheMediaIds.insert(media.identifier())
        return true
    }

    // A pending removal marks the episode as busy just like a pending download does, so the
    // absence of a cached file is what tells the two apart.
    @discardableResult
    func cancelDownload(episodeId: String, showId: String) -> Bool {
        guard let mediaLibraryService = mediaLibraryService,
              let media = media(forEpisodeId: episodeId),
              pendingCacheMediaIds.contains(media.identifier()),
              downloadedFileURL(episodeId: episodeId, showId: showId) == nil else {
            return false
        }

        if playbackRequest?.episodeId == episodeId {
            playbackRequest = nil
        }
        mediaLibraryService.subscriptionCacher.cancelCachingOfMedia(withIdentifier: media.identifier())
        return true
    }

    @discardableResult
    func deleteDownloadedEpisode(episodeId: String, showId: String) -> Bool {
        guard let media = media(forEpisodeId: episodeId),
              mediaLibraryService?.medialib.removeCachedMedia(media) == true else {
            return false
        }
        pendingCacheMediaIds.insert(media.identifier())
        return true
    }

    // MARK: - Private helpers

    private func subscription(withId showId: String) -> VLCMLSubscription? {
        guard let identifier = VLCMLIdentifier(showId) else {
            return nil
        }
        return subscriptionModel?.subscriptions.first { $0.identifier() == identifier }
    }

    private func media(forEpisodeId episodeId: String) -> VLCMLMedia? {
        guard let mediaId = VLCMLIdentifier(episodeId) else {
            return nil
        }
        return mediaLibraryService?.media(for: mediaId)
    }

    @discardableResult
    private func rebuildShowsCacheIfNeeded() -> [PodcastShow] {
        if let cachedShows = cachedShows {
            return cachedShows
        }

        let shows = (subscriptionModel?.subscriptions ?? []).map(PodcastStore.podcastShow)
        cachedShows = shows
        cachedShowsById = Dictionary(uniqueKeysWithValues: shows.map { ($0.id, $0) })
        return shows
    }

    private func invalidateCaches() {
        invalidateDerivedEpisodeCaches()
        cachedShows = nil
        cachedShowsById.removeAll()
    }

    private func invalidateDerivedEpisodeCaches() {
        cachedContinueListeningEpisodes = nil
        cachedResumeEpisode = nil
        cachedLatestEpisodes = nil
    }

    private func refreshCachedEpisode(withId episodeId: String) {
        guard let media = media(forEpisodeId: episodeId) else {
            invalidateDerivedEpisodeCaches()
            return
        }
        cachedContinueListeningEpisodes = PodcastStore.refreshing(cachedContinueListeningEpisodes,
                                                                  episodeId: episodeId,
                                                                  media: media)
        cachedResumeEpisode = PodcastStore.refreshing(cachedResumeEpisode,
                                                      episodeId: episodeId,
                                                      media: media)
        cachedLatestEpisodes = PodcastStore.refreshing(cachedLatestEpisodes,
                                                       episodeId: episodeId,
                                                       media: media)
    }

    private static func refreshing(_ episodes: [PodcastEpisode]?,
                                   episodeId: String,
                                   media: VLCMLMedia) -> [PodcastEpisode]? {
        guard var episodes = episodes,
              let index = episodes.firstIndex(where: { $0.id == episodeId }) else {
            return episodes
        }
        episodes[index] = podcastEpisode(from: media, showId: episodes[index].showId)
        return episodes
    }

    private static func podcastShow(from subscription: VLCMLSubscription) -> PodcastShow {
        return PodcastShow(id: String(subscription.identifier()),
                            name: subscription.name,
                            episodeCount: Int(subscription.nbMedia()),
                            artworkURL: subscription.artworkMRL,
                            websiteURL: subscription.website,
                            author: subscription.author)
    }

    private static func podcastEpisode(from media: VLCMLMedia, showId: String) -> PodcastEpisode {
        let progress = media.progress > 0 ? Double(media.progress) : nil
        // A media the library never played reports the epoch rather than no date at all.
        let lastPlayed = media.lastPlayedDate()
        let downloaded = media.files.contains { $0.type() == .cache }
        let subscriptionEpisode = media.subscriptionEpisode
        let notesHTML = subscriptionEpisode?.showNotes ?? media.shortSummary
        return PodcastEpisode(id: String(media.identifier()),
                               showId: showId,
                               title: media.title,
                               artworkURL: media.thumbnail(),
                               releaseDate: media.releaseDate(),
                               durationValue: media.duration(),
                               progress: progress,
                               lastPlayedDate: lastPlayed.timeIntervalSince1970 > 0 ? lastPlayed : nil,
                               downloaded: downloaded,
                               playCount: media.playCount(),
                               seasonNumber: subscriptionEpisode?.seasonNumber ?? 0,
                               episodeNumber: subscriptionEpisode?.episodeNumber ?? 0,
                               author: subscriptionEpisode?.author,
                               notesHTML: notesHTML)
    }
}

// MARK: - PodcastSubscriptionModelDelegate

extension PodcastStore: PodcastSubscriptionModelDelegate {
    func podcastSubscriptionModelDidChange(_ model: PodcastSubscriptionModel) {
        invalidateCaches()
    }
}

// MARK: - VLCSubscriptionCacherDelegate

extension PodcastStore: VLCSubscriptionCacherDelegate {
    func subscriptionCacher(_ cacher: VLCSubscriptionCacher,
                            didCacheMediaWithIdentifier identifier: VLCMLIdentifier,
                            toPath path: String,
                            fraction: Float) {
        guard fraction >= PodcastStore.playbackStartFraction,
              let request = playbackRequest,
              request.episodeId == String(identifier) else {
            return
        }
        playbackRequest = nil
        play(episodeId: request.episodeId,
             showId: request.showId,
             startPosition: request.startPosition,
             partialFileURL: URL(fileURLWithPath: path))
    }
}

// MARK: - MediaLibraryObserver

extension PodcastStore: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService,
                      didStartCachingMediaWithId mediaId: VLCMLIdentifier,
                      operation: VLCMLCacheOperation) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pendingCacheMediaIds.insert(mediaId)
            self.notifyEpisodeChanged(String(mediaId))
            self.notifyReload()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didFinishCachingMediaWithId mediaId: VLCMLIdentifier,
                      operation: VLCMLCacheOperation,
                      status: VLCMLCacheStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pendingCacheMediaIds.remove(mediaId)
            if status != .success && status != .alreadyCached {
                APLog("podcast cache: media \(mediaId) ended with status \(status.rawValue)")
            }
            self.refreshCachedEpisode(withId: String(mediaId))
            self.notifyEpisodeChanged(String(mediaId))
            self.notifyReload()

            // A feed that never announces a content length, or an episode short enough to arrive
            // in a single progress report, never reaches the fraction playback waits for.
            guard let request = self.playbackRequest, request.episodeId == String(mediaId) else {
                return
            }
            self.playbackRequest = nil
            guard status == .success || status == .alreadyCached else {
                return
            }
            self.play(episodeId: request.episodeId, showId: request.showId, startPosition: request.startPosition)
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didReceiveNewMediaForSubscriptionsWithIds subscriptionIds: [NSNumber]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.automaticDownloadsEnabled else {
                return
            }
            if #available(iOS 13.0, *) {
                PodcastBackgroundRefresher.sharedInstance().scheduleDownloadTask()
            }
            guard UIApplication.shared.applicationState == .active else {
                return
            }
            self.cacheNewEpisodes()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, cacheIdleChanged idle: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.cacheInFlight else {
                return
            }
            guard idle else {
                self.cacheSawBusy = true
                return
            }
            guard self.cacheSawBusy else {
                return
            }
            self.endCaching()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, backgroundTasksIdleChanged idle: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.refreshInFlight else {
                return
            }
            guard idle else {
                self.refreshSawBusy = true
                return
            }
            guard self.refreshSawBusy else {
                return
            }
            self.endRefresh()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, thumbnailReady media: VLCMLMedia,
                      type: VLCMLThumbnailSizeType, success: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let episodeId = String(media.identifier())
            // This fires for every thumbnail in the library, so leave the ones we never asked for alone.
            guard self.requestedArtworkEpisodeIds.contains(episodeId) else {
                return
            }
            guard success else {
                self.requestedArtworkEpisodeIds.remove(episodeId)
                APLog("podcast artwork: episode \(episodeId) failed")
                return
            }

            self.refreshCachedEpisode(withId: episodeId)
            self.notifyEpisodeChanged(episodeId)
            self.scheduleArtworkReload()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      artworkReadyForSubscriptionWithId subscriptionId: VLCMLIdentifier, success: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let showId = String(subscriptionId)
            guard success else {
                self.requestedArtworkShowIds.remove(showId)
                APLog("podcast artwork: show \(showId) failed")
                return
            }
            self.subscriptionModel?.refresh()
            self.cachedShows = nil
            self.cachedShowsById.removeAll()
            self.scheduleArtworkReload()
        }
    }

    private func scheduleArtworkReload() {
        guard !artworkReloadScheduled else {
            return
        }
        artworkReloadScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.artworkReloadScheduled = false
            self.notifyReload()
        }
    }

    private func notifyReload() {
        subscriptionModel?.observable.notifyObservers { $0.mediaLibraryBaseModelReloadView() }
        NotificationCenter.default.post(name: .VLCPodcastsContentDidChange, object: nil)
    }

    private func notifyEpisodeChanged(_ episodeId: String) {
        episodeObservable.notifyObservers { $0.podcastStore(self, didUpdateEpisodeWithId: episodeId) }
    }
}
