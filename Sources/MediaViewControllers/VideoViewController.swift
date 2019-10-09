/*****************************************************************************
 * VideoViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class VideoViewController: MediaViewController {
    override init(services: Services) {
        super.init(services: services)
        setupUI()
    }

    private func setupUI() {
        title = NSLocalizedString("VIDEO", comment: "")
        tabBarItem = UITabBarItem(
            title: NSLocalizedString("VIDEO", comment: ""),
            image: UIImage(named: "Video"),
            selectedImage: UIImage(named: "Video"))
        tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.video
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [MovieCategoryViewController(services),
                VideoGroupCategoryViewController(services)]
    }
}
