/*****************************************************************************
 * MediaSubcategoryViewController.swift
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

class VLCVideoSubcategoryViewController: VLCMediaSubcategoryViewController {
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let movies = VLCMediaViewController(services: services, type: VLCMediaType(category: .video, subcategory: .allVideos))
        let episodes = VLCMediaViewController(services: services, type: VLCMediaType(category: .video, subcategory: .episodes))
        let playlists = VLCMediaViewController(services: services, type: VLCMediaType(category: .video, subcategory: .videoPlaylists))
        let viewControllers = [movies, episodes, playlists]
        viewControllers.forEach { $0.delegate = mediaDelegate }
        return viewControllers
    }
}

class VLCAudioSubcategoryViewController: VLCMediaSubcategoryViewController {
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let tracks = VLCMediaViewController(services: services, type: VLCMediaType(category: .audio, subcategory: .tracks))
        let genres = VLCMediaViewController(services: services, type: VLCMediaType(category: .audio, subcategory: .genres))
        let artists = VLCMediaViewController(services: services, type: VLCMediaType(category: .audio, subcategory: .artists))
        let albums = VLCMediaViewController(services: services, type: VLCMediaType(category: .audio, subcategory: .albums))
        let playlists = VLCMediaViewController(services: services, type: VLCMediaType(category: .audio, subcategory: .audioPlaylists))
        let viewControllers = [tracks, genres, artists, albums, playlists]
        viewControllers.forEach { $0.delegate = mediaDelegate }
        return viewControllers
    }
}

class VLCMediaSubcategoryViewController: BaseButtonBarPagerTabStripViewController<VLCLabelCell> {

    var services: Services
    weak var mediaDelegate: VLCMediaViewControllerDelegate?
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
