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

final class PodcastStore {
    static let shared = PodcastStore()

    private var subscriptionModel: PodcastSubscriptionModel?

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter
    }()

    private init() {}

    func configure(mediaLibraryService: MediaLibraryService) {
        guard subscriptionModel == nil else {
            return
        }
        subscriptionModel = PodcastSubscriptionModel(medialibrary: mediaLibraryService)
    }

    func addObserver(_ observer: MediaLibraryBaseModelObserver) {
        subscriptionModel?.observable.addObserver(observer)
    }

    func removeObserver(_ observer: MediaLibraryBaseModelObserver) {
        subscriptionModel?.observable.removeObserver(observer)
    }

    // MARK: - Queries

    var shows: [PodcastShow] {
        return (subscriptionModel?.subscriptions ?? []).map(PodcastStore.podcastShow)
    }

    var continueListeningEpisodes: [PodcastEpisode] {
        return allEpisodes().filter { $0.continueListening }
    }

    var latestEpisodes: [PodcastEpisode] {
        return allEpisodes().filter { !$0.continueListening }
    }

    func show(withId showId: String) -> PodcastShow? {
        return shows.first { $0.id == showId }
    }

    func episodes(forShowId showId: String) -> [PodcastEpisode] {
        guard let subscription = subscription(withId: showId) else {
            return []
        }
        return episodes(forSubscription: subscription)
    }

    func isSubscribed(showId: String) -> Bool {
        return subscription(withId: showId) != nil
    }

    // MARK: - Mutations

    func addSubscription(mrl: URL, completion: @escaping (Bool) -> Void) {
        guard let subscriptionModel = subscriptionModel else {
            completion(false)
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
        return PodcastEpisodeDownloader.shared.isDownloading(episodeId: episodeId)
    }

    func downloadEpisode(episodeId: String, showId: String, completion: @escaping (Bool) -> Void) {
        guard let subscriptionModel = subscriptionModel,
              let subscription = subscription(withId: showId),
              let media = subscriptionModel.media(for: subscription).first(where: { String($0.identifier()) == episodeId }) else {
            completion(false)
            return
        }
        PodcastEpisodeDownloader.shared.download(media: media, completion: completion)
    }

    @discardableResult
    func deleteDownloadedEpisode(episodeId: String, showId: String) -> Bool {
        guard let subscriptionModel = subscriptionModel,
              let subscription = subscription(withId: showId),
              let media = subscriptionModel.media(for: subscription).first(where: { String($0.identifier()) == episodeId }) else {
            return false
        }
        let cacheFiles = media.files.filter { $0.type() == .cache }
        guard !cacheFiles.isEmpty else {
            return false
        }
        for cacheFile in cacheFiles {
            try? FileManager.default.removeItem(at: cacheFile.mrl)
            cacheFile.delete()
        }
        return true
    }

    // MARK: - Private helpers

    private func subscription(withId showId: String) -> VLCMLSubscription? {
        return subscriptionModel?.subscriptions.first { String($0.identifier()) == showId }
    }

    private func allEpisodes() -> [PodcastEpisode] {
        guard let subscriptionModel = subscriptionModel else {
            return []
        }
        return subscriptionModel.subscriptions.flatMap(episodes(forSubscription:))
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
        // Confirm the file still exists on disk: deleteDownloadedEpisode removes it directly since
        // VLCMLFile.delete() doesn't reliably clean up externally-added cache files, which can
        // leave a stale Cache-type File row behind after a manual delete.
        let downloaded = media.files.contains {
            $0.type() == .cache && FileManager.default.fileExists(atPath: $0.mrl.path)
        }
        return PodcastEpisode(id: String(media.identifier()),
                               showId: showId,
                               title: media.title,
                               date: dateFormatter.string(from: media.releaseDate()),
                               duration: VLCTime(number: NSNumber(value: media.duration())).stringValue,
                               progress: progress,
                               downloaded: downloaded,
                               continueListening: (progress ?? 0) > 0 && (progress ?? 0) < 1)
    }
}
