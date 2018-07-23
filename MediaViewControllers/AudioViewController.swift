/*****************************************************************************
 * AudioViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class VLCAudioViewController: VLCMediaViewController {
    override init(services: Services) {
        super.init(services: services)
        setupUI()
    }

    private func setupUI() {
        title = NSLocalizedString("AUDIO", comment: "")
        tabBarItem = UITabBarItem(
            title: NSLocalizedString("AUDIO", comment: ""),
            image: UIImage(named: "MusicAlbums"),
            selectedImage: UIImage(named: "MusicAlbums"))
        tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.audio
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let tracks = VLCTrackCategoryViewController(services)
        let genres = VLCGenreCategoryViewController(services)
        let artists = VLCArtistCategoryViewController(services)
        let albums = VLCAlbumCategoryViewController(services)
        let playlists = VLCAudioPlaylistCategoryViewController(services)
        return [tracks, genres, artists, albums, playlists]
    }
}
