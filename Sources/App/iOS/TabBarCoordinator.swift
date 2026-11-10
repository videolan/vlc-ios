/*****************************************************************************
 * TabBarCoordinator.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018-2026 VideoLAN. All rights reserved.
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

    private var isUsingSidebarTabs = false

    private static let tabBarIndexUsesSidebarTabsKey = "TabBarIndexUsesSidebarTabs"

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

    private lazy var foldersNavigationController: UINavigationController = {
        let rootViewController = FoldersViewController(mediaLibraryService: mediaLibraryService)
        return UINavigationController(rootViewController: rootViewController)
    }()

    private lazy var playlistsNavigationController: UINavigationController = {
        let rootViewController = PlaylistViewController(mediaLibraryService: mediaLibraryService)
        return UINavigationController(rootViewController: rootViewController)
    }()

    private lazy var onAirNavigationController: UINavigationController = {
        let rootViewController = VLCOnAirViewController()
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
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackgroundNotification),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        mediaLibraryService.observable.addObserver(self)
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

            if #available(iOS 27.0, *),
               sideBar.responds(to: NSSelectorFromString("setPreferredPlacement:")) {
                sideBar.setValue(1, forKey: "preferredPlacement")
            }
            sideBar.delegate = self
            sideBar.bottomBarView?.isHidden = true
        }

        if tabBarController.isSidebarShown != isUsingSidebarTabs {
            setupViewControllers()
        }
        restoreTabBarIndex()
#else
        tabBarController.selectedIndex = UserDefaults.standard.integer(forKey: kVLCTabBarIndex)
#endif
    }

    private func setupViewControllers() {
        var controllers: [UINavigationController] = [videoNavigationController]

#if os(iOS)
        isUsingSidebarTabs = tabBarController.isSidebarShown
        if isUsingSidebarTabs {
            controllers.append(artistsNavigationController)
            controllers.append(albumsNavigationController)
            controllers.append(tracksNavigationController)
            controllers.append(genresNavigationController)
            controllers.append(foldersNavigationController)
            controllers.append(playlistsNavigationController)
        } else {
            controllers.append(audioNavigationController)
            controllers.append(playlistsNavigationController)
        }
#else
        controllers.append(audioNavigationController)
        controllers.append(playlistsNavigationController)
#endif

        if let browseNavigationController = browseNavigationController {
            controllers.append(browseNavigationController)
        }

        controllers.append(onAirNavigationController)

        // Settings is reachable from a navigation bar button instead of a
        // dedicated tab.
        tabBarController.viewControllers = controllers
    }

#if os(iOS)
    private func updateTabsForSidebarIfNeeded() {
        guard tabBarController.isSidebarShown != isUsingSidebarTabs else {
            return
        }

        setupViewControllers()
        restoreTabBarIndex()
        NotificationCenter.default.post(name: NSNotification.Name("sidebarVisibilityChanged"), object: nil)
    }

    private func saveTabBarIndex(_ tabIndex: Int) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(tabIndex, forKey: kVLCTabBarIndex)
        userDefaults.set(isUsingSidebarTabs, forKey: TabBarCoordinator.tabBarIndexUsesSidebarTabsKey)
    }

    private func restoreTabBarIndex() {
        let userDefaults = UserDefaults.standard
        var tabIndex: Int = userDefaults.integer(forKey: kVLCTabBarIndex)
        let savedWithSidebarTabs = userDefaults.object(forKey: TabBarCoordinator.tabBarIndexUsesSidebarTabsKey) as? Bool
            ?? isUsingSidebarTabs

        if savedWithSidebarTabs == isUsingSidebarTabs {
            // Nothing to convert.
        } else if isUsingSidebarTabs {
            switch tabIndex {
            case 0:
                break
            case 1:
                if let audioViewController = audioNavigationController.topViewController as? AudioViewController {
                    tabIndex = audioViewController.currentIndex + 1
                }
                break
            default:
                tabIndex += 4
                break
            }
        } else {
            switch tabIndex {
            case 0:
                tabIndex = 0
                break
            case 1, 2, 3, 4, 5:
                if let audioViewController = audioNavigationController.topViewController as? AudioViewController {
                    audioViewController.currentIndex = tabIndex - 1
                    audioViewController.reloadPagerTabStripView()
                }
                tabIndex = 1
                break
            default:
                tabIndex -= 4
                break
            }
        }

        let tabCount = tabBarController.viewControllers?.count ?? 0
        tabIndex = min(max(tabIndex, 0), max(tabCount - 1, 0))
        tabBarController.selectedIndex = tabIndex
        saveTabBarIndex(tabIndex)
    }
#endif

    func setupEditToolbar() {
        let colors = PresentationTheme.current.colors
        let editToolbar = EditToolbar()
        self.editToolbar = editToolbar
        editToolbar.isHidden = true
        editToolbar.translatesAutoresizingMaskIntoConstraints = false
        editToolbar.backgroundColor = colors.tabBarColor

#if os(iOS)
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            let sideToolBar = EditToolbar()
            self.sideToolBar = sideToolBar
            sideToolBar.isHidden = true
            sideToolBar.translatesAutoresizingMaskIntoConstraints = false
            sideToolBar.backgroundColor = colors.tabBarColor
            tabBarController.sidebar.bottomBarView = sideToolBar
        }

        let needsBottomToolbar = UIDevice.current.userInterfaceIdiom != .pad
#else
        let needsBottomToolbar = true
#endif
        if needsBottomToolbar {
            tabBarController.view.addSubview(editToolbar)
        }
    }

    // MARK: - Helpers

    @objc func updateTheme() {
        let colors = PresentationTheme.current.colors
        let tabBar = tabBarController.tabBar

#if os(iOS)
        tabBar.isTranslucent = true
#endif

        tabBarController.view.tintColor = colors.orangeUI

        if #unavailable(iOS 26.0) {
            let tabBarLayer = tabBar.layer

            //Setting this in appearanceManager doesn't update tabbar and UINavigationbar of the settingsViewController on change hence we do it here
            tabBar.backgroundColor = colors.tabBarColor
            tabBar.barTintColor = colors.tabBarColor
            tabBar.itemPositioning = .fill

            tabBarLayer.shadowOffset = CGSize(width: 0, height: 0)
            tabBarLayer.shadowRadius = 1.0
            tabBarLayer.shadowColor = colors.cellDetailTextColor.cgColor
            tabBarLayer.shadowOpacity = 0.6
            tabBarLayer.shadowPath = UIBezierPath(rect: tabBar.bounds).cgPath

            tabBarController.view.backgroundColor = colors.background
        }

        editToolbar?.backgroundColor = colors.tabBarColor
        sideToolBar?.backgroundColor = colors.tabBarColor

        if #unavailable(iOS 26.0) {
            UINavigationBar.appearance().standardAppearance = AppearanceManager.navigationbarAppearance()
            UINavigationBar.appearance().compactAppearance = AppearanceManager.navigationbarAppearance()
            UINavigationBar.appearance().scrollEdgeAppearance = AppearanceManager.navigationbarAppearance()
        }
    }

    @objc func handleShortcutItem(_ item: UIApplicationShortcutItem) {
        switch item.type {
        case kVLCApplicationShortcutLastPlayed:
            handleLastPlayedShortcut()
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

    @objc(showTabForMedia:) func showTab(for media: VLCMLMedia) {
        let isVideo = media.type() == .video
        if let index = tabBarController.viewControllers?.firstIndex(where: {
            let rootViewController = ($0 as? UINavigationController)?.viewControllers.first
            return isVideo ? rootViewController is VideoViewController
                           : rootViewController is AudioViewController || rootViewController is TracksViewController
        }) {
            tabBarController.selectedIndex = index
        }
    }

    private func handleLastPlayedShortcut() {
        guard !KeychainCoordinator.passcodeService.hasSecret,
              let lastMedia = mediaLibraryService.lastPlayedMedia() else {
            return
        }

        let album = lastMedia.type() == .audio ? lastMedia.album : nil
        if let album = album {
            openAlbum(album)
        }

        // the queue on disk is only written when backgrounding, hence stale while anything plays
        guard !PlaybackService.sharedInstance().playerIsSetup else {
            return
        }

        let openInMiniPlayer = album != nil
        mediaLibraryService.restoreLastPlayedMediaList(onDemand: true,
                                                      openInMiniPlayer: openInMiniPlayer) {
            PlaybackService.sharedInstance().play(lastMedia, openInMiniPlayer: openInMiniPlayer)
        }
    }

    private func openAlbum(_ album: VLCMLAlbum) {
        let navigationController: UINavigationController
        let mediaViewController: MediaViewController

        if let albumsIndex = tabBarController.viewControllers?.firstIndex(where: {
            ($0 as? UINavigationController)?.viewControllers.first is AlbumsViewController
        }),
           let albumsNavigationController = tabBarController.viewControllers?[albumsIndex] as? UINavigationController,
           let albumsViewController = albumsNavigationController.viewControllers.first as? AlbumsViewController {
            tabBarController.selectedIndex = albumsIndex
            navigationController = albumsNavigationController
            mediaViewController = albumsViewController
        } else {
            guard let audioIndex = tabBarController.viewControllers?.firstIndex(where: {
                ($0 as? UINavigationController)?.viewControllers.first is AudioViewController
            }),
                  let audioNavigationController = tabBarController.viewControllers?[audioIndex] as? UINavigationController,
                  let audioViewController = audioNavigationController.viewControllers.first as? AudioViewController else {
                return
            }

            tabBarController.selectedIndex = audioIndex
            navigationController = audioNavigationController
            mediaViewController = audioViewController
        }

        navigationController.popToRootViewController(animated: false)
        mediaViewController.loadViewIfNeeded()
        guard let categoryViewController = mediaViewController.viewControllers.first(where: {
            $0 is AlbumCategoryViewController
        }) as? MediaCategoryViewController else {
            return
        }
        categoryViewController.pushCollectionViewController(for: album)
    }
}

// MARK: - Last played quick action

extension TabBarCoordinator: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, historyChangedOfType type: VLCMLHistoryType) {
        let subtitle = lastPlayedShortcutSubtitle()
        DispatchQueue.main.async {
            self.updateLastPlayedShortcutItem(subtitle: subtitle)
        }
    }

    @objc func handleDidEnterBackgroundNotification() {
        updateLastPlayedShortcutItem(subtitle: lastPlayedShortcutSubtitle())
    }

    private func lastPlayedShortcutSubtitle() -> String? {
        guard mediaLibraryService.isMediaLibrarySetup,
              !KeychainCoordinator.passcodeService.hasSecret,
              let lastMedia = mediaLibraryService.lastPlayedMedia() else {
            return nil
        }

        return lastMedia.album?.title ?? lastMedia.title
    }

    private func updateLastPlayedShortcutItem(subtitle: String?) {
        let application = UIApplication.shared
        let currentItems = application.shortcutItems ?? []
        let currentItem = currentItems.first { $0.type == kVLCApplicationShortcutLastPlayed }

        // we only ever create this item with a subtitle, so it stands in for the whole state
        guard subtitle != currentItem?.localizedSubtitle else {
            return
        }

        var shortcutItems = currentItems.filter {
            $0.type != kVLCApplicationShortcutLastPlayed
        }

        if let subtitle = subtitle {
            let item = UIApplicationShortcutItem(type: kVLCApplicationShortcutLastPlayed,
                                                 localizedTitle: NSLocalizedString("LAST_PLAYED", comment: ""),
                                                 localizedSubtitle: subtitle,
                                                 icon: UIApplicationShortcutIcon(type: .play),
                                                 userInfo: nil)
            shortcutItems.insert(item, at: 0)
        }

        application.shortcutItems = shortcutItems
    }
}

// MARK: - UITabBarControllerDelegate

extension TabBarCoordinator: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController === tabBarController.selectedViewController {
            ((viewController as? UINavigationController)?.topViewController as? MediaViewController)?.scrollToTop()
        }
        return true
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let viewControllerIndex: Int = tabBarController.viewControllers?.firstIndex(of: viewController) ?? 0
#if os(iOS)
        saveTabBarIndex(viewControllerIndex)
#else
        UserDefaults.standard.set(viewControllerIndex, forKey: kVLCTabBarIndex)
#endif
    }
}

#if os(iOS)
@available(iOS 18.0, *)
extension TabBarCoordinator: UITabBarController.Sidebar.Delegate {
    func tabBarController(_ tabBarController: UITabBarController, sidebarVisibilityWillChange sidebar: UITabBarController.Sidebar, animator: any UITabBarController.Sidebar.Animating) {
        updateTabsForSidebarIfNeeded()
        animator.addCompletion { [weak self] in
            self?.updateTabsForSidebarIfNeeded()
        }
    }

    @available(iOS 27.0, *)
    func tabBarController(_ tabBarController: UITabBarController, sidebarAvailabilityDidChange sidebar: UITabBarController.Sidebar) {
        updateTabsForSidebarIfNeeded()
    }
}
#endif
