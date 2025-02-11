/*****************************************************************************
 * AudioViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class AudioViewController: MediaViewController {
    override init(mediaLibraryService: MediaLibraryService) {
        super.init(mediaLibraryService: mediaLibraryService)
        setupUI()
    }

    private func setupUI() {
        title = NSLocalizedString("AUDIO", comment: "")
        tabBarItem = UITabBarItem(
            title: NSLocalizedString("AUDIO", comment: ""),
            image: UIImage(named: "Audio"),
            selectedImage: UIImage(named: "Audio"))
        tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.audio
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [
            ArtistCategoryViewController(mediaLibraryService),
            AlbumCategoryViewController(mediaLibraryService),
            TrackCategoryViewController(mediaLibraryService),
            GenreCategoryViewController(mediaLibraryService),
            FolderViewController(
                mediaLibraryService,
                isAudio: true,
                folder: mediaLibraryService.medialib.folder(atMrl: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!)!
            ),

        ]
    }

    func resetTitleView() {
        navigationItem.titleView = nil
    }
}

class ArtistsViewController: MediaViewController {
    override init(mediaLibraryService: MediaLibraryService) {
        super.init(mediaLibraryService: mediaLibraryService)
        setupUI()
    }

    private func setupUI() {
        let localizedTitle: String = NSLocalizedString("ARTISTS", comment: "")
        title = localizedTitle

        let image: UIImage?
        if #available(iOS 13.0, *) {
            let color: UIColor = PresentationTheme.current.colors.tabBarIconColor
            image = UIImage(named: "artists")?.withTintColor(color)
        } else {
            image = UIImage(named: "artists")
        }

        tabBarItem = UITabBarItem(title: localizedTitle, image: image, selectedImage: image)
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [ArtistCategoryViewController(mediaLibraryService)]
    }
}

class AlbumsViewController: MediaViewController {
    override init(mediaLibraryService: MediaLibraryService) {
        super.init(mediaLibraryService: mediaLibraryService)
        setupUI()
    }

    private func setupUI() {
        let localizedTitle: String = NSLocalizedString("ALBUMS", comment: "")
        title = localizedTitle

        let image: UIImage?
        if #available(iOS 13.0, *) {
            let color: UIColor = PresentationTheme.current.colors.tabBarIconColor
            image = UIImage(named: "albums")?.withTintColor(color)
        } else {
            image = UIImage(named: "albums")
        }

        tabBarItem = UITabBarItem(title: localizedTitle, image: image, selectedImage: image)
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [AlbumCategoryViewController(mediaLibraryService)]
    }
}

class TracksViewController: MediaViewController {
    override init(mediaLibraryService: MediaLibraryService) {
        super.init(mediaLibraryService: mediaLibraryService)
        setupUI()
    }

    private func setupUI() {
        let localizedTitle: String = NSLocalizedString("SONGS", comment: "")
        title = localizedTitle

        let image: UIImage?
        if #available(iOS 13.0, *) {
            let color: UIColor = PresentationTheme.current.colors.tabBarIconColor
            image = UIImage(named: "songs")?.withTintColor(color)
        } else {
            image = UIImage(named: "songs")
        }

        tabBarItem = UITabBarItem(title: localizedTitle, image: image, selectedImage: image)
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [TrackCategoryViewController(mediaLibraryService)]
    }
}

class GenresViewController: MediaViewController {
    override init(mediaLibraryService: MediaLibraryService) {
        super.init(mediaLibraryService: mediaLibraryService)
        setupUI()
    }

    private func setupUI() {
        let localizedTitle: String = NSLocalizedString("GENRES", comment: "")
        title = localizedTitle

        let image: UIImage?
        if #available(iOS 13.0, *) {
            let color: UIColor = PresentationTheme.current.colors.tabBarIconColor
            image = UIImage(named: "genres")?.withTintColor(color)
        } else {
            image = UIImage(named: "genres")
        }

        tabBarItem = UITabBarItem(title: localizedTitle, image: image, selectedImage: image)
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [GenreCategoryViewController(mediaLibraryService)]
    }
}
