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
    private lazy var services: Services = {
        assertionFailure()
        return Services()
    }()
    private let displayController = VLCPlayerDisplayController()

    public init(tabBarController: UITabBarController, services: Services) {
        self.tabBarController = tabBarController
        super.init()
        self.services = services
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
    }

    @objc public func start() {
        setupViewControllers()
        updateTheme()
    }

    @objc func updateTheme() {
        tabBarController.tabBar.barTintColor = PresentationTheme.current.colors.tabBarColor
    }

    func setupViewControllers() {

        tabBarController.addChildViewController(displayController)
        tabBarController.view.addSubview(displayController.view)
        displayController.view.layoutMargins = UIEdgeInsets(top:0, left:0, bottom:tabBarController.tabBar.frame.size.height, right:0)
        displayController.didMove(toParentViewController: tabBarController)

        let videoVC = VLCMediaViewController(services: services)
        //this should probably not be the delegate
        videoVC.delegate = self
        videoVC.title = NSLocalizedString("VIDEO", comment: "")
        videoVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("VIDEO", comment: ""),
            image: UIImage(named: "TVShowsIcon"),
            selectedImage: UIImage(named: "TVShowsIcon"))
        videoVC.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.video

        // Audio
        let audioVC = VLCMediaViewController(services: services)
        //this should probably not be the delegate
        audioVC.delegate = self
        audioVC.title = NSLocalizedString("AUDIO", comment: "")
        audioVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("AUDIO", comment: ""),
            image: UIImage(named: "MusicAlbums"),
            selectedImage:UIImage(named: "MusicAlbums"))
        audioVC.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.audio

        //Serverlist
        let serverVC = VLCServerListViewController(nibName: nil, bundle: nil)
        serverVC.title = NSLocalizedString("LOCAL_NETWORK", comment: "")
        serverVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("LOCAL_NETWORK", comment: ""),
            image: UIImage(named: "Local"),
            selectedImage: UIImage(named: "Local"))
        serverVC.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.localNetwork

        //Settings
        let settingsVC = VLCSettingsController()
        settingsVC.title = NSLocalizedString("Settings", comment: "")
        settingsVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Settings", comment: ""),
            image: UIImage(named: "Settings"),
            selectedImage: UIImage(named: "Settings"))
        settingsVC.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.settings

        let controllers = [audioVC, serverVC, videoVC, settingsVC]
        tabBarController.viewControllers = controllers.map { UINavigationController(rootViewController: $0)}
    }

    // MARK: - VLCMediaViewControllerDelegate
    func mediaViewControllerDidSelectMediaObject(_ VLCMediaViewController: VLCMediaViewController, mediaObject: NSManagedObject) {
        playMedia(media:mediaObject)
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
        //This should be in a subclass
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
