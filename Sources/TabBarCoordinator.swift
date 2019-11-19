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
    private var services: Services

    private lazy var editToolbar = EditToolbar()

    init(tabBarController: UITabBarController, services: Services) {
        self.tabBarController = tabBarController
        self.services = services
        super.init()
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
    }

    private func setup() {
        setupViewControllers()
        setupEditToolbar()
        updateTheme()
    }

    @objc func updateTheme() {
        editToolbar.backgroundColor = PresentationTheme.current.colors.tabBarColor
        //Setting this in appearanceManager doesn't update tabbar and UINavigationbar of the settingsViewController on change hence we do it here
        tabBarController.tabBar.isTranslucent = false
        tabBarController.tabBar.backgroundColor = PresentationTheme.current.colors.tabBarColor
        tabBarController.tabBar.barTintColor = PresentationTheme.current.colors.tabBarColor
        tabBarController.tabBar.itemPositioning = .fill
        tabBarController.viewControllers?.forEach {
            if let navController = $0 as? UINavigationController, navController.topViewController is VLCSettingsController {
                navController.navigationBar.isTranslucent = false
                navController.navigationBar.barTintColor = PresentationTheme.current.colors.navigationbarColor
                navController.navigationBar.tintColor = PresentationTheme.current.colors.orangeUI
                navController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:  PresentationTheme.current.colors.navigationbarTextColor]

                if #available(iOS 11.0, *) {
                    navController.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor:  PresentationTheme.current.colors.navigationbarTextColor]
                }
                if #available(iOS 13.0, *) {
                    navController.navigationBar.standardAppearance = AppearanceManager.navigationbarAppearance()
                    navController.navigationBar.scrollEdgeAppearance = AppearanceManager.navigationbarAppearance()
                }
            }
        }
    }

    private func setupViewControllers() {
        let controllers: [UIViewController] = [
            VideoViewController(services: services),
            AudioViewController(services: services),
            PlaylistViewController(services: services),
            VLCServerListViewController(nibName: nil, bundle: nil),
            VLCSettingsController(mediaLibraryService: services.medialibraryService)
        ]

        tabBarController.viewControllers = controllers.map { UINavigationController(rootViewController: $0) }
    }

    func handleShortcutItem(_ item: UIApplicationShortcutItem) {
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

extension UITabBarController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
                // Since traitCollectionDidChange is called in, for example rotations, we make sure that
                // there was a userInterfaceStyle change.
                return
            }
            guard UserDefaults.standard.integer(forKey: kVLCSettingAppTheme) == kVLCSettingAppThemeSystem else {
                // Theme is specificly set, do not follow systeme theme.
                return
            }

            let isSystemDarkTheme = traitCollection.userInterfaceStyle == .dark
            PresentationTheme.current = isSystemDarkTheme ? PresentationTheme.darkTheme : PresentationTheme.brightTheme
        }
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
