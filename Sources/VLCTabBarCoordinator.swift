/*****************************************************************************
 * VLCTabbarCooordinator.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class VLCTabbarCooordinator: NSObject, VLCMediaViewControllerDelegate {

    private var childCoordinators: [NSObject] = []
    private var tabBarController: UITabBarController
    private var services: Services
    private var displayController: VLCPlayerDisplayController

    public init(tabBarController: UITabBarController, services: Services) {
        self.tabBarController = tabBarController
        self.services = services
        displayController = VLCPlayerDisplayController(services: services)
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
    }

    @objc public func start() {
        setupViewControllers()
        updateTheme()
    }

    @objc func updateTheme() {
        //Setting this in appearanceManager doesn't update tabbar and UINavigationbar of the settingsViewController on change hence we do it here
        tabBarController.tabBar.barTintColor = PresentationTheme.current.colors.tabBarColor
        tabBarController.viewControllers?.forEach {
            if let navController = $0 as? UINavigationController, navController.topViewController is VLCSettingsController {
                navController.navigationBar.barTintColor = PresentationTheme.current.colors.navigationbarColor
                navController.navigationBar.tintColor = PresentationTheme.current.colors.orangeUI
                navController.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor:  PresentationTheme.current.colors.navigationbarTextColor]

                if #available(iOS 11.0, *) {
                    navController.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor:  PresentationTheme.current.colors.navigationbarTextColor]
                }
            }
        }
    }

    func setupViewControllers() {

        tabBarController.addChildViewController(displayController)
        tabBarController.view.addSubview(displayController.view)
        displayController.view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: tabBarController.tabBar.frame.size.height, right: 0)
        displayController.didMove(toParentViewController: tabBarController)

        let videoVC = VLCVideoSubcategoryViewController(services: services)
        videoVC.mediaDelegate = self
        videoVC.title = NSLocalizedString("VIDEO", comment: "")
        videoVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("VIDEO", comment: ""),
            image: UIImage(named: "TVShowsIcon"),
            selectedImage: UIImage(named: "TVShowsIcon"))
        videoVC.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.video

        // Audio
        let audioVC = VLCAudioSubcategoryViewController(services: services)
        audioVC.mediaDelegate = self
        audioVC.title = NSLocalizedString("AUDIO", comment: "")
        audioVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("AUDIO", comment: ""),
            image: UIImage(named: "MusicAlbums"),
            selectedImage: UIImage(named: "MusicAlbums"))
        audioVC.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.audio

        // Serverlist
        let serverVC = VLCServerListViewController(nibName: nil, bundle: nil)
        serverVC.title = NSLocalizedString("LOCAL_NETWORK", comment: "")
        serverVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("LOCAL_NETWORK", comment: ""),
            image: UIImage(named: "Local"),
            selectedImage: UIImage(named: "Local"))
        serverVC.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.localNetwork

        // Settings
        let settingsVC = VLCSettingsController()
        settingsVC.title = NSLocalizedString("Settings", comment: "")
        settingsVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Settings", comment: ""),
            image: UIImage(named: "Settings"),
            selectedImage: UIImage(named: "Settings"))
        settingsVC.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.settings

        let controllers = [videoVC, audioVC, serverVC, settingsVC]
        tabBarController.viewControllers = controllers.map { UINavigationController(rootViewController: $0) }
    }

    // MARK: - VLCMediaViewControllerDelegate

    func mediaViewControllerDidSelectMediaObject(_ VLCMediaViewController: VLCMediaViewController, mediaObject: NSManagedObject) {
        playMedia(media: mediaObject)
    }

    func mediaViewControllerDidSelectSort(_ VLCMediaViewController: VLCMediaViewController) {
        showSortOptions()
    }

    func playMedia(media: NSManagedObject) {
        //that should go into a Coordinator itself
        let vpc = VLCPlaybackController.sharedInstance()
        vpc?.playMediaLibraryObject(media)
    }

    func showSortOptions() {
        // This should be in a subclass
        let sortOptionsAlertController = UIAlertController(title: NSLocalizedString("SORT_BY", comment: ""), message: nil, preferredStyle: .actionSheet)
        let sortByNameAction = UIAlertAction(title: SortOption.alphabetically.localizedDescription, style: .default) { action in
        }
        let sortBySizeAction = UIAlertAction(title: SortOption.size.localizedDescription, style: .default) { action in
        }
        let sortbyDateAction = UIAlertAction(title: SortOption.insertonDate.localizedDescription, style: .default) { action in
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .cancel, handler: nil)
        sortOptionsAlertController.addAction(sortByNameAction)
        sortOptionsAlertController.addAction(sortbyDateAction)
        sortOptionsAlertController.addAction(sortBySizeAction)
        sortOptionsAlertController.addAction(cancelAction)
        sortOptionsAlertController.view.tintColor = UIColor.vlcOrangeTint()
        tabBarController.present(sortOptionsAlertController, animated: true)
    }
}
