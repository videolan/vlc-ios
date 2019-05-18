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

class VLCMediaViewController: VLCPagingViewController<VLCLabelCell> {
    var services: Services
    private var rendererButton: UIButton
    private var sortButton: UIBarButtonItem?

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
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.rightBarButtonItems = [editButtonItem, UIBarButtonItem(customView: rendererButton)]
        sortButton = UIBarButtonItem(title: NSLocalizedString("SORT", comment: ""),
                                     style: .plain,
                                     target: self,
                                     action: #selector(handleSort))
        navigationItem.leftBarButtonItem = sortButton
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

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        scrollingEnabled(!editing)
        navigationItem.leftBarButtonItem = editing ? nil : sortButton
        viewControllers[currentIndex].setEditing(editing, animated: animated)
    }

    @objc func handleSort() {
        if let mediaCategoryViewController = viewControllers[currentIndex] as? VLCMediaCategoryViewController {
            mediaCategoryViewController.handleSort()
        }
    }
}
