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

    private var editToolbar: EditToolbar?
    private var sideToolBar: EditToolbar?

    private lazy var videoNavigationController: UINavigationController = {
        let rootViewController = VideoViewController(mediaLibraryService: mediaLibraryService)
        return UINavigationController(rootViewController: rootViewController)
    }()

    private lazy var audioNavigationController: UINavigationController = {
        let rootViewController = AudioViewController(mediaLibraryService: mediaLibraryService)
        return UINavigationController(rootViewController: rootViewController)
    }()

    private lazy var artistsNavigationController: UINavigationController = {
        let rootViewController = ArtistsViewController(mediaLibraryService: mediaLibraryService)
        return UINavigationController(rootViewController: rootViewController)
    }()

    private lazy var albumsNavigationController: UINavigationController = {
        let rootViewController = AlbumsViewController(mediaLibraryService: mediaLibraryService)
        return UINavigationController(rootViewController: rootViewController)
    }()

    private lazy var tracksNavigationController: UINavigationController = {
        let rootViewController = TracksViewController(mediaLibraryService: mediaLibraryService)
        return UINavigationController(rootViewController: rootViewController)
    }()

    private lazy var genresNavigationController: UINavigationController = {
        let rootViewController = GenresViewController(mediaLibraryService: mediaLibraryService)
        return UINavigationController(rootViewController: rootViewController)
    }()

    private lazy var playlistsNavigationController: UINavigationController = {
        let rootViewController = PlaylistViewController(mediaLibraryService: mediaLibraryService)
        return UINavigationController(rootViewController: rootViewController)
    }()

    private lazy var browseNavigationController: UINavigationController? = {
        guard let rootViewController = VLCServerListViewController(medialibraryService: mediaLibraryService) else {
            return nil
        }

        return UINavigationController(rootViewController: rootViewController)
    }()

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
        tabBarController.editToolbarSetupHandler = { [weak self] in
            self?.setupEditToolbar()
        }
        updateTheme()
        tabBarController.title = "VLC  iOS"
#if os(iOS)
        if #available(iOS 18.0, *) {
            tabBarController.mode = .tabSidebar
            let sideBar = tabBarController.sidebar
            sideBar.preferredLayout = .overlap
            sideBar.delegate = self
            sideBar.bottomBarView?.isHidden = true
            tabBarController.selectedIndex = UserDefaults.standard.integer(forKey: kVLCTabBarIndex)
        }
#endif
    }

    private func setupViewControllers() {
        var controllers: [UINavigationController] = [videoNavigationController]

#if os(iOS)
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad,
           !tabBarController.sidebar.isHidden {
            controllers.append(artistsNavigationController)
            controllers.append(albumsNavigationController)
            controllers.append(tracksNavigationController)
            controllers.append(genresNavigationController)
            controllers.append(playlistsNavigationController)

            if let browseNavigationController = browseNavigationController {
                controllers.append(browseNavigationController)
            }
        } else {
            controllers.append(audioNavigationController)
            controllers.append(playlistsNavigationController)

            if let browseNavigationController = browseNavigationController {
                controllers.append(browseNavigationController)
            }
        }
#else
        controllers.append(audioNavigationController)
        controllers.append(playlistsNavigationController)

        if let browseNavigationController = browseNavigationController {
            controllers.append(browseNavigationController)
        }
#endif

        // Settings is reachable from a navigation bar button instead of a
        // dedicated tab.
        tabBarController.viewControllers = controllers
    }

#if os(iOS)
    private func updateTabBarIndexIfNeeded() {
        let userDefaults = UserDefaults.standard
        var tabIndex: Int = userDefaults.integer(forKey: kVLCTabBarIndex)

        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad,
           !tabBarController.sidebar.isHidden {
            switch tabIndex {
            case 0:
                break
            case 1:
                if let audioViewController = audioNavigationController.topViewController as? AudioViewController {
                    let currentIndex = audioViewController.currentIndex
                    if currentIndex < audioViewController.viewControllers.count - 1 {
                        // Do not update the tabIndex if the folders view is selected.
                        tabIndex = currentIndex + 1
                    }
                }
                break
            default:
                tabIndex += 3
                break
            }
        } else {
            switch tabIndex {
            case 0:
                tabIndex = 0
                break
            case 1, 2, 3, 4:
                if let audioViewController = audioNavigationController.topViewController as? AudioViewController {
                    audioViewController.currentIndex = tabIndex - 1
                    audioViewController.reloadPagerTabStripView()
                }
                tabIndex = 1
                break
            default:
                tabIndex -= 3
                break
            }
        }

        tabBarController.selectedIndex = tabIndex
        userDefaults.set(tabIndex, forKey: kVLCTabBarIndex)
    }
#endif

    func setupEditToolbar() {
        let colors = PresentationTheme.current.colors
        let editToolbar = EditToolbar()
        self.editToolbar = editToolbar
        editToolbar.isHidden = true
        editToolbar.translatesAutoresizingMaskIntoConstraints = false
        editToolbar.backgroundColor = colors.tabBarColor

        var useSidebar = false
#if os(iOS)
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            let sideToolBar = EditToolbar()
            self.sideToolBar = sideToolBar
            sideToolBar.isHidden = true
            sideToolBar.translatesAutoresizingMaskIntoConstraints = false
            sideToolBar.backgroundColor = colors.tabBarColor
            tabBarController.sidebar.bottomBarView = sideToolBar
            useSidebar = true
        }
#endif
        if !useSidebar {
            let containerView = tabBarController.view!
            containerView.addSubview(editToolbar)

            NSLayoutConstraint.activate([
                editToolbar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                editToolbar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                editToolbar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                editToolbar.topAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor),
            ])
        }
    }

    // MARK: - Helpers

    @objc func updateTheme() {
        let colors = PresentationTheme.current.colors
        let tabBar = tabBarController.tabBar
        let bottomBar = tabBarController.bottomBar

#if os(iOS)
        tabBar.isTranslucent = true
        bottomBar.isTranslucent = false
#endif

        if #unavailable(iOS 26.0) {
            let tabBarLayer = tabBar.layer
            let bottomBarLayer = bottomBar.layer

            //Setting this in appearanceManager doesn't update tabbar and UINavigationbar of the settingsViewController on change hence we do it here
            tabBar.backgroundColor = colors.tabBarColor
            tabBar.barTintColor = colors.tabBarColor
            tabBar.itemPositioning = .fill

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

            tabBarController.view.backgroundColor = colors.background
        }

        editToolbar?.backgroundColor = colors.tabBarColor
        sideToolBar?.backgroundColor = colors.tabBarColor

        if #unavailable(iOS 26.0) {
            if #available(iOS 15.0, *) {
                UINavigationBar.appearance().standardAppearance = AppearanceManager.navigationbarAppearance()
                UINavigationBar.appearance().compactAppearance = AppearanceManager.navigationbarAppearance()
                UINavigationBar.appearance().scrollEdgeAppearance = AppearanceManager.navigationbarAppearance()
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

#if os(iOS)
@available(iOS 18.0, *)
extension TabBarCoordinator: UITabBarController.Sidebar.Delegate {
    func tabBarController(_ tabBarController: UITabBarController, sidebarVisibilityWillChange sidebar: UITabBarController.Sidebar, animator: any UITabBarController.Sidebar.Animating) {
        setupViewControllers()
        updateTabBarIndexIfNeeded()

        NotificationCenter.default.post(name: NSNotification.Name("sidebarVisibilityChanged"), object: nil)
    }
}
#endif
