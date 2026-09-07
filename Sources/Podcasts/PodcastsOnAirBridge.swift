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

@objc final class PodcastsOnAirBridge: NSObject {
    @objc static let showsCellReuseIdentifier = "OnAirPodcastShowsCell"

    @objc static func registerShowsCell(with tableView: UITableView) {
        tableView.register(ShowsSectionCell.self, forCellReuseIdentifier: showsCellReuseIdentifier)
    }

    @objc static func configure(mediaLibraryService: MediaLibraryService) {
        PodcastStore.shared.configure(mediaLibraryService: mediaLibraryService)
    }

    @objc static var numberOfShows: Int {
        return PodcastStore.shared.shows.count
    }

    @objc static var resumeEpisode: PodcastResumeItem? {
        let store = PodcastStore.shared
        guard let episode = store.resumeEpisode, let lastPlayedDate = episode.lastPlayedDate else {
            return nil
        }
        let show = store.show(withId: episode.showId)
        return PodcastResumeItem(episode: episode,
                                 artworkURL: episode.artworkURL ?? show?.artworkURL,
                                 lastPlayedDate: lastPlayedDate)
    }

    @objc static func playResumeEpisode(_ item: PodcastResumeItem) {
        PodcastStore.shared.playEpisode(episodeId: item.episodeId, showId: item.showId)
    }

    @objc static func refreshAllSubscriptions() -> Bool {
        return PodcastStore.shared.refreshAllSubscriptions()
    }

    @objc static var automaticDownloadsEnabled: Bool {
        return PodcastStore.shared.automaticDownloadsEnabled
    }

    @objc static func cacheNewEpisodes() -> Bool {
        return PodcastStore.shared.cacheNewEpisodes()
    }

    @objc static func interruptCaching() {
        PodcastStore.shared.interruptCaching()
    }

    @discardableResult
    @objc static func configureShowsCell(_ cell: UITableViewCell, onSelectShowId: @escaping (String) -> Void) -> Bool {
        guard let showsCell = cell as? ShowsSectionCell else {
            return false
        }
        showsCell.shows = PodcastStore.shared.shows
        showsCell.onSelectShow = { show in
            onSelectShowId(show.id)
        }
        return true
    }

    @objc static func makePodcastsViewController(mediaLibraryService: MediaLibraryService) -> UIViewController {
        return PodcastsViewController(mediaLibraryService: mediaLibraryService)
    }

    @objc static func makeShowDetailViewController(forShowId showId: String) -> UIViewController? {
        guard let show = PodcastStore.shared.show(withId: showId) else {
            return nil
        }
        return PodcastShowDetailViewController(show: show)
    }
}
