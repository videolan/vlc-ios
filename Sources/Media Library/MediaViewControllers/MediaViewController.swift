/*****************************************************************************
 * MediaViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import Foundation
import UniformTypeIdentifiers

class MediaViewController: VLCPagingViewController<VLCLabelCell> {

    private let tabTitleMargin: CGFloat = 8.0
    private var tabTitleFont: UIFont {
        return UIFont.preferredCustomFont(forTextStyle: .headline).bolded
    }

    var mediaLibraryService: MediaLibraryService
    #if os(iOS)
    private lazy var rendererButton: UIButton = VLCAppCoordinator.sharedInstance().rendererDiscovererManager.setupRendererButton()
    #endif
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

    private lazy var selectButton: UIBarButtonItem = {
        let select = UIBarButtonItem(image: UIImage(systemName: "checkmark.circle"),
                                     style: .plain, target: self,
                                     action: #selector(customSetEditing))
        select.title = NSLocalizedString("BUTTON_SELECT", comment: "")
        select.accessibilityHint = NSLocalizedString("BUTTON_SELECT_HINT", comment: "")
        select.accessibilityIdentifier = VLCAccessibilityIdentifier.select
        return select
    }()

    private lazy var addExternalFolderButton: UIBarButtonItem = {
        let addExternalFolder = UIBarButtonItem(image: UIImage(systemName: "folder.badge.plus"),
                                                style: .plain, target: self,
                                                action: #selector(handleAddExternalFolder))
        addExternalFolder.title = NSLocalizedString("ADD_EXTERNAL_FOLDER", comment: "")
        return addExternalFolder
    }()

    private lazy var overflowMenuButton: UIBarButtonItem = {
        let overflowMenuButton = UIBarButtonItem(image: UIImage(named: "EllipseCircle"), menu: nil)
        overflowMenuButton.accessibilityLabel = NSLocalizedString("BUTTON_MENU", comment: "")
        return overflowMenuButton
    }()

    private lazy var doneButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(customSetEditing))
    }()

    private lazy var appMenuButton: UIBarButtonItem = {
        return AppMenuBarButtonItem(presenter: self)
    }()

    private var rightBarButtons: [UIBarButtonItem]?
    private var leftBarButtons: [UIBarButtonItem]?

    init(mediaLibraryService: MediaLibraryService) {
        self.mediaLibraryService = mediaLibraryService
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

        viewControllers.forEach {
            ($0 as? MediaCategoryViewController)?.delegate = self
        }
        setupNavigationBar()
#if os(iOS)
        NotificationCenter.default.addObserver(self, selector: #selector(renderersDidChange),
                                               name: .VLCRenderersDidChangeNotification, object: nil)
#endif
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass
                || traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass,
              !viewControllers.isEmpty else {
            return
        }

        updateButtonsFor(viewControllers[currentIndex])
    }

#if os(iOS)
    @objc private func renderersDidChange() {
        guard !viewControllers.isEmpty else {
            return
        }
        updateButtonsFor(viewControllers[currentIndex])
    }
#endif

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        if #unavailable(iOS 26.0) {
            navigationController?.navigationBar.standardAppearance = AppearanceManager.navigationbarAppearance()
            navigationController?.navigationBar.scrollEdgeAppearance = AppearanceManager.navigationbarAppearance()
            navigationController?.navigationBar.isTranslucent = false
        }
        #if os(iOS)
        setNeedsStatusBarAppearanceUpdate()
        #endif
        updateButtonsFor(viewControllers[currentIndex])
    }

    @objc private func updateTheme() {
        if containerView != nil {
            containerView.backgroundColor = PresentationTheme.current.colors.background
        }
    }

    func scrollToTop() {
        guard let collectionView = (viewControllers[currentIndex] as? UICollectionViewController)?.collectionView else {
            return
        }
        collectionView.setContentOffset(CGPoint(x: 0, y: -collectionView.adjustedContentInset.top), animated: true)
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

        leftBarButtons = isEditing ? [selectAllButton] : nil
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

        var emptyStateRightBarButtons: [UIBarButtonItem] = []
        if navigationController?.viewControllers.last is PlaylistViewController,
           let viewController = viewControllers[currentIndex] as? PlaylistCategoryViewController,
           !isEditing {
            let createPlaylistButton = viewController.getCreatePlaylistButton()
            rightBarButtons?.append(createPlaylistButton)
            emptyStateRightBarButtons = [createPlaylistButton]
        }

        if !isEditing, offersExternalFolders(on: viewController) {
            emptyStateRightBarButtons.insert(addExternalFolderButton, at: 0)
        }

        if !isEditing, let historyCategoryViewController = viewController as? HistoryCategoryViewController {
            emptyStateRightBarButtons.append(historyCategoryViewController.sortBarButtonItem())
        }

        if !isEditing, navigationController?.viewControllers.count == 1 {
            var items: [UIBarButtonItem] = [appMenuButton]
            if showButtons, let leftBarButtons = leftBarButtons {
                items.append(contentsOf: leftBarButtons)
            }
            mediaCategoryViewController.navigationItem.leftBarButtonItems = items
        } else {
            mediaCategoryViewController.navigationItem.leftBarButtonItems = showButtons ? leftBarButtons : nil
        }
        mediaCategoryViewController.navigationItem.rightBarButtonItems = showButtons ? rightBarButtons : emptyStateRightBarButtons
        if #available(iOS 16.0, *) {
            mediaCategoryViewController.navigationItem.additionalOverflowItems = showButtons && !isEditing ? overflowMenu(for: viewController) : nil
        }

        if #available(iOS 26.0, visionOS 26.0, *), let page = viewController as? MediaCategoryViewController {
            let showSearch = (showButtons || page.isSearchActive) && !isEditing
            mediaCategoryViewController.navigationItem.preferredSearchBarPlacement = .integrated
            mediaCategoryViewController.navigationItem.searchController = showSearch ? page.searchController : nil
        }
    }

    private func rightBarButtonItems(for viewController: UIViewController) -> [UIBarButtonItem] {
        var rightBarButtonItems: [UIBarButtonItem] = []

        if let mediaCategoryViewController = viewController as? MediaCategoryViewController {
            rightBarButtonItems.append(mediaCategoryViewController.sortBarButtonItem())
        }

        let showsOverflowMenu = showsOverflowMenu(for: viewController)

        if offersExternalFolders(on: viewController), !showsOverflowMenu {
            rightBarButtonItems.append(addExternalFolderButton)
        }

        if let historyCategoryViewController = viewController as? HistoryCategoryViewController {
            rightBarButtonItems.append(historyCategoryViewController.clearHistoryButton)
        } else if !showsOverflowMenu {
            rightBarButtonItems.append(selectButton)
        }

        if #unavailable(iOS 16.0) {
            let overflowMenuElements = overflowMenuElements(for: viewController)
            if !overflowMenuElements.isEmpty {
                overflowMenuButton.menu = UIMenu(children: overflowMenuElements)
                rightBarButtonItems.insert(overflowMenuButton, at: 0)
            }
        }

#if os(iOS)
        if !rendererButton.isHidden {
            rightBarButtonItems.append(UIBarButtonItem(customView: rendererButton))
        }
#endif

        return rightBarButtonItems
    }

    private func offersExternalFolders(on viewController: UIViewController) -> Bool {
        return (self is VideoViewController || self is AudioViewController || self is FoldersViewController)
            && viewControllers.contains(viewController)
    }

    private func showsOverflowMenu(for viewController: UIViewController) -> Bool {
        return traitCollection.horizontalSizeClass == .compact
            && traitCollection.verticalSizeClass == .regular
            && viewControllers.contains(viewController)
    }

    @available(iOS 16.0, *)
    private func overflowMenu(for viewController: UIViewController) -> UIDeferredMenuElement? {
        let elements = overflowMenuElements(for: viewController)
        guard !elements.isEmpty else {
            return nil
        }

        return UIDeferredMenuElement { completion in
            completion(elements)
        }
    }

    private func overflowMenuElements(for viewController: UIViewController) -> [UIMenuElement] {
        guard showsOverflowMenu(for: viewController) else {
            return []
        }

        var actions: [UIMenuElement] = []

        if !(viewController is HistoryCategoryViewController) {
            let selectAction = UIAction(title: selectButton.title ?? "", image: selectButton.image) { [weak self] _ in
                self?.customSetEditing()
            }
            selectAction.accessibilityIdentifier = VLCAccessibilityIdentifier.select
            actions.append(selectAction)
        }

        if offersExternalFolders(on: viewController) {
            actions.append(UIAction(title: addExternalFolderButton.title ?? "", image: addExternalFolderButton.image) { [weak self] _ in
                self?.handleAddExternalFolder()
            })
        }

        return actions
    }

    override func configure(cell: VLCLabelCell, for indicatorInfo: IndicatorInfo) {
        cell.iconLabel.adjustsFontSizeToFitWidth = true
        cell.iconLabel.text = indicatorInfo.title
        cell.iconLabel.font = tabTitleFont
        cell.iconLabel.accessibilityIdentifier = indicatorInfo.accessibilityIdentifier
    }

    override func minimumCellWidth(for indicatorInfo: IndicatorInfo?) -> CGFloat {
        let defaultWidth: CGFloat = super.minimumCellWidth(for: indicatorInfo)

        guard let title = indicatorInfo?.title else {
            return defaultWidth
        }

        let titleWidth = (title as NSString).size(withAttributes: [.font: tabTitleFont]).width
        return max(defaultWidth, ceil(titleWidth) + 2 * tabTitleMargin)
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
        rightBarButtons = isEditing ? [doneButton] : [viewController.sortBarButtonItem(), selectButton]

#if os(iOS)
        if !rendererButton.isHidden {
            rightBarButtons?.append(UIBarButtonItem(customView: rendererButton))
        }
#endif

        if navigationController?.viewControllers.last is PlaylistViewController,
           let playlistCategoryViewController = viewControllers[currentIndex] as? PlaylistCategoryViewController,
           !isEditing {
            rightBarButtons?.append(playlistCategoryViewController.getCreatePlaylistButton())
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
        var rightButtons: [UIBarButtonItem] = rightBarButtonItems(for: viewControllers[currentIndex])

        if let mediaCategoryViewController = viewControllers[currentIndex] as? MediaCategoryViewController,
            mediaCategoryViewController.model is MediaGroupViewModel {
            leftBarButtons = isEditing ? [regroupButton, selectAllButton] : nil
        } else {
            leftBarButtons = isEditing ? [selectAllButton] : nil
        }

        // Check if the playAllButton should be displayed
        if navigationController?.viewControllers.last is ArtistViewController,
           let viewController = viewControllers[currentIndex] as? CollectionCategoryViewController {
            let playAllButton = viewController.getPlayAllButton()
            rightButtons.append(playAllButton)
        }

        if navigationController?.viewControllers.last is PlaylistViewController,
           let viewController = viewControllers[currentIndex] as? PlaylistCategoryViewController {
            rightButtons.append(viewController.getCreatePlaylistButton())
        }

        rightBarButtons = isEditing ? [doneButton] : rightButtons
        navigationItem.rightBarButtonItems = rightBarButtons
        navigationItem.leftBarButtonItems = leftBarButtons
        if #available(iOS 16.0, *) {
            navigationItem.additionalOverflowItems = isEditing ? nil : overflowMenu(for: viewControllers[currentIndex])
        }

        if !isEditing, navigationController?.viewControllers.count == 1 {
            var items: [UIBarButtonItem] = [appMenuButton]
            if let leftBarButtons = leftBarButtons {
                items.append(contentsOf: leftBarButtons)
            }
            navigationItem.leftBarButtonItems = items
        }

        if #available(iOS 26.0, visionOS 26.0, *),
           let page = viewControllers[currentIndex] as? MediaCategoryViewController,
           navigationController?.viewControllers.count == 1 {
            let showSearch = page.isSearchActive || !isEditing
            navigationItem.preferredSearchBarPlacement = .integrated
            navigationItem.searchController = showSearch ? page.searchController : nil
        }

        if isEditing == false {
            selectAllButton.image = UIImage(named: "emptySelectAll")
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        scrollingEnabled(!editing)

        if let controllers = navigationController?.viewControllers,
           controllers.count > 1,
           let collectionViewController = navigationController?.topCollectionCategoryViewController {
            collectionViewController.setEditing(editing, animated: animated)
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

    @objc func handleAddExternalFolder() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }

    @objc func handleSelectAll() {
        let controller: MediaCategoryViewController
        if let mediaCategoryViewController = navigationController?.topCollectionCategoryViewController {
            controller = mediaCategoryViewController
        } else if let mediaCategoryViewController = viewControllers[currentIndex] as? MediaCategoryViewController {
            controller = mediaCategoryViewController
        } else {
            preconditionFailure("MediaViewController: Invalid view controller.")
        }

        controller.handleSelectAll()
        selectAllButton.image = controller.isAllSelected ? UIImage(named: "allSelected") : UIImage(named: "emptySelectAll")
    }
}

// MARK: - UIDocumentPickerDelegate

extension MediaViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }

        let errorMessage: String
        switch mediaLibraryService.medialib.addExternalFolder(at: url) {
        case .added, .updated:
            return
        case .overlapping:
            errorMessage = NSLocalizedString("EXTERNAL_FOLDER_OVERLAPPING", comment: "")
        case .failed:
            errorMessage = NSLocalizedString("EXTERNAL_FOLDER_FAILED", comment: "")
        @unknown default:
            return
        }

        VLCAlertViewController.alertViewManager(title: NSLocalizedString("EXTERNAL_FOLDER_NOT_ADDED", comment: ""),
                                                errorMessage: errorMessage,
                                                viewController: self)
    }
}
