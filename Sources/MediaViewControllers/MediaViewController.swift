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
    private lazy var sortButton: UIBarButtonItem = {
        var sortButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        sortButton.setImage(UIImage(named: "sort"), for: .normal)
        // It seems that using a custom view, UIBarButtonItem have a offset of 16, therefore adding a large margin
        if UIView.userInterfaceLayoutDirection(for: sortButton.semanticContentAttribute) == .rightToLeft {
            sortButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -16)
        } else {
            sortButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
        }
        sortButton.addTarget(self, action: #selector(handleSort), for: .touchUpInside)
        sortButton.tintColor = PresentationTheme.current.colors.orangeUI
        sortButton.accessibilityLabel = NSLocalizedString("BUTTON_SORT", comment: "")
        sortButton.accessibilityHint = NSLocalizedString("BUTTON_SORT_HINT", comment: "")
        sortButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self,
                                                                     action: #selector(handleSortShortcut(sender:))))
        return UIBarButtonItem(customView: sortButton)
    }()

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

// MARK: - Sort

extension VLCMediaViewController {
    @objc func handleSort() {
        if let mediaCategoryViewController = viewControllers[currentIndex] as? VLCMediaCategoryViewController {
            mediaCategoryViewController.handleSort()
        }
    }

    @objc func handleSortShortcut(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            if #available(iOS 10.0, *) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            if let mediaCategoryViewController = viewControllers[currentIndex] as? VLCMediaCategoryViewController {
                mediaCategoryViewController.handleSortShortcut()
            }
        }
    }
}
