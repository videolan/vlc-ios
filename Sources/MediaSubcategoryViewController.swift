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

    init(services: Services) {
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {

        changeCurrentIndexProgressive = { (oldCell: VLCLabelCell?, newCell: VLCLabelCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) in
            guard changeCurrentIndex == true else { return }
            oldCell?.iconLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
            newCell?.iconLabel.textColor = PresentationTheme.current.colors.orangeUI
        }
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        super.viewDidLoad()
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
        if indexWasChanged && toIndex >= 0 && toIndex < viewControllers.count {
            let child = viewControllers[toIndex] as! IndicatorInfoProvider
            UIView.performWithoutAnimation({ [weak self] in
                guard let me = self else { return }
                me.navigationItem.leftBarButtonItem?.title = child.indicatorInfo(for: me).title
            })
        }
    }

}
