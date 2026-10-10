/*****************************************************************************
 * PodcastsOnAirBridge.swift
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

extension Notification.Name {
    static let VLCPodcastsContentDidChange = Notification.Name("VLCPodcastsContentDidChange")
    static let VLCPodcastsRefreshDidEnd = Notification.Name("VLCPodcastsRefreshDidEnd")
    static let VLCPodcastsCachingDidEnd = Notification.Name("VLCPodcastsCachingDidEnd")
}

extension NSNotification {
    @objc static let VLCPodcastsContentDidChange = Notification.Name.VLCPodcastsContentDidChange
    @objc static let VLCPodcastsRefreshDidEnd = Notification.Name.VLCPodcastsRefreshDidEnd
    @objc static let VLCPodcastsCachingDidEnd = Notification.Name.VLCPodcastsCachingDidEnd
}

@objc final class PodcastResumeItem: NSObject {
    @objc let episodeId: String
    @objc let showId: String
    @objc let title: String
    @objc let artworkURL: URL?
    @objc let progress: CGFloat
    @objc let lastPlayedDate: Date

    init(episode: PodcastEpisode, artworkURL: URL?, lastPlayedDate: Date) {
        self.episodeId = episode.id
        self.showId = episode.showId
        self.title = episode.title
        self.artworkURL = artworkURL
        self.progress = episode.progressFraction
        self.lastPlayedDate = lastPlayedDate
        super.init()
    }
}

extension VLCOnAirRailItem {
    convenience init(show: PodcastShow) {
        self.init(name: show.name, artworkURL: show.artworkURL)
        subtitle = String(format: NSLocalizedString("PODCAST_EPISODE_COUNT", comment: ""), show.episodeCount)
    }
}

@objc final class PodcastsOnAirBridge: NSObject {
    private static var store: PodcastStore {
        return VLCAppCoordinator.sharedInstance().podcastStore
    }

    @objc static var numberOfShows: Int {
        return store.shows.count
    }

    @objc static var resumeEpisode: PodcastResumeItem? {
        guard let episode = store.resumeEpisode, let lastPlayedDate = episode.lastPlayedDate else {
            return nil
        }
        let show = store.show(withId: episode.showId)
        return PodcastResumeItem(episode: episode,
                                 artworkURL: episode.artworkURL ?? show?.artworkURL,
                                 lastPlayedDate: lastPlayedDate)
    }

    @objc static func playResumeEpisode(_ item: PodcastResumeItem) {
        store.playEpisode(episodeId: item.episodeId, showId: item.showId)
    }

    @objc static func refreshAllSubscriptions() -> Bool {
        return store.refreshAllSubscriptions()
    }

    @objc static var automaticDownloadsEnabled: Bool {
        return store.automaticDownloadsEnabled
    }

    @objc static func cacheNewEpisodes() -> Bool {
        return store.cacheNewEpisodes()
    }

    @objc static func interruptCaching() {
        store.interruptCaching()
    }

    @objc static var showRailItems: [VLCOnAirRailItem] {
        let shows = store.shows
        shows.forEach { store.requestArtwork(for: $0) }
        return shows.map { VLCOnAirRailItem(show: $0) }
    }

    @objc static func makePodcastsViewController() -> UIViewController {
        return PodcastsViewController()
    }

    @objc static func makeDirectoryViewController() -> UIViewController {
        return PodcastDirectoryViewController()
    }

    @objc static func makeShowDetailViewController(forShowAt index: Int) -> UIViewController? {
        let shows = store.shows
        guard shows.indices.contains(index) else {
            return nil
        }
        return PodcastShowDetailViewController(show: shows[index])
    }
}
