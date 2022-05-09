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

class MediaViewController: VLCPagingViewController<VLCLabelCell> {

    var services: Services
    private var rendererButton: UIButton
    private(set) lazy var sortButton: UIBarButtonItem = {
        let sortButton = setupSortbutton()

        sortButton.addTarget(self, action: #selector(handleSort), for: .touchUpInside)
        sortButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self,
                                                                     action: #selector(handleSortShortcut(sender:))))
        return UIBarButtonItem(customView: sortButton)
    }()

    private lazy var editButton: UIBarButtonItem = {
        var editButton = UIBarButtonItem(image: UIImage(named: "edit"),
                                     style: .plain, target: self,
                                     action: #selector(customSetEditing))
        editButton.tintColor = PresentationTheme.current.colors.orangeUI
        editButton.accessibilityLabel = NSLocalizedString("BUTTON_EDIT", comment: "")
        editButton.accessibilityHint = NSLocalizedString("BUTTON_EDIT_HINT", comment: "")
        return editButton
    }()

    private lazy var regroupButton: UIBarButtonItem = {
        var regroup = UIBarButtonItem(image: UIImage(named: "regroupMediaGroups"),
                                     style: .plain, target: self,
                                     action: #selector(handleRegroup))
        regroup.tintColor = PresentationTheme.current.colors.orangeUI
        regroup.accessibilityLabel = NSLocalizedString("BUTTON_REGROUP", comment: "")
        regroup.accessibilityHint = NSLocalizedString("BUTTON_REGROUP_HINT", comment: "")
        return regroup
    }()

    private lazy var selectAllButton: UIBarButtonItem = {
        var selectAll = UIBarButtonItem(image: UIImage(named: "emptySelectAll"),
                                        style: .plain, target: self,
                                        action: #selector(handleSelectAll))
        selectAll.accessibilityLabel = NSLocalizedString("BUTTON_SELECT_ALL", comment: "")
        selectAll.accessibilityHint = NSLocalizedString("BUTTON_SELECT_ALL_HINT", comment: "")
        return selectAll
    }()


    private lazy var doneButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(customSetEditing))
    }()

    private var rightBarButtons: [UIBarButtonItem]?
    private var leftBarButtons: [UIBarButtonItem]?

    init(services: Services) {
        self.services = services
        rendererButton = services.rendererDiscovererManager.setupRendererButton()
        super.init(nibName: nil, bundle: nil)
        rightBarButtons = [editButton, UIBarButtonItem(customView: rendererButton)]
        leftBarButtons = [sortButton]
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
    }

    override func viewDidLoad() {

        changeCurrentIndexProgressive = { (oldCell: VLCLabelCell?, newCell: VLCLabelCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) in
            guard changeCurrentIndex == true else { return }
            oldCell?.iconLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
            newCell?.iconLabel.textColor = PresentationTheme.current.colors.orangeUI
        }
        super.viewDidLoad()
        viewControllers.forEach {
            ($0 as? MediaCategoryViewController)?.delegate = self
        }
        setupNavigationBar()
    }

    private func setupSortbutton() -> UIButton {
        let sortButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))

        sortButton.setImage(UIImage(named: "sort"), for: .normal)
        // It seems that using a custom view, UIBarButtonItem have a offset of 16, therefore adding a large margin
        if UIView.userInterfaceLayoutDirection(for: sortButton.semanticContentAttribute) == .rightToLeft {
            sortButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -16)
        } else {
            sortButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
        }
        sortButton.tintColor = PresentationTheme.current.colors.orangeUI
        sortButton.accessibilityLabel = NSLocalizedString("BUTTON_SORT", comment: "")
        sortButton.accessibilityHint = NSLocalizedString("BUTTON_SORT_HINT", comment: "")
        return sortButton
    }

    private func setupNavigationBar() {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance = AppearanceManager.navigationbarAppearance()
            navigationController?.navigationBar.scrollEdgeAppearance = AppearanceManager.navigationbarAppearance()
        }
        navigationController?.navigationBar.isTranslucent = false
        setNeedsStatusBarAppearanceUpdate()
        updateButtonsFor(viewControllers[currentIndex])
    }

    @objc private func updateTheme() {
        if containerView != nil {
            containerView.backgroundColor = PresentationTheme.current.colors.background
        }
    }

    // MARK: - PagerTabStripDataSource

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        fatalError("this should only be used as subclass")
    }

    func updateButtonsFor(_ viewController: UIViewController) {
        var showButtons = false
        if let mediaCategoryViewController = viewController as? MediaCategoryViewController,
            !mediaCategoryViewController.isSearching {
            showButtons = true
            showButtons = mediaCategoryViewController.isEmptyCollectionView() ? false : true
        }
        navigationItem.rightBarButtonItems = showButtons ? rightBarButtons : nil
        navigationItem.leftBarButtonItems = showButtons ? leftBarButtons : nil
    }

    override func configure(cell: VLCLabelCell, for indicatorInfo: IndicatorInfo) {
        cell.iconLabel.adjustsFontSizeToFitWidth = true
        cell.iconLabel.text = indicatorInfo.title
        cell.iconLabel.font = UIFont.preferredCustomFont(forTextStyle: .headline).bolded
        cell.accessibilityIdentifier = indicatorInfo.accessibilityIdentifier
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

// MARK: - MediaCatgoryViewControllerDelegate

extension MediaViewController: MediaCategoryViewControllerDelegate {
    func needsToUpdateNavigationbarIfNeeded(_ viewController: MediaCategoryViewController) {
        if viewController == viewControllers[currentIndex] {
            updateButtonsFor(viewController)
        }
    }

    func enableCategorySwitching(for viewController: MediaCategoryViewController, enable: Bool) {
        scrollingEnabled(enable)
    }

    func setEditingStateChanged(for viewController: MediaCategoryViewController, editing: Bool) {
        customSetEditing()
    }

    func updateSelectAllButton(for viewController: MediaCategoryViewController) {
        selectAllButton.image = viewController.isAllSelected ? UIImage(named: "allSelected") : UIImage(named: "emptySelectAll")
    }
}

// MARK: - Edit

extension MediaViewController {
    @objc private func customSetEditing() {
        isEditing = !isEditing
        rightBarButtons = isEditing ? [doneButton] : [editButton, UIBarButtonItem(customView: rendererButton)]

        if let mediaCategoryViewController = viewControllers[currentIndex] as? MediaCategoryViewController,
            mediaCategoryViewController.model is MediaGroupViewModel {
            leftBarButtons = isEditing ? [regroupButton, selectAllButton] : [sortButton]
        } else {
            leftBarButtons = isEditing ? [selectAllButton] : [sortButton]
        }
        navigationItem.rightBarButtonItems = rightBarButtons
        navigationItem.leftBarButtonItems = leftBarButtons

        if isEditing == false {
            selectAllButton.image = UIImage(named: "emptySelectAll")
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        scrollingEnabled(!editing)
        viewControllers[currentIndex].setEditing(editing, animated: animated)
    }
}

// MARK: - Sort

extension MediaViewController {
    @objc func handleRegroup() {
        if let mediaCategoryViewController = viewControllers[currentIndex] as? MediaCategoryViewController {
            guard mediaCategoryViewController.model is MediaGroupViewModel else {
                assertionFailure("MediaViewController: handleRegroup: Mismatching model can't regroup.")
                return
            }
            mediaCategoryViewController.handleRegroup()
        }
    }

    @objc func handleSelectAll() {
        if let mediaCategoryViewController = viewControllers[currentIndex] as? MediaCategoryViewController {
            mediaCategoryViewController.handleSelectAll()
            selectAllButton.image = mediaCategoryViewController.isAllSelected ? UIImage(named: "allSelected")
                : UIImage(named: "emptySelectAll")
        }
    }

    @objc func handleSort() {
        if let mediaCategoryViewController = viewControllers[currentIndex] as? MediaCategoryViewController {
            mediaCategoryViewController.handleSort()
        }
    }

    @objc func handleSortShortcut(sender: UILongPressGestureRecognizer) {
        if let mediaCategoryViewController = viewControllers[currentIndex] as? MediaCategoryViewController {
            mediaCategoryViewController.handleSortLongPress(sender: sender)
        }
    }
}
