import UIKit
/*****************************************************************************
 * TabBarCoordinator.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class TabBarCoordinator: NSObject {
    private var tabBarController: UITabBarController
    private var mediaLibraryService: MediaLibraryService

    private lazy var editToolbar = EditToolbar()

    @objc init(tabBarController: UITabBarController, mediaLibraryService: MediaLibraryService) {
        self.tabBarController = tabBarController
        self.mediaLibraryService = mediaLibraryService
        super.init()
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
    }

    private func setup() {
        tabBarController.delegate = self
        setupViewControllers()
        setupEditToolbar()
        updateTheme()
    }

    @objc func updateTheme() {
        let colors = PresentationTheme.current.colors
        let tabBar = tabBarController.tabBar
        let tabBarLayer = tabBar.layer

        editToolbar.backgroundColor = colors.tabBarColor

        //Setting this in appearanceManager doesn't update tabbar and UINavigationbar of the settingsViewController on change hence we do it here
        tabBar.isTranslucent = true
        tabBar.backgroundColor = colors.tabBarColor
        tabBar.barTintColor = colors.tabBarColor
        tabBar.itemPositioning = .fill

        tabBarLayer.shadowOffset = CGSize(width: 0, height: 0)
        tabBarLayer.shadowRadius = 1.0
        tabBarLayer.shadowColor = colors.cellDetailTextColor.cgColor
        tabBarLayer.shadowOpacity = 0.6
        tabBarLayer.shadowPath = UIBezierPath(rect: tabBar.bounds).cgPath

        tabBarController.viewControllers?.forEach {
            if let navController = $0 as? UINavigationController, navController.topViewController is SettingsController {
                navController.navigationBar.isTranslucent = false
                navController.navigationBar.barTintColor = colors.navigationbarColor
                navController.navigationBar.tintColor = colors.orangeUI
                navController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:  colors.navigationbarTextColor]

                if #available(iOS 11.0, *) {
                    navController.navigationBar.prefersLargeTitles = false
                }
                if #available(iOS 13.0, *) {
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

// MARK: - Edit ToolBar

private extension TabBarCoordinator {
    func setupEditToolbar() {
        editToolbar.isHidden = true
        editToolbar.translatesAutoresizingMaskIntoConstraints = false
        tabBarController.tabBar.addSubview(editToolbar)
        tabBarController.tabBar.bringSubviewToFront(editToolbar)

        let view = tabBarController.tabBar
        var guide: LayoutAnchorContainer = view
        if #available(iOS 11.0, *) {
            guide = view.safeAreaLayoutGuide
        }

        NSLayoutConstraint.activate([
            editToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editToolbar.topAnchor.constraint(equalTo: guide.topAnchor),
            editToolbar.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
        ])
    }
}

extension TabBarCoordinator: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let viewControllerIndex: Int = tabBarController.viewControllers?.firstIndex(of: viewController) ?? 0
        UserDefaults.standard.set(viewControllerIndex, forKey: kVLCTabBarIndex)
    }
}

extension UITabBarController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }
}

// MARK: UITabBarController - Edit

extension UITabBarController {
    func editToolBar() -> EditToolbar? {
        return tabBar.subviews.filter() { $0 is EditToolbar }.first as? EditToolbar
    }

    func displayEditToolbar(with model: MediaLibraryBaseModel) {
        guard let editToolbar = editToolBar() else {
            return
        }
        editToolbar.updateEditToolbar(for: model)
        editToolbar.isHidden = false
    }

    func hideEditToolbar() {
        guard let editToolbar = editToolBar() else {
            return
        }
        editToolbar.isHidden = true
    }
}
