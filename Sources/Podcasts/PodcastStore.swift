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

    // Mapping a subscription's VLCMLMedia to PodcastEpisode reformats every episode's date and
    // duration - for a show with thousands of episodes that's too expensive to redo on every
    // access, so it's cached per show and only dropped when the underlying data actually
    // changes (see invalidateCaches()).
    private var episodesByShowId: [String: [PodcastEpisode]] = [:]

    private var cachedAllEpisodes: [PodcastEpisode]?
    private var cachedContinueListeningEpisodes: [PodcastEpisode]?
    private var cachedLatestEpisodes: [PodcastEpisode]?
    private var cachedShows: [PodcastShow]?
    private var cachedShowsById: [String: PodcastShow] = [:]

    private static let latestEpisodesPerShow = 3
    private static let prefetchedArtworkEpisodes = 10

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
        subscriptionModel = PodcastSubscriptionModel(medialibrary: mediaLibraryService)
        subscriptionModel?.observable.addObserver(self)
        mediaLibraryService.observable.addObserver(self)
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

        let episodes = allEpisodes().filter { $0.continueListening }
        cachedContinueListeningEpisodes = episodes
        return episodes
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

    func isSubscribed(showId: String) -> Bool {
        return subscription(withId: showId) != nil
    }

    // MARK: - Mutations

    func addSubscription(mrl: URL, completion: @escaping (Result<Void, PodcastAddSubscriptionError>) -> Void) {
        guard let subscriptionModel = subscriptionModel else {
            completion(.failure(.unknown))
            return
        }
        subscriptionModel.addSubscription(mrl: mrl, completion: completion)
    }

    func toggleSubscribe(showId: String) {
        guard let subscriptionModel = subscriptionModel else {
            return
        }
        if let subscription = subscription(withId: showId) {
            subscriptionModel.removeSubscription(subscription)
        }
    }

    func play(episodeId: String, showId: String) {
        guard let subscriptionModel = subscriptionModel, let subscription = subscription(withId: showId) else {
            return
        }
        subscriptionModel.play(episodeId: episodeId, subscription: subscription)
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

    @discardableResult
    func downloadEpisode(episodeId: String, showId: String) -> Bool {
        guard let media = media(forEpisodeId: episodeId, showId: showId),
              mediaLibraryService?.medialib.cacheMedia(media) == true else {
            return false
        }
        pendingCacheMediaIds.insert(media.identifier())
        return true
    }

    @discardableResult
    func deleteDownloadedEpisode(episodeId: String, showId: String) -> Bool {
        guard let media = media(forEpisodeId: episodeId, showId: showId),
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

    private func media(forEpisodeId episodeId: String, showId: String) -> VLCMLMedia? {
        guard let subscriptionModel = subscriptionModel, let subscription = subscription(withId: showId) else {
            return nil
        }
        return subscriptionModel.media(for: subscription).first { String($0.identifier()) == episodeId }
    }

    private func allEpisodes() -> [PodcastEpisode] {
        if let cachedAllEpisodes = cachedAllEpisodes {
            return cachedAllEpisodes
        }

        guard let subscriptionModel = subscriptionModel else {
            return []
        }

        let result = subscriptionModel.subscriptions.flatMap { episodes(forShowId: String($0.identifier())) }
        cachedAllEpisodes = result
        return result
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
        cachedAllEpisodes = nil
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
                               continueListening: (progress ?? 0) > 0 && (progress ?? 0) < 1,
                               playCount: media.playCount(),
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
    }
}
