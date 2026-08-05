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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
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

        let episodes = allEpisodes().filter { !$0.continueListening }
        cachedLatestEpisodes = episodes
        return episodes
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
        cachedAllEpisodes = nil
        cachedContinueListeningEpisodes = nil
        cachedLatestEpisodes = nil
        cachedShows = nil
        cachedShowsById.removeAll()
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
                            artworkURL: subscription.artworkMRL)
    }

    private static func podcastEpisode(from media: VLCMLMedia, showId: String) -> PodcastEpisode {
        let progress = media.progress > 0 ? Double(media.progress) : nil
        let downloaded = media.files.contains { $0.type() == .cache }
        let releaseDate = media.releaseDate()
        return PodcastEpisode(id: String(media.identifier()),
                               showId: showId,
                               title: media.title,
                               date: dateFormatter.string(from: releaseDate),
                               releaseDate: releaseDate,
                               duration: VLCTime(number: NSNumber(value: media.duration())).stringValue,
                               durationValue: media.duration(),
                               progress: progress,
                               downloaded: downloaded,
                               continueListening: (progress ?? 0) > 0 && (progress ?? 0) < 1)
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
                      didStartCachingMediaWithId mediaId: VLCMLIdentifier) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pendingCacheMediaIds.insert(mediaId)
            self.notifyReload()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didFinishCachingMediaWithId mediaId: VLCMLIdentifier, cached: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pendingCacheMediaIds.remove(mediaId)
            self.invalidateCaches()
            self.notifyReload()
        }
    }

    private func notifyReload() {
        subscriptionModel?.observable.notifyObservers { $0.mediaLibraryBaseModelReloadView() }
    }
}
