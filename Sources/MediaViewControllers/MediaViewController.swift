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

class VLCMediaViewController: VLCPagingViewController<VLCLabelCell>, MediaCategoryViewControllerDelegate {

    var services: Services
    private var rendererButton: UIButton
    private var sortButton: UIBarButtonItem?
    private lazy var editButton: UIBarButtonItem = {
        var editButton = UIBarButtonItem(image: UIImage(named: "edit"),
                                     style: .plain, target: self,
                                     action: #selector(customSetEditing(button:)))
        editButton.tintColor = PresentationTheme.current.colors.orangeUI
        editButton.accessibilityLabel = NSLocalizedString("BUTTON_EDIT", comment: "")
        editButton.accessibilityHint = NSLocalizedString("BUTTON_EDIT_HINT", comment: "")
        return editButton
    }()

    private var rigthBarButtons: [UIBarButtonItem]?

    init(services: Services) {
        self.services = services
        rendererButton = services.rendererDiscovererManager.setupRendererButton()
        super.init(nibName: nil, bundle: nil)
        sortButton = UIBarButtonItem(title: NSLocalizedString("SORT", comment: ""),
                                     style: .plain,
                                     target: self,
                                     action: #selector(handleSort))
        rigthBarButtons = [editButton, UIBarButtonItem(customView: rendererButton)]
    }

    override func viewDidLoad() {

        changeCurrentIndexProgressive = { (oldCell: VLCLabelCell?, newCell: VLCLabelCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) in
            guard changeCurrentIndex == true else { return }
            oldCell?.iconLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
            newCell?.iconLabel.textColor = PresentationTheme.current.colors.orangeUI
        }
        super.viewDidLoad()
        viewControllers.forEach {
            ($0 as? VLCMediaCategoryViewController)?.delegate = self
        }
        setupNavigationBar()
    }

    private func setupNavigationBar() {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        navigationController?.navigationBar.isTranslucent = false
        updateButtonsFor(viewControllers[currentIndex])
    }
    // MARK: - MediaCatgoryViewControllerDelegate

    func needsToUpdateNavigationbarIfNeeded(_ viewController: VLCMediaCategoryViewController) {
        if viewController == viewControllers[currentIndex] {
            updateButtonsFor(viewController)
        }
    }
    // MARK: - PagerTabStripDataSource

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        fatalError("this should only be used as subclass")
    }

    func updateButtonsFor(_ viewController: UIViewController) {
        var showButtons = false
        if let mediaCategoryViewController = viewController as? VLCMediaCategoryViewController,
            !mediaCategoryViewController.isEmptyCollectionView()
                && !mediaCategoryViewController.isSearching {
            showButtons = true
        }
        navigationItem.rightBarButtonItems = showButtons ? rigthBarButtons : nil
        navigationItem.leftBarButtonItem = showButtons ? sortButton : nil
    }

    override func configure(cell: VLCLabelCell, for indicatorInfo: IndicatorInfo) {
        cell.iconLabel.text = indicatorInfo.title
    }

    override func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        if indexWasChanged {
            updateButtonsFor(viewControllers[toIndex])
        }
        super.updateIndicator(for: viewController, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage, indexWasChanged: indexWasChanged)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    @objc func handleSort() {
        if let mediaCategoryViewController = viewControllers[currentIndex] as? VLCMediaCategoryViewController {
            mediaCategoryViewController.handleSort()
        }
    }
}

// MARK: - Edit

extension VLCMediaViewController {
    @objc private func customSetEditing(button: UIButton) {
        isEditing = !isEditing
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        scrollingEnabled(!editing)
        navigationItem.leftBarButtonItem = editing ? nil : sortButton
        viewControllers[currentIndex].setEditing(editing, animated: animated)
    }
}
