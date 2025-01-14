/*****************************************************************************
 * TabBarCoordinator.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class TabBarCoordinator: NSObject {
    // MARK: - Properties

    private var tabBarController: BottomTabBarController
    private var mediaLibraryService: MediaLibraryService

    private lazy var editToolbar = EditToolbar()

    // MARK: - Init

    @objc init(tabBarController: BottomTabBarController, mediaLibraryService: MediaLibraryService) {
        self.tabBarController = tabBarController
        self.mediaLibraryService = mediaLibraryService
        super.init()
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
    }

    // MARK: - Setup methods

    private func setup() {
        tabBarController.delegate = self
        setupViewControllers()
        setupEditToolbar()
        updateTheme()
    }

    private func setupViewControllers() {
        let controllers: [UIViewController] = [
            VideoViewController(mediaLibraryService: mediaLibraryService),
            AudioViewController(mediaLibraryService: mediaLibraryService),
            PlaylistViewController(mediaLibraryService: mediaLibraryService),
            VLCServerListViewController(medialibraryService: mediaLibraryService),
            SettingsController(mediaLibraryService: mediaLibraryService)
        ]

        tabBarController.viewControllers = controllers.map { UINavigationController(rootViewController: $0) }
        tabBarController.selectedIndex = UserDefaults.standard.integer(forKey: kVLCTabBarIndex)
    }

    func setupEditToolbar() {
        editToolbar.isHidden = true
        editToolbar.translatesAutoresizingMaskIntoConstraints = false

        let view: UIView
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            tabBarController.bottomBar.addSubview(editToolbar)
            tabBarController.bottomBar.bringSubviewToFront(editToolbar)
            view = tabBarController.bottomBar
        } else {
            tabBarController.tabBar.addSubview(editToolbar)
            tabBarController.tabBar.bringSubviewToFront(editToolbar)
            view = tabBarController.tabBar
        }

        let layoutGuide: UILayoutGuide
        if #available(iOS 11.0, *) {
            layoutGuide = view.safeAreaLayoutGuide
        } else {
            layoutGuide = view.layoutMarginsGuide
        }

        NSLayoutConstraint.activate([
            editToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editToolbar.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
            editToolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Helpers

    @objc func updateTheme() {
        let colors = PresentationTheme.current.colors
        let tabBar = tabBarController.tabBar
        let bottomBar = tabBarController.bottomBar
        let tabBarLayer = tabBar.layer
        let bottomBarLayer = bottomBar.layer

        //Setting this in appearanceManager doesn't update tabbar and UINavigationbar of the settingsViewController on change hence we do it here
        tabBar.isTranslucent = true
        tabBar.backgroundColor = colors.tabBarColor
        tabBar.barTintColor = colors.tabBarColor
        tabBar.itemPositioning = .fill

        bottomBar.isTranslucent = false
        bottomBar.backgroundColor = colors.tabBarColor
        bottomBar.barTintColor = colors.tabBarColor
        bottomBar.itemPositioning = .fill

        tabBarLayer.shadowOffset = CGSize(width: 0, height: 0)
        tabBarLayer.shadowRadius = 1.0
        tabBarLayer.shadowColor = colors.cellDetailTextColor.cgColor
        tabBarLayer.shadowOpacity = 0.6
        tabBarLayer.shadowPath = UIBezierPath(rect: tabBar.bounds).cgPath

        bottomBarLayer.shadowOffset = CGSize(width: 0, height: 0)
        bottomBarLayer.shadowRadius = 1.0
        bottomBarLayer.shadowColor = colors.cellDetailTextColor.cgColor
        bottomBarLayer.shadowOpacity = 0.6
        bottomBarLayer.shadowPath = UIBezierPath(rect: bottomBar.bounds).cgPath

        editToolbar.backgroundColor = colors.tabBarColor

        tabBarController.viewControllers?.forEach {
            if let navController = $0 as? UINavigationController, navController.topViewController is SettingsController {
                navController.navigationBar.isTranslucent = false
                navController.navigationBar.barTintColor = colors.navigationbarColor
                navController.navigationBar.tintColor = colors.orangeUI
                navController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: colors.navigationbarTextColor]
                if #available(iOS 13.0, *) {
                    navController.navigationBar.prefersLargeTitles = false
                    navController.navigationBar.standardAppearance = AppearanceManager.navigationbarAppearance()
                    navController.navigationBar.scrollEdgeAppearance = AppearanceManager.navigationbarAppearance()
                }
                if #available(iOS 15.0, *) {
                    UINavigationBar.appearance().standardAppearance = AppearanceManager.navigationbarAppearance()
                    UINavigationBar.appearance().compactAppearance = AppearanceManager.navigationbarAppearance()
                    UINavigationBar.appearance().scrollEdgeAppearance = AppearanceManager.navigationbarAppearance()
                }
            }
        }
    }

    @objc func handleShortcutItem(_ item: UIApplicationShortcutItem) {
        switch item.type {
        case kVLCApplicationShortcutLocalVideo:
            tabBarController.selectedIndex = tabBarController.viewControllers?.firstIndex(where: { vc -> Bool in
                vc is VideoViewController
            }) ?? 0
        case kVLCApplicationShortcutLocalAudio:
            tabBarController.selectedIndex = tabBarController.viewControllers?.firstIndex(where: { vc -> Bool in
                vc is AudioViewController
            }) ?? 1
        case kVLCApplicationShortcutPlaylist:
            tabBarController.selectedIndex = tabBarController.viewControllers?.firstIndex(where: { vc -> Bool in
                vc is PlaylistViewController
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

// MARK: - UITabBarControllerDelegate

extension TabBarCoordinator: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let viewControllerIndex: Int = tabBarController.viewControllers?.firstIndex(of: viewController) ?? 0
        UserDefaults.standard.set(viewControllerIndex, forKey: kVLCTabBarIndex)
    }
}
