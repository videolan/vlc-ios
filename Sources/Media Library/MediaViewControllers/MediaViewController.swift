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

    // MARK: UIMenu & UIActions

    private lazy var menuButton: UIBarButtonItem = {
        var buttonItem = UIBarButtonItem()
        if #available(iOS 26.0, *) {
            buttonItem.image = UIImage(systemName: "ellipsis")
        } else {
            buttonItem.image = UIImage(named: "EllipseCircle")
        }
        buttonItem.accessibilityLabel = NSLocalizedString("BUTTON_MENU", comment: "")
        buttonItem.accessibilityHint = NSLocalizedString("BUTTON_MENU_HINT", comment: "")
        buttonItem.accessibilityIdentifier = VLCAccessibilityIdentifier.mediaMenu
        return buttonItem
    }()

    private lazy var addExternalFolderButton: UIBarButtonItem = {
        let addExternalFolder = UIBarButtonItem(image: UIImage(systemName: "folder.badge.plus"),
                                                style: .plain, target: self,
                                                action: #selector(handleAddExternalFolder))
        addExternalFolder.title = NSLocalizedString("ADD_EXTERNAL_FOLDER", comment: "")
        return addExternalFolder
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
        rightBarButtons = [menuButton]

#if os(iOS)
        if !rendererButton.isHidden {
            rightBarButtons?.append(UIBarButtonItem(customView: rendererButton))
        }
#endif

        viewControllers.forEach {
            ($0 as? MediaCategoryViewController)?.delegate = self
        }
        setupNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if menuButton.menu == nil,
           let viewController = viewControllers[currentIndex] as? MediaCategoryViewController {
            menuButton.menu = generateMenu(viewController: viewController)
        }
    }

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

        if let viewController = viewController as? MediaCategoryViewController {
            menuButton.menu = view.window != nil ? generateMenu(viewController: viewController) : nil
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

        if #available(iOS 26.0, visionOS 26.0, *), let page = viewController as? MediaCategoryViewController {
            let showSearch = (showButtons || page.isSearchActive) && !isEditing
            mediaCategoryViewController.navigationItem.preferredSearchBarPlacement = .integrated
            mediaCategoryViewController.navigationItem.searchController = showSearch ? page.searchController : nil
        }
    }

    private func rightBarButtonItems(for viewController: UIViewController) -> [UIBarButtonItem] {
        var rightBarButtonItems: [UIBarButtonItem] = [menuButton]

        if let mediaCategoryViewController = viewController as? MediaCategoryViewController {
            rightBarButtonItems.append(mediaCategoryViewController.sortBarButtonItem())
        }

        if offersExternalFolders(on: viewController) {
            rightBarButtonItems.append(addExternalFolderButton)
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
        rightBarButtons = isEditing ? [doneButton] : [menuButton, viewController.sortBarButtonItem()]

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
    
    @objc func handleHistory() {
        let mediaType: VLCMLMediaType = viewControllers[currentIndex] is MovieCategoryViewController ? .video : .audio
        let historyView = HistoryCategoryViewController(mediaLibraryService, mediaType: mediaType)
        navigationController?.pushViewController(historyView, animated: true)
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

// MARK: - UIMenu

extension MediaViewController {
    func generateSelectAction() -> UIAction {
        let selectAction = UIAction(title: NSLocalizedString("BUTTON_SELECT", comment: ""),
                                    image: UIImage(systemName: "checkmark.circle"),
                                    handler: {
            [unowned self] _ in
            customSetEditing()
        })
        selectAction.accessibilityLabel = NSLocalizedString("BUTTON_SELECT", comment: "")
        selectAction.accessibilityHint = NSLocalizedString("BUTTON_SELECT_HINT", comment: "")
        selectAction.accessibilityIdentifier = VLCAccessibilityIdentifier.select
        return selectAction
    }

    func generateHistoryMenu() -> UIMenu {
        let historyAction = UIAction(title: NSLocalizedString("BUTTON_HISTORY", comment: ""),
                                     image: UIImage(systemName: "clock.arrow.2.circlepath")) { [weak self] _ in
            self?.handleHistory()
        }

        historyAction.accessibilityLabel = NSLocalizedString("BUTTON_HISTORY", comment: "")
        historyAction.accessibilityHint = NSLocalizedString("BUTTON_HISTORY_HINT", comment: "")

        return UIMenu(options: .displayInline, children: [historyAction])
    }

    func generateMenu(viewController: MediaCategoryViewController?) -> UIMenu {
        guard viewController != nil else {
            preconditionFailure("MediaViewControllers: invalid viewController")
        }

        let selectAction = generateSelectAction()

        var rightMenuItems: [UIMenuElement] = [selectAction]

        if let parentViewController = viewController?.parent,
           parentViewController is VideoViewController || parentViewController is AudioViewController {
            let historyMenu = generateHistoryMenu()
            rightMenuItems.append(historyMenu)
        }

        return UIMenu(options: .displayInline, children: rightMenuItems)
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
