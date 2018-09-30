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
        tabBarController.tabBar.barTintColor = PresentationTheme.current.colors.tabBarColor
        tabBarController.viewControllers?.forEach {
            if let navController = $0 as? UINavigationController, navController.topViewController is VLCSettingsController {
                navController.navigationBar.barTintColor = PresentationTheme.current.colors.navigationbarColor
                navController.navigationBar.tintColor = PresentationTheme.current.colors.orangeUI
                navController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:  PresentationTheme.current.colors.navigationbarTextColor]

                if #available(iOS 11.0, *) {
                    navController.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor:  PresentationTheme.current.colors.navigationbarTextColor]
                }
            }
        }
    }

    private func setupViewControllers() {
        let controllers = [
            VLCVideoViewController(services: services),
            VLCAudioViewController(services: services),
            VLCPlaylistViewController(services: services),
            VLCServerListViewController(nibName: nil, bundle: nil),
            VLCSettingsController()
        ]

        tabBarController.viewControllers = controllers.map { UINavigationController(rootViewController: $0) }
    }
}
