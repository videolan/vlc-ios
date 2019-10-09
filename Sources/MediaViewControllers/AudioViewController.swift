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

class AudioViewController: MediaViewController {
    override init(services: Services) {
        super.init(services: services)
        setupUI()
    }

    private func setupUI() {
        title = NSLocalizedString("AUDIO", comment: "")
        tabBarItem = UITabBarItem(
            title: NSLocalizedString("AUDIO", comment: ""),
            image: UIImage(named: "Audio"),
            selectedImage: UIImage(named: "Audio"))
        tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.audio
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [
            ArtistCategoryViewController(services),
            AlbumCategoryViewController(services),
            TrackCategoryViewController(services),
            GenreCategoryViewController(services)
        ]
    }
}
