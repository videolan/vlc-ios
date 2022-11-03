/*****************************************************************************
 * VLCPlaylistViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class PlaylistViewController: MediaViewController {
    override init(mediaLibraryService: MediaLibraryService) {
        super.init(mediaLibraryService: mediaLibraryService)
        setupUI()
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
        return [
            PlaylistCategoryViewController(mediaLibraryService)
        ]
    }

    func resetTitleView() {
        navigationItem.titleView = nil
    }
}
