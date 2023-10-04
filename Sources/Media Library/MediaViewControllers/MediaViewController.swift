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

    var mediaLibraryService: MediaLibraryService
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
    
    private lazy var historyButton: UIBarButtonItem = {
        var historyButton = UIBarButtonItem(image: UIImage(named: "HistoryClock"),
                                     style: .plain, target: self,
                                     action: #selector(handleHistory))
        historyButton.tintColor = PresentationTheme.current.colors.orangeUI
        historyButton.accessibilityLabel = NSLocalizedString("BUTTON_HISTORY", comment: "")
        historyButton.accessibilityHint = NSLocalizedString("BUTTON_HISTORY_HINT", comment: "")
        return historyButton
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

    private lazy var menuButton: UIBarButtonItem = {
        var buttonItem = UIBarButtonItem()
        buttonItem.image = UIImage(named: "EllipseCircle")
        buttonItem.accessibilityLabel = NSLocalizedString("BUTTON_MENU", comment: "")
        buttonItem.accessibilityHint = NSLocalizedString("BUTTON_MENU_HINT", comment: "")
        return buttonItem
    }()

    private lazy var doneButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(customSetEditing))
    }()

    private var rightBarButtons: [UIBarButtonItem]?
    private var leftBarButtons: [UIBarButtonItem]?

    init(mediaLibraryService: MediaLibraryService) {
        self.mediaLibraryService = mediaLibraryService
        rendererButton = VLCAppCoordinator.sharedInstance().rendererDiscovererManager.setupRendererButton()
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
            rightBarButtons = [menuButton]
        } else {
            rightBarButtons = [editButton]
            leftBarButtons = [sortButton, historyButton]
        }

        if !rendererButton.isHidden {
            rightBarButtons?.append(UIBarButtonItem(customView: rendererButton))
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
        if let mediaCategoryViewController = viewController as? MediaCategoryViewController {
            showButtons = mediaCategoryViewController.isEmptyCollectionView() ? false : true
        }

        if #available(iOS 14.0, *) {
            if let viewController = viewController as? MediaCategoryViewController {
                menuButton.menu = generateMenu(viewController: viewController)
            }
        }
        leftBarButtons = isEditing ? [selectAllButton] : leftBarButtonItems(for: viewController)
        rightBarButtons = isEditing ? [doneButton] : rightBarButtonItems(for: viewController)

        var mediaCategoryViewController: UIViewController = self
        if navigationController?.viewControllers.last is ArtistViewController {
            showButtons = true
            mediaCategoryViewController = self
        } else if viewController is CollectionCategoryViewController {
            mediaCategoryViewController = viewController
        }

        if navigationController?.viewControllers.last is ArtistViewController,
           let viewController = viewControllers[currentIndex] as? CollectionCategoryViewController {
            let playButton = viewController.getPlayAllButton()
            rightBarButtons?.append(playButton)
        }

        mediaCategoryViewController.navigationItem.leftBarButtonItems = showButtons ? leftBarButtons : nil
        mediaCategoryViewController.navigationItem.rightBarButtonItems = showButtons ? rightBarButtons : nil
    }

    private func leftBarButtonItems(for viewController: UIViewController) -> [UIBarButtonItem]? {
        var leftBarButtonItems = [UIBarButtonItem]()

        if #available(iOS 14.0, *) {
            return nil
        } else if viewController is CollectionCategoryViewController ||
                    viewController is ArtistAlbumCategoryViewController {
            return nil
        }

        leftBarButtonItems.append(sortButton)

        if let parentViewController = viewController.parent,
           parentViewController is AudioViewController || parentViewController is VideoViewController {
            leftBarButtonItems.append(historyButton)
        }

        return leftBarButtonItems
    }

    private func rightBarButtonItems(for viewController: UIViewController) -> [UIBarButtonItem] {
        var rightBarButtonItems = [UIBarButtonItem]()

        rightBarButtonItems.append(editButton)
        if navigationController?.viewControllers.last is ArtistViewController ||
            viewController is CollectionCategoryViewController {
            rightBarButtonItems.append(sortButton)
        }

        if #available(iOS 14.0, *) {
            rightBarButtonItems = [menuButton]
        }

        if !rendererButton.isHidden {
            rightBarButtonItems.append(UIBarButtonItem(customView: rendererButton))
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
        return generateMenu(viewController: viewController)
    }

    func needsToUpdateNavigationbarIfNeeded(_ viewController: MediaCategoryViewController) {
        if viewController == viewControllers[currentIndex] {
            updateButtonsFor(viewController)
        } else if viewController is CollectionCategoryViewController {
            updateButtonsFor(viewController)
        }
    }

    func enableCategorySwitching(for viewController: MediaCategoryViewController, enable: Bool) {
        scrollingEnabled(enable)
    }

    func setEditingStateChanged(for viewController: MediaCategoryViewController, editing: Bool) {
        customSetEditing()
    }

    func updateNavigationBarButtons(for viewController: MediaCategoryViewController, isEditing: Bool) {
        leftBarButtons = isEditing ? [selectAllButton] : nil
        if #available(iOS 14.0, *) {
            rightBarButtons = isEditing ? [doneButton] : [menuButton]
        } else {
            rightBarButtons = isEditing ? [doneButton] : [editButton]
        }

        if !rendererButton.isHidden {
            rightBarButtons?.append(UIBarButtonItem(customView: rendererButton))
        }

        viewController.navigationItem.rightBarButtonItems = rightBarButtons
        viewController.navigationItem.leftBarButtonItems = leftBarButtons

        setEditing(isEditing, animated: true)
    }

    func updateSelectAllButton(for viewController: MediaCategoryViewController) {
        selectAllButton.image = viewController.isAllSelected ? UIImage(named: "allSelected") : UIImage(named: "emptySelectAll")
    }
}

// MARK: - Edit

extension MediaViewController {
    @objc private func customSetEditing() {
        isEditing = !isEditing
        var rightButtons: [UIBarButtonItem] = []

        if let mediaCategoryViewController = viewControllers[currentIndex] as? MediaCategoryViewController,
            mediaCategoryViewController.model is MediaGroupViewModel {
            leftBarButtons = isEditing ? [regroupButton, selectAllButton] : [sortButton, historyButton]
            rightButtons = [editButton]
        } else if viewControllers[currentIndex] is ArtistAlbumCategoryViewController ||
                    viewControllers[currentIndex] is CollectionCategoryViewController {
            leftBarButtons = nil
            rightButtons = [editButton, sortButton]
        } else {
            leftBarButtons = isEditing ? [selectAllButton] : [sortButton, historyButton]
            rightButtons = [editButton]
        }

        if #available(iOS 14.0, *) {
            rightButtons = [menuButton]
            // left button is History button
            if isEditing == false {
                leftBarButtons = nil
            }
        }

        if !rendererButton.isHidden {
            rightButtons.append(UIBarButtonItem(customView: rendererButton))
        }

        // Check if the playAllButton should be displayed
        if navigationController?.viewControllers.last is ArtistViewController,
           let viewController = viewControllers[currentIndex] as? CollectionCategoryViewController {
            let playAllButton = viewController.getPlayAllButton()
            rightButtons.append(playAllButton)
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

        if let controllers = navigationController?.viewControllers,
           controllers.count > 1, controllers.last is CollectionCategoryViewController {
            controllers.last?.setEditing(editing, animated: animated)
        } else {
            viewControllers[currentIndex].setEditing(editing, animated: animated)
        }
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
    
    @objc func handleHistory() {
        let mediaType: VLCMLMediaType = viewControllers[currentIndex] is MovieCategoryViewController ? .video : .audio
        let historyView = HistoryCategoryViewController(mediaLibraryService, mediaType: mediaType)
        navigationController?.pushViewController(historyView, animated: true)
    }

    @objc func handleSelectAll() {
        let controller: MediaCategoryViewController
        if let mediaCategoryViewController = navigationController?.viewControllers.last as? CollectionCategoryViewController {
            controller = mediaCategoryViewController
        } else if let mediaCategoryViewController = viewControllers[currentIndex] as? MediaCategoryViewController {
            controller = mediaCategoryViewController
        } else {
            preconditionFailure("MediaViewController: Invalid view controller.")
        }

        controller.handleSelectAll()
        selectAllButton.image = controller.isAllSelected ? UIImage(named: "allSelected") : UIImage(named: "emptySelectAll")
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
            menuButton.menu = generateMenu(viewController: mediaCategoryViewController)
        })

        let listAction = UIAction(title: NSLocalizedString("LIST_LAYOUT", comment: ""),
                                  image: UIImage(systemName: "list.bullet"),
                                  state: isGridLayout ? .off : .on,
                                  handler: {
            [unowned self] _ in
            mediaCategoryViewController.handleLayoutChange(gridLayout: false)
            menuButton.menu = generateMenu(viewController: mediaCategoryViewController)
        })

        return UIMenu(title: NSLocalizedString("DISPLAY_AS", comment: ""), options: .displayInline,
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
                menuButton.menu = generateMenu(viewController: mediaCategoryViewController)
            })
            sortActions.append(action)
        }

        if #available(iOS 15.0, *) {
            return UIMenu(title: NSLocalizedString("SORT_BY", comment: ""),
                          image: UIImage(named: "sort"),
                          options: .singleSelection,
                          children: sortActions)
        } else {
            return UIMenu(title: NSLocalizedString("SORT_BY", comment: ""), options: .displayInline, children: sortActions)
        }
    }

    @available(iOS 14.0, *)
    func generateSelectAction() -> UIAction {
        let selectAction = UIAction(title: NSLocalizedString("BUTTON_SELECT", comment: ""),
                                    image: UIImage(systemName: "checkmark.circle"),
                                    handler: {
            [unowned self] _ in
            customSetEditing()
        })
        selectAction.accessibilityLabel = NSLocalizedString("BUTTON_SELECT", comment: "")
        selectAction.accessibilityHint = NSLocalizedString("BUTTON_SELECT_HINT", comment: "")
        return selectAction
    }

    @available(iOS 14.0, *)
    func generateHistoryMenu() -> UIMenu {
        let historyAction = UIAction(title: NSLocalizedString("BUTTON_HISTORY", comment: ""),
                                     image: UIImage(systemName: "clock.arrow.2.circlepath")) { _ in
            self.handleHistory()
        }

        historyAction.accessibilityLabel = NSLocalizedString("BUTTON_HISTORY", comment: "")
        historyAction.accessibilityHint = NSLocalizedString("BUTTON_HISTORY_HINT", comment: "")

        return UIMenu(options: .displayInline, children: [historyAction])
    }

    @available(iOS 14.0, *)
    func generateMenu(viewController: MediaCategoryViewController?) -> UIMenu {
        guard let mediaCategoryViewController = viewController else {
            preconditionFailure("MediaViewControllers: invalid viewController")
        }

        let selectAction = generateSelectAction()

        var rightMenuItems: [UIMenuElement] = [selectAction]

        if let model = mediaCategoryViewController.model as? CollectionModel,
           model.mediaCollection is VLCMLPlaylist {
            return UIMenu(options: .displayInline, children: rightMenuItems)
        }

        if let parentViewController = viewController?.parent,
           parentViewController is VideoViewController || parentViewController is AudioViewController {
            let historyMenu = generateHistoryMenu()
            rightMenuItems.append(historyMenu)
        }

        let layoutSubMenu = generateLayoutMenu(with: mediaCategoryViewController)
        let sortSubMenu = generateSortMenu(with: mediaCategoryViewController)

        rightMenuItems.append(layoutSubMenu)
        rightMenuItems.append(sortSubMenu)

        var additionalMenuItems: [UIAction] = []

        if mediaCategoryViewController.model is ArtistModel {
            let isIncludeAllArtistActive = UserDefaults.standard.bool(forKey: kVLCAudioLibraryHideFeatArtists)
            let includeAllArtist = UIAction(title: NSLocalizedString("HIDE_FEAT_ARTISTS", comment: ""),
                                            image: UIImage(systemName: "person.3"),
                                            state: isIncludeAllArtistActive ? .on : .off,
                                            handler: { _ in
                mediaCategoryViewController.actionSheetSortSectionHeaderShouldHideFeatArtists(onSwitchIsOnChange: !isIncludeAllArtistActive)
            })

            additionalMenuItems.append(includeAllArtist)
        } else if let model = mediaCategoryViewController.model as? CollectionModel,
                  let mediaCollection = model.mediaCollection as? VLCMLAlbum,
                  !mediaCollection.isUnknownAlbum() {
            let hideTrackNumbers = UserDefaults.standard.bool(forKey: kVLCAudioLibraryHideTrackNumbers)
            let hideTrackNumbersAction = UIAction(title: NSLocalizedString("HIDE_TRACK_NUMBERS", comment: ""),
                                                     state: hideTrackNumbers ? .on : .off,
                                                     handler: { _ in
                mediaCategoryViewController.actionSheetSortSectionHeaderShouldHideTrackNumbers(onSwitchIsOnChange: !hideTrackNumbers)
            })

            additionalMenuItems.append(hideTrackNumbersAction)
        }

        if !additionalMenuItems.isEmpty {
            let additionalMenu: UIMenu = UIMenu(title: NSLocalizedString("ADDITIONAL_OPTIONS", comment: ""),
                                                options: .displayInline,
                                                children: additionalMenuItems)
            rightMenuItems.append(additionalMenu)
        }

        return UIMenu(options: .displayInline, children: rightMenuItems)
    }
}
