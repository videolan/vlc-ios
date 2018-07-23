/*****************************************************************************
 * MediaViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class VLCVideoViewController: VLCMediaViewController {

    override init(services: Services) {
        super.init(services: services)
        setupUI()
    }

    private func setupUI() {
        title = NSLocalizedString("VIDEO", comment: "")
        tabBarItem = UITabBarItem(
            title: NSLocalizedString("VIDEO", comment: ""),
            image: UIImage(named: "TVShowsIcon"),
            selectedImage: UIImage(named: "TVShowsIcon"))
        tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.video
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let movies = VLCMediaCategoryViewController<MLFile>(services: services, subcategory: VLCMediaSubcategories.movies)
        movies.delegate = super.self()
        let episodes = VLCMediaCategoryViewController<MLShowEpisode>(services: services, subcategory: VLCMediaSubcategories.episodes)
        episodes.delegate = super.self()
        let playlists = VLCMediaCategoryViewController<MLLabel>(services: services, subcategory: VLCMediaSubcategories.videoPlaylists)
        playlists.delegate = super.self()
        return [movies, episodes, playlists]
    }
}

class VLCAudioViewController: VLCMediaViewController {

    override init(services: Services) {
        super.init(services: services)
        setupUI()
    }

    private func setupUI() {
        title = NSLocalizedString("AUDIO", comment: "")
        tabBarItem = UITabBarItem(
            title: NSLocalizedString("AUDIO", comment: ""),
            image: UIImage(named: "MusicAlbums"),
            selectedImage: UIImage(named: "MusicAlbums"))
        tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.audio
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let tracks = VLCMediaCategoryViewController<MLFile>(services: services, subcategory: VLCMediaSubcategories.tracks)
        tracks.delegate = super.self()
        let genres = VLCMediaCategoryViewController<String>(services: services, subcategory: VLCMediaSubcategories.genres)
        genres.delegate = super.self()
        let artists = VLCMediaCategoryViewController<String>(services: services, subcategory: VLCMediaSubcategories.artists)
        artists.delegate = super.self()
        let albums = VLCMediaCategoryViewController<MLAlbum>(services: services, subcategory: VLCMediaSubcategories.albums)
        albums.delegate = super.self()
        let playlists = VLCMediaCategoryViewController<MLLabel>(services: services, subcategory: VLCMediaSubcategories.audioPlaylists)
        playlists.delegate = super.self()
        return [tracks, genres, artists, albums, playlists]
    }
}

class VLCMediaViewController: VLCPagingViewController<VLCLabelCell> {
    var services: Services
    private var rendererButton: UIButton

    init(services: Services) {
        self.services = services
        rendererButton = services.rendererDiscovererManager.setupRendererButton()
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {

        changeCurrentIndexProgressive = { (oldCell: VLCLabelCell?, newCell: VLCLabelCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) in
            guard changeCurrentIndex == true else { return }
            oldCell?.iconLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
            newCell?.iconLabel.textColor = PresentationTheme.current.colors.orangeUI
        }
        setupNavigationBar()
        super.viewDidLoad()
    }

    private func setupNavigationBar() {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("SORT", comment: ""), style: .plain, target: self, action: #selector(sort))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rendererButton)
    }

    @objc func sort() {
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
        present(sortOptionsAlertController, animated: true)
    }

    // MARK: - PagerTabStripDataSource

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        fatalError("this should only be used as subclass")
    }

    override func configure(cell: VLCLabelCell, for indicatorInfo: IndicatorInfo) {
        cell.iconLabel.text = indicatorInfo.title
    }

    override func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        super.updateIndicator(for: viewController, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage, indexWasChanged: indexWasChanged)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }
}

// MARK: - VLCMediaCategoryViewControllerDelegate
extension VLCMediaViewController: VLCMediaCategoryViewControllerDelegate {

    func mediaViewControllerDidSelectMediaObject(_ viewcontroller: UIViewController, mediaObject: NSManagedObject) {
        playMedia(media: mediaObject)
    }

    func playMedia(media: NSManagedObject) {
        //that should go into a Coordinator itself
        let vpc = VLCPlaybackController.sharedInstance()
        vpc?.playMediaLibraryObject(media)
    }
}
