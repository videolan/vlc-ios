/*****************************************************************************
 * VLCPlaylistViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class PlaylistViewController: MediaViewController {
    private let showsHistory: Bool

    override init(mediaLibraryService: MediaLibraryService) {
        showsHistory = mediaLibraryService.isPlaybackHistoryEnabled
        super.init(mediaLibraryService: mediaLibraryService)
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        currentIndex = showsHistory ? UserDefaults.standard.integer(forKey: kVLCPlaylistTabIndex) : 0
        super.viewWillAppear(animated)
    }

    private func setupUI() {
        title = NSLocalizedString("PLAYLISTS", comment: "")
        tabBarItem = UITabBarItem(
            title: NSLocalizedString("PLAYLISTS", comment: ""),
            image: UIImage(named: "Playlist"),
            selectedImage: UIImage(named: "Playlist"))
        tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.playlist
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        guard showsHistory else {
            return [PlaylistCategoryViewController(mediaLibraryService)]
        }
        return [
            PlaylistCategoryViewController(mediaLibraryService),
            HistoryCategoryViewController(mediaLibraryService)
        ]
    }

    func resetTitleView() {
        navigationItem.titleView = nil
    }
}
