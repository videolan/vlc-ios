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
