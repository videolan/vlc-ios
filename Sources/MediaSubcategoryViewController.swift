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

class VLCVideoSubcategoryViewController: VLCMediaSubcategoryViewController
{
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let movies = VLCMediaViewController(services: services, type: VLCMediaType(category: .video, subcategory: .allVideos))
        let episodes = VLCMediaViewController(services: services, type: VLCMediaType(category: .video, subcategory: .episodes))
        let playlists = VLCMediaViewController(services: services, type: VLCMediaType(category: .video, subcategory: .videoPlaylists))
        return [movies, episodes, playlists]
    }
}

class VLCAudioSubcategoryViewController: VLCMediaSubcategoryViewController
{
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let tracks = VLCMediaViewController(services: services, type: VLCMediaType(category: .audio, subcategory: .tracks))
        let genres = VLCMediaViewController(services: services, type: VLCMediaType(category: .audio, subcategory: .genres))
        let artists = VLCMediaViewController(services: services, type: VLCMediaType(category: .audio, subcategory: .artists))
        let albums = VLCMediaViewController(services: services, type: VLCMediaType(category: .audio, subcategory: .albums))
        let playlists = VLCMediaViewController(services: services, type: VLCMediaType(category: .audio, subcategory: .audioPlaylists))
        return [tracks, genres, artists, albums, playlists]
    }
}

class VLCMediaSubcategoryViewController: BaseButtonBarPagerTabStripViewController<IconLabelCell> {

    internal var services: Services

    init(services: Services) {
        self.services = services
        super.init(nibName: nil, bundle: nil)
        buttonBarItemSpec = ButtonBarItemSpec.nibFile(nibName: "IconLabelCell", bundle: Bundle.main, width: { _ in
            return 70.0
        })
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        // change selected bar color
        settings.style.buttonBarBackgroundColor = .white
        settings.style.selectedBarBackgroundColor = PresentationTheme.current.colors.orangeUI
        settings.style.selectedBarHeight = 4.0
        settings.style.buttonBarItemTitleColor = .black
        settings.style.buttonBarItemsShouldFillAvailableWidth = true

        changeCurrentIndexProgressive = { (oldCell: IconLabelCell?, newCell: IconLabelCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) in
            guard changeCurrentIndex == true else { return }
            oldCell?.iconImage.tintColor = PresentationTheme.current.colors.cellDetailTextColor
            oldCell?.iconLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
            newCell?.iconImage.tintColor = PresentationTheme.current.colors.orangeUI
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

    override func configure(cell: IconLabelCell, for indicatorInfo: IndicatorInfo) {
        cell.iconImage.image = indicatorInfo.image?.withRenderingMode(.alwaysTemplate)
        cell.iconLabel.text = indicatorInfo.title?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    override func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        super.updateIndicator(for: viewController, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage, indexWasChanged: indexWasChanged)
        if indexWasChanged && toIndex >= 0 && toIndex < viewControllers.count {
            let child = viewControllers[toIndex] as! IndicatorInfoProvider
            UIView.performWithoutAnimation({ [weak self] in
                guard let me = self else { return }
                me.navigationItem.leftBarButtonItem?.title =  child.indicatorInfo(for: me).title
            })
        }
    }

}
