/*****************************************************************************
 * VLCTabBarCoordinator.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class VLCTabBarCoordinator: NSObject {
    private var tabBarController: UITabBarController
    private var services: Services

    init(tabBarController: UITabBarController, services: Services) {
        self.tabBarController = tabBarController
        self.services = services
        super.init()
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
    }

    private func setup() {
        setupViewControllers()
        updateTheme()
    }

    @objc func updateTheme() {
        //Setting this in appearanceManager doesn't update tabbar and UINavigationbar of the settingsViewController on change hence we do it here
        tabBarController.tabBar.isTranslucent = false
        tabBarController.tabBar.backgroundColor = PresentationTheme.current.colors.tabBarColor
        tabBarController.tabBar.barTintColor = PresentationTheme.current.colors.tabBarColor
        tabBarController.tabBar.itemPositioning = .fill
        tabBarController.viewControllers?.forEach {
            if let navController = $0 as? UINavigationController, navController.topViewController is VLCSettingsController {
                navController.navigationBar.barTintColor = PresentationTheme.current.colors.navigationbarColor
                navController.navigationBar.tintColor = PresentationTheme.current.colors.orangeUI
                navController.navigationBar.isTranslucent = false
                navController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:  PresentationTheme.current.colors.navigationbarTextColor]

                if #available(iOS 11.0, *) {
                    navController.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor:  PresentationTheme.current.colors.navigationbarTextColor]
                }
            }
        }
    }

    private func setupViewControllers() {
        let controllers: [UIViewController] = [
            VLCVideoViewController(services: services),
            VLCAudioViewController(services: services),
            VLCPlaylistViewController(services: services),
            VLCServerListViewController(nibName: nil, bundle: nil),
            VLCSettingsController(mediaLibraryService: services.medialibraryService)
        ]

        tabBarController.viewControllers = controllers.map { UINavigationController(rootViewController: $0) }
    }

    func handleShortcutItem(_ item: UIApplicationShortcutItem) {
        switch item.type {
        case kVLCApplicationShortcutLocalVideo:
            tabBarController.selectedIndex = tabBarController.viewControllers?.firstIndex(where: { vc -> Bool in
                vc is VLCVideoViewController
            }) ?? 0
        case kVLCApplicationShortcutLocalAudio:
            tabBarController.selectedIndex = tabBarController.viewControllers?.firstIndex(where: { vc -> Bool in
                vc is VLCAudioViewController
            }) ?? 1
        case kVLCApplicationShortcutPlaylist:
            tabBarController.selectedIndex = tabBarController.viewControllers?.firstIndex(where: { vc -> Bool in
                vc is VLCPlaylistViewController
            }) ?? 2
        case kVLCApplicationShortcutNetwork:
            tabBarController.selectedIndex = tabBarController.viewControllers?.firstIndex(where: { vc -> Bool in
                vc is VLCServerListViewController
            }) ?? 3
        default:
            assertionFailure("unhandled shortcut")
        }
    }
}

extension UITabBarController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }
}
