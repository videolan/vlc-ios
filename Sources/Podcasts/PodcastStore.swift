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

final class PodcastStore: NSObject {
    static let shared = PodcastStore()

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

    private var playbackRequest: (episodeId: String, showId: String)?

    // Mapping a subscription's VLCMLMedia to PodcastEpisode reformats every episode's date and
    // duration - for a show with thousands of episodes that's too expensive to redo on every
    // access, so it's cached per show and only dropped when the underlying data actually
    // changes (see invalidateCaches()).
    private var episodesByShowId: [String: [PodcastEpisode]] = [:]

    private var cachedContinueListeningEpisodes: [PodcastEpisode]?
    private var cachedLatestEpisodes: [PodcastEpisode]?
    private var cachedShows: [PodcastShow]?
    private var cachedShowsById: [String: PodcastShow] = [:]

    private static let latestEpisodesPerShow = 3
    private static let prefetchedArtworkEpisodes = 10
    private static let subscriptionRefreshInterval: TimeInterval = 30 * 60
    private static let subscriptionRefreshTimeout: TimeInterval = 30
    private static let cacheStartTimeout: TimeInterval = 30
    private static let maxCachedEpisodesPerShow: UInt32 = 2
    private static let playbackStartFraction: Float = 0.2
    private static let lastSubscriptionRefreshKey = "VLCPodcastsLastSubscriptionRefresh"

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMd")
        return formatter
    }()

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
        subscriptionModel?.observable.addObserver(self)
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
        guard let episodeId = nowPlayingEpisodeId else {
            return
        }

        for (showId, episodes) in episodesByShowId {
            guard let index = episodes.firstIndex(where: { $0.id == episodeId }),
                  let media = media(forEpisodeId: episodeId) else {
                continue
            }
            episodesByShowId[showId]?[index] = PodcastStore.podcastEpisode(from: media, showId: showId)
            invalidateDerivedEpisodeCaches()
            notifyReload()
            return
        }
    }

    func addObserver(_ observer: MediaLibraryBaseModelObserver) {
        subscriptionModel?.observable.addObserver(observer)
    }

    func removeObserver(_ observer: MediaLibraryBaseModelObserver) {
        subscriptionModel?.observable.removeObserver(observer)
    }

    // MARK: - Queries

    var shows: [PodcastShow] {
        return rebuildShowsCacheIfNeeded()
    }

    var continueListeningEpisodes: [PodcastEpisode] {
        if let cachedContinueListeningEpisodes = cachedContinueListeningEpisodes {
            return cachedContinueListeningEpisodes
        }

        let all = (subscriptionModel?.subscriptions ?? []).flatMap { episodes(forShowId: String($0.identifier())) }
        let unfinished = all.filter { $0.continueListening }
        cachedContinueListeningEpisodes = unfinished
        return unfinished
    }

    var latestEpisodes: [PodcastEpisode] {
        if let cachedLatestEpisodes = cachedLatestEpisodes {
            return cachedLatestEpisodes
        }

        guard let subscriptionModel = subscriptionModel else {
            return []
        }

        var result: [PodcastEpisode] = []
        for subscription in subscriptionModel.subscriptions {
            let showEpisodes: [PodcastEpisode] = episodes(forShowId: String(subscription.identifier()))
            var unplayed: [PodcastEpisode] = showEpisodes.filter { !$0.continueListening }
            unplayed.sort { $0.releaseDate > $1.releaseDate }
            result.append(contentsOf: unplayed.prefix(PodcastStore.latestEpisodesPerShow))
        }
        result.sort { $0.releaseDate > $1.releaseDate }

        cachedLatestEpisodes = result
        return result
    }

    func show(withId showId: String) -> PodcastShow? {
        rebuildShowsCacheIfNeeded()
        return cachedShowsById[showId]
    }

    func episodes(forShowId showId: String) -> [PodcastEpisode] {
        if let cached = episodesByShowId[showId] {
            return cached
        }
        guard let subscription = subscription(withId: showId) else {
            return []
        }
        let episodes = episodes(forSubscription: subscription)
        episodesByShowId[showId] = episodes
        return episodes
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
        notifyReload()
    }

    // An episode that has yet to be downloaded is fetched to the cache first and starts playing off
    // the partial file, which by then is far enough ahead for the rest to arrive in time.
    func playEpisode(episodeId: String, showId: String) {
        guard downloadedFileURL(episodeId: episodeId, showId: showId) == nil else {
            playbackRequest = nil
            play(episodeId: episodeId, showId: showId)
            return
        }

        guard isDownloading(episodeId: episodeId) || downloadEpisode(episodeId: episodeId, showId: showId) else {
            playbackRequest = nil
            return
        }
        playbackRequest = (episodeId, showId)
        notifyReload()
    }

    func play(episodeId: String, showId: String) {
        play(episodeId: episodeId, showId: showId, partialFileURL: nil)
    }

    private func play(episodeId: String, showId: String, partialFileURL: URL?) {
        guard let subscriptionModel = subscriptionModel, let subscription = subscription(withId: showId) else {
            return
        }
        subscriptionModel.play(episodeId: episodeId, subscription: subscription, partialFileURL: partialFileURL)
    }

    var nowPlayingEpisodeId: String? {
        let playbackService = PlaybackService.sharedInstance()
        guard let currentMedia = playbackService.currentlyPlayingMedia,
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
        let latest = episodes(forShowId: showId).sorted { $0.releaseDate > $1.releaseDate }
        for episode in latest.prefix(PodcastStore.prefetchedArtworkEpisodes) {
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
        for episodeId in pending {
            guard let identifier = VLCMLIdentifier(episodeId),
                  let media = mediaLibraryService.media(for: identifier) else {
                continue
            }
            media.requestThumbnail(of: .thumbnail, desiredWidth: 0, desiredHeight: 0, atPosition: 0)
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
        if subscription.requestArtwork() == false {
            APLog("podcast artwork: failed to queue show \(show.id)")
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
        return subscriptionModel?.subscriptions.first { String($0.identifier()) == showId }
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
        episodesByShowId.removeAll()
        invalidateDerivedEpisodeCaches()
        cachedShows = nil
        cachedShowsById.removeAll()
    }

    private func invalidateDerivedEpisodeCaches() {
        cachedContinueListeningEpisodes = nil
        cachedLatestEpisodes = nil
    }

    private func episodes(forSubscription subscription: VLCMLSubscription) -> [PodcastEpisode] {
        guard let subscriptionModel = subscriptionModel else {
            return []
        }
        let showId = String(subscription.identifier())
        return subscriptionModel.media(for: subscription).map { PodcastStore.podcastEpisode(from: $0, showId: showId) }
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
        let downloaded = media.files.contains { $0.type() == .cache }
        let releaseDate = media.releaseDate()
        let subscriptionEpisode = media.subscriptionEpisode
        let notesHTML = subscriptionEpisode?.showNotes ?? media.shortSummary
        return PodcastEpisode(id: String(media.identifier()),
                               showId: showId,
                               title: media.title,
                               artworkURL: media.thumbnail(),
                               date: dateFormatter.string(from: releaseDate),
                               releaseDate: releaseDate,
                               duration: VLCTime(number: NSNumber(value: media.duration())).stringValue,
                               durationValue: media.duration(),
                               progress: progress,
                               downloaded: downloaded,
                               playCount: media.playCount(),
                               seasonNumber: subscriptionEpisode?.seasonNumber ?? 0,
                               episodeNumber: subscriptionEpisode?.episodeNumber ?? 0,
                               author: subscriptionEpisode?.author,
                               notesHTML: notesHTML)
    }
}

// MARK: - MediaLibraryBaseModelObserver

extension PodcastStore: MediaLibraryBaseModelObserver {
    func mediaLibraryBaseModelReloadView() {
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
            self.invalidateCaches()
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
            self.play(episodeId: request.episodeId, showId: request.showId)
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
            // This fires for every thumbnail in the library, so leave the ones we never asked for
            // alone instead of scanning each cached show for them.
            guard self.requestedArtworkEpisodeIds.contains(episodeId) else {
                return
            }
            guard success else {
                self.requestedArtworkEpisodeIds.remove(episodeId)
                APLog("podcast artwork: episode \(episodeId) failed")
                return
            }
            for (showId, episodes) in self.episodesByShowId {
                guard let index = episodes.firstIndex(where: { $0.id == episodeId }) else {
                    continue
                }
                self.episodesByShowId[showId]?[index] = PodcastStore.podcastEpisode(from: media,
                                                                                    showId: showId)
                self.invalidateDerivedEpisodeCaches()
                self.scheduleArtworkReload()
                return
            }
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
}
