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
import Foundation

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

    // MARK: UIMenu & UIActions

    @available(iOS 14.0, *)
    private lazy var rightMenuItems: [UIMenuElement] = []

    @available(iOS 14.0, *)
    private lazy var menuButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "EllipseCircle"),
                               menu: generateMenu())
    }()

    @available(iOS 14.0, *)
    private lazy var selectAction: UIAction = {
        let selectAction = UIAction(title: NSLocalizedString("BUTTON_EDIT", comment: ""),
                                    image: UIImage(systemName: "checkmark.circle"),
                                    handler: {
            [unowned self] _ in
            customSetEditing()
        })
        selectAction.accessibilityLabel = NSLocalizedString("BUTTON_EDIT", comment: "")
        selectAction.accessibilityHint = NSLocalizedString("BUTTON_EDIT_HINT", comment: "")
        return selectAction
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
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
    }

    override func viewDidLoad() {
        changeCurrentIndexProgressive = { (oldCell: VLCLabelCell?, newCell: VLCLabelCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) in
            guard changeCurrentIndex == true else { return }
            oldCell?.iconLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
            newCell?.iconLabel.textColor = PresentationTheme.current.colors.orangeUI
        }
        super.viewDidLoad()
        if #available(iOS 14.0, *) {
            rightBarButtons = [menuButton, UIBarButtonItem(customView: rendererButton)]
        } else {
            rightBarButtons = [editButton, UIBarButtonItem(customView: rendererButton)]
            leftBarButtons = [sortButton]
        }

        viewControllers.forEach {
            ($0 as? MediaCategoryViewController)?.delegate = self
        }
        setupNavigationBar()
    }

    private func setupSortbutton() -> UIButton {
        let sortButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))

        sortButton.setImage(UIImage(named: "sort"), for: .normal)
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

        if #available(iOS 14.0, *) {
            // Update menu for new ViewController
            menuButton.menu = generateMenu()
        }

        if navigationController?.viewControllers.last is ArtistViewController {
            showButtons = true
            leftBarButtons = isEditing ? [selectAllButton] : nil
            rightBarButtons = isEditing ? [doneButton] : rightBarButtonItems()
        }

        navigationItem.rightBarButtonItems = showButtons ? rightBarButtons : nil
        navigationItem.leftBarButtonItems = showButtons ? leftBarButtons : nil
    }

    private func rightBarButtonItems() -> [UIBarButtonItem] {
        var rightBarButtonItems = [UIBarButtonItem]()

        rightBarButtonItems.append(editButton)
        if navigationController?.viewControllers.last is ArtistViewController {
            rightBarButtonItems.append(sortButton)
        }

        if !rendererButton.isHidden {
            rightBarButtonItems.append(UIBarButtonItem(customView: rendererButton))
        }
        if #available(iOS 14.0, *) {
            rightBarButtonItems = [menuButton, UIBarButtonItem(customView: rendererButton)]
        }
        return rightBarButtonItems
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
    @available(iOS 14.0, *)
    func generateMenu(for viewController: MediaCategoryViewController) -> UIMenu {
        return generateMenu()
    }

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

    func updateNavigationBarButtons(isEditing: Bool) {
        leftBarButtons = isEditing ? [selectAllButton] : nil
        rightBarButtons = isEditing ? [doneButton] : [editButton, sortButton, UIBarButtonItem(customView: rendererButton)]

        navigationItem.rightBarButtonItems = rightBarButtons
        navigationItem.leftBarButtonItems = leftBarButtons

        setEditing(isEditing, animated: true)
    }
}

// MARK: - Edit

extension MediaViewController {
    @objc private func customSetEditing() {
        isEditing = !isEditing
        if let mediaCategoryViewController = viewControllers[currentIndex] as? MediaCategoryViewController,
            mediaCategoryViewController.model is MediaGroupViewModel {
            leftBarButtons = isEditing ? [regroupButton, selectAllButton] : [sortButton]
        } else if navigationController?.viewControllers.last is ArtistViewController {
            leftBarButtons = viewControllers[currentIndex].isEditing ? [selectAllButton] : nil
        } else {
            leftBarButtons = isEditing ? [selectAllButton] : [sortButton]
        }

        var rightButtons = [editButton, UIBarButtonItem(customView: rendererButton)]

        if #available(iOS 14.0, *) {
            rightButtons = [menuButton, UIBarButtonItem(customView: rendererButton)]
            // No left buttons with UIMenu
            if isEditing == false {
                leftBarButtons = nil
            }
        }
        rightBarButtons = isEditing ? [doneButton] : rightButtons
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

// MARK: - UIMenu

extension MediaViewController {
    @available(iOS 14.0, *)
    func generateLayoutMenu(with mediaCategoryViewController: MediaCategoryViewController) -> UIMenu {
        let isGridLayout: Bool = mediaCategoryViewController.model.cellType == MovieCollectionViewCell.self
        || mediaCategoryViewController.model.cellType == MediaGridCollectionCell.self

        let gridAction = UIAction(title: NSLocalizedString("GRID_LAYOUT", comment: ""),
                                  image: UIImage(systemName: "square.grid.2x2"),
                                  state: isGridLayout ? .on : .off,
                                  handler: {
            [unowned self] _ in
            mediaCategoryViewController.handleLayoutChange(gridLayout: true)
            menuButton.menu = generateMenu()
        })

        let listAction = UIAction(title: NSLocalizedString("LIST_LAYOUT", comment: ""),
                                  image: UIImage(systemName: "list.bullet"),
                                  state: isGridLayout ? .off : .on,
                                  handler: {
            [unowned self] _ in
            mediaCategoryViewController.handleLayoutChange(gridLayout: false)
            menuButton.menu = generateMenu()
        })

        return UIMenu(options: .displayInline,
                      children: [gridAction, listAction])
    }

    @available(iOS 14.0, *)
    func generateSortMenu(with mediaCategoryViewController: MediaCategoryViewController) -> UIMenu {
        let sortModel = mediaCategoryViewController.model.sortModel
        var sortActions: [UIMenuElement] = []

        var currentSortIndex: Int = 0
        for (index, criterion) in
                sortModel.sortingCriteria.enumerated()
        where criterion == sortModel.currentSort {
            currentSortIndex = index
            break
        }

        for (index, criterion) in sortModel.sortingCriteria.enumerated() {
            let currentSort: Bool = index == currentSortIndex
            let chevronImageName: String = sortModel.desc ? "chevron.down" : "chevron.up"
            let actionImage: UIImage? = currentSort ?
            UIImage(systemName: chevronImageName) : nil

            let action = UIAction(title: String(describing: criterion),
                                  image: actionImage,
                                  state: currentSort ? .on : .off,
                                  handler: {
                [unowned self] _ in
                mediaCategoryViewController.executeSortAction(with: criterion,
                                                              desc: !sortModel.desc)
                menuButton.menu = generateMenu()
            })
            sortActions.append(action)
        }
        return UIMenu(options: .displayInline, children: sortActions)
    }

    @available(iOS 14.0, *)
    func generateMenu() -> UIMenu {
        guard let mediaCategoryViewController = viewControllers[currentIndex] as? MediaCategoryViewController else {
            preconditionFailure("MediaViewControllers: viewControllers wrong class.")
        }
        let layoutSubMenu = generateLayoutMenu(with: mediaCategoryViewController)
        let sortSubMenu = generateSortMenu(with: mediaCategoryViewController)

        rightMenuItems = [selectAction, layoutSubMenu, sortSubMenu]

        if mediaCategoryViewController.model is ArtistModel {
            let isIncludeAllArtistActive = UserDefaults.standard.bool(forKey: kVLCAudioLibraryHideFeatArtists)
            let includeAllArtist = UIAction(title: NSLocalizedString("HIDE_FEAT_ARTISTS", comment: ""),
                                            image: UIImage(systemName: "person.3"),
                                            state: isIncludeAllArtistActive ? .on : .off,
                                            handler: { _ in
                mediaCategoryViewController.actionSheetSortSectionHeaderShouldHideFeatArtists(onSwitchIsOnChange: !isIncludeAllArtistActive)
            })
            rightMenuItems.append(includeAllArtist)
        }

        return UIMenu(options: .displayInline, children: rightMenuItems)
    }
}
