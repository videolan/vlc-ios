/*****************************************************************************
 * MediaCateogoryViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *          Mike JS. Choi <mkchoi212 # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

@objc protocol MediaCategoryViewControllerDelegate: NSObjectProtocol {
    func needsToUpdateNavigationbarIfNeeded(_ viewController: MediaCategoryViewController)
    func enableCategorySwitching(for viewController: MediaCategoryViewController,
                                 enable: Bool)
    func setEditingStateChanged(for viewController: MediaCategoryViewController, editing: Bool)
}

class MediaCategoryViewController: UICollectionViewController, UISearchBarDelegate, IndicatorInfoProvider {
    // MARK: - Properties
    var model: MediaLibraryBaseModel
    private var services: Services

    var searchBar = UISearchBar(frame: .zero)
    var isSearching: Bool = false
    private var searchBarConstraint: NSLayoutConstraint?
    private let searchDataSource: LibrarySearchDataSource
    private let searchBarSize: CGFloat = 50.0
    private var rendererButton: UIButton
    private lazy var editController: EditController = {
        let editController = EditController(mediaLibraryService:services.medialibraryService,
                                            model: model,
                                            presentingView: collectionView)
        editController.delegate = self
        return editController
    }()

    private var cachedCellSize = CGSize.zero
    private var toSize = CGSize.zero
    private var longPressGesture: UILongPressGestureRecognizer!
    weak var delegate: MediaCategoryViewControllerDelegate?

//    @available(iOS 11.0, *)
//    lazy var dragAndDropManager: VLCDragAndDropManager = { () -> VLCDragAndDropManager<T> in
//        VLCDragAndDropManager<T>(subcategory: VLCMediaSubcategories<>)
//    }()

    @objc private lazy var sortActionSheet: ActionSheet = {
        let header = ActionSheetSortSectionHeader(model: model.sortModel)
        let actionSheet = ActionSheet(header: header)
        header.delegate = self
        actionSheet.delegate = self
        actionSheet.dataSource = self
        actionSheet.modalPresentationStyle = .custom
        actionSheet.setAction { [weak self] item in
            guard let sortingCriteria = item as? VLCMLSortingCriteria else {
                return
            }
            self?.model.sort(by: sortingCriteria, desc: header.actionSwitch.isOn)
            self?.sortActionSheet.removeActionSheet()
        }
        return actionSheet
    }()

    private lazy var sortBarButton: UIBarButtonItem = {
        return UIBarButtonItem(customView: setupSortButton())
    }()

    private lazy var editBarButton: UIBarButtonItem = {
        return setupEditBarButton()
    }()

    private lazy var rendererBarButton: UIBarButtonItem = {
        return UIBarButtonItem(customView: rendererButton)
    }()

    private lazy var emptyView: VLCEmptyLibraryView = {
        let name = String(describing: VLCEmptyLibraryView.self)
        let nib = Bundle.main.loadNibNamed(name, owner: self, options: nil)
        guard let emptyView = nib?.first as? VLCEmptyLibraryView else { fatalError("Can't find nib for \(name)") }

        // Check if it is inside a playlist
        if let collectionModel = model as? CollectionModel,
            collectionModel.mediaCollection is VLCMLPlaylist {
            emptyView.contentType = .playlist
        }

        return emptyView
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    // MARK: - Initializers

    @available(*, unavailable)
    init() {
        fatalError()
    }

    init(services: Services, model: MediaLibraryBaseModel) {
        self.services = services
        self.model = model
        self.rendererButton = services.rendererDiscovererManager.setupRendererButton()
        self.searchDataSource = LibrarySearchDataSource(model: model)

        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        if let collection = model as? CollectionModel {
            title = collection.mediaCollection.title()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification, object: nil)
    }

    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = NSLocalizedString("SEARCH", comment: "")
        searchBar.backgroundColor = PresentationTheme.current.colors.background
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        if let textfield = searchBar.value(forKey: "searchField") as? UITextField {
            if let backgroundview = textfield.subviews.first {
                backgroundview.backgroundColor = UIColor.white
                backgroundview.layer.cornerRadius = 10
                backgroundview.clipsToBounds = true
            }
        }

        searchBarConstraint = searchBar.topAnchor.constraint(equalTo: view.topAnchor, constant: -searchBarSize)
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBarConstraint!,
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            searchBar.heightAnchor.constraint(equalToConstant: searchBarSize)
        ])
    }

    @objc func reloadData() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.reloadData()
            }
            return
        }
        delegate?.needsToUpdateNavigationbarIfNeeded(self)
        collectionView?.reloadData()
        updateUIForContent()

        if !isSearching {
            popViewIfNecessary()
        }

        if isEditing {
            if let editToolbar = tabBarController?.editToolBar() {
                editToolbar.updateEditToolbar(for: model)
            }
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder: ) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSearchBar()
        _ = (MLMediaLibrary.sharedMediaLibrary() as! MLMediaLibrary).libraryDidAppear()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let manager = services.rendererDiscovererManager
        if manager.discoverers.isEmpty {
            // Either didn't start or stopped before
            manager.start()
        }

        PlaybackService.sharedInstance().setPlayerHidden(isEditing)

        manager.presentingViewController = self
        cachedCellSize = .zero
        collectionView.collectionViewLayout.invalidateLayout()
        updateVideoGroups()
        reloadData()
    }

    @objc func themeDidChange() {
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
        searchBar.backgroundColor = PresentationTheme.current.colors.background

        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance = AppearanceManager.navigationbarAppearance()
            navigationController?.navigationBar.scrollEdgeAppearance = AppearanceManager.navigationbarAppearance()
        }
        setNeedsStatusBarAppearanceUpdate()
    }

    // MARK: - Renderer

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        cachedCellSize = .zero
        toSize = size
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Edit

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // This ensures that the search bar is always visible like a sticky while searching
        if isSearching {
            searchBar.endEditing(true)
            delegate?.enableCategorySwitching(for: self, enable: true)
            // End search if scrolled and the textfield is empty
            if let searchBarText = searchBar.text, searchBarText.isEmpty {
                searchBarCancelButtonClicked(searchBar)
            }
            return
        }

        searchBarConstraint?.constant = -min(scrollView.contentOffset.y, searchBarSize) - searchBarSize
        if scrollView.contentOffset.y < -searchBarSize && scrollView.contentInset.top != searchBarSize {
            collectionView.contentInset = UIEdgeInsets(top: searchBarSize, left: 0, bottom: 0, right: 0)
        }
        if scrollView.contentOffset.y >= 0 && scrollView.contentInset.top != 0 {
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        guard editing != isEditing else {
            // Guard in case where setEditing is called twice with the same state
            return
        }
        super.setEditing(editing, animated: animated)
        // might have an issue if the old datasource was search
        // Most of the edit logic is handled inside editController
        collectionView?.dataSource = editing ? editController : self
        collectionView?.delegate = editing ? editController : self

        editController.resetSelections(resetUI: true)
        displayEditToolbar()

        PlaybackService.sharedInstance().setPlayerHidden(editing)

        searchBar.resignFirstResponder()
        searchBarConstraint?.constant = -self.searchBarSize
        reloadData()
    }

    private func displayEditToolbar() {
        if isEditing {
            tabBarController?.editToolBar()?.delegate = editController
            tabBarController?.displayEditToolbar(with: model)
            UIView.animate(withDuration: 0.2) {
                [weak self] in
                self?.collectionView.contentInset = .zero
            }
        } else {
            tabBarController?.hideEditToolbar()
        }
    }

    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        let uiTestAccessibilityIdentifier = model is TrackModel ? VLCAccessibilityIdentifier.songs : nil
        return IndicatorInfo(title: model.indicatorName, accessibilityIdentifier: uiTestAccessibilityIdentifier)
    }
}

// MARK: - MediaCategoryViewController - Private Helpers

private extension MediaCategoryViewController {
    private func popViewIfNecessary() {
        // Inside a collection without files
        if let collectionModel = model as? CollectionModel, collectionModel.anyfiles.isEmpty {
            // Pop view if collection is not a playlist since a playlist is user created
            if !(collectionModel.mediaCollection is VLCMLPlaylist) {
                navigationController?.popViewController(animated: true)
            }
        }
    }

    private func updateVideoGroups() {
        // Manually update video groups since there is no callbacks for it
        if let videoGroupViewModel = model as? VideoGroupViewModel {
            videoGroupViewModel.updateVideoGroups()
        }
    }

    private func isEmptyCollectionView() -> Bool {
        return collectionView?.numberOfItems(inSection: 0) == 0
    }

    private func updateUIForContent() {
        if isSearching {
            return
        }

        let isEmpty = isEmptyCollectionView()
        if isEmpty {
            collectionView?.setContentOffset(.zero, animated: false)
        }
        searchBar.isHidden = isEmpty || isEditing
        collectionView?.backgroundView = isEmpty ? emptyView : nil
    }

    private func objects(from modelContent: VLCMLObject) -> [VLCMLObject] {
        if let media = modelContent as? VLCMLMedia {
            return [media]
        } else if let mediaCollection = modelContent as? MediaCollectionModel {
            return mediaCollection.files() ?? [VLCMLObject]()
        }
        return [VLCMLObject]()
    }

    private func createSpotlightItem(media: VLCMLMedia) {
        if KeychainCoordinator.passcodeLockEnabled {
            return
        }
        userActivity = NSUserActivity(activityType: kVLCUserActivityPlaying)
        userActivity?.title = media.title
        userActivity?.contentAttributeSet = media.coreSpotlightAttributeSet()
        userActivity?.userInfo = ["playingmedia" : media.identifier()]
        userActivity?.isEligibleForSearch = true
        userActivity?.isEligibleForHandoff = true
        userActivity?.becomeCurrent()
    }
}

// MARK: - NavigationItem

extension MediaCategoryViewController {
    private func setupEditBarButton() -> UIBarButtonItem {
        let editButton = UIBarButtonItem(image: UIImage(named: "edit"),
                                         style: .plain, target: self,
                                         action: #selector(handleEditing))
        editButton.tintColor = PresentationTheme.current.colors.orangeUI
        editButton.accessibilityLabel = NSLocalizedString("BUTTON_EDIT", comment: "")
        editButton.accessibilityHint = NSLocalizedString("BUTTON_EDIT_HINT", comment: "")
        return editButton
    }

    private func setupSortButton() -> UIButton {
        // Fetch sortButton configuration from MediaVC
        let sortButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        sortButton.setImage(UIImage(named: "sort"), for: .normal)
        sortButton.addTarget(self,
                             action: #selector(handleSort),
                             for: .touchUpInside)
        sortButton
            .addGestureRecognizer(UILongPressGestureRecognizer(target: self,
                                                               action: #selector(handleSortLongPress(sender:))))

        sortButton.tintColor = PresentationTheme.current.colors.orangeUI
        sortButton.accessibilityLabel = NSLocalizedString("BUTTON_SORT", comment: "")
        sortButton.accessibilityHint = NSLocalizedString("BUTTON_SORT_HINT", comment: "")
        return sortButton
    }

    private func rightBarButtonItems() -> [UIBarButtonItem] {
        var rightBarButtonItems = [UIBarButtonItem]()

        rightBarButtonItems.append(editBarButton)
        // Sort is not available for Playlists
        if let model = model as? CollectionModel, !(model.mediaCollection is VLCMLPlaylist) {
            rightBarButtonItems.append(sortBarButton)
        }
        rightBarButtonItems.append(rendererBarButton)
        return rightBarButtonItems
    }

    @objc func handleSort() {
        var currentSortIndex: Int = 0
        for (index, criteria) in
            model.sortModel.sortingCriteria.enumerated()
            where criteria == model.sortModel.currentSort {
                currentSortIndex = index
                break
        }
        present(sortActionSheet, animated: false) {
            [sortActionSheet, currentSortIndex] in
            sortActionSheet.collectionView.selectItem(at:
                IndexPath(row: currentSortIndex, section: 0), animated: false,
                                                              scrollPosition: .centeredVertically)
        }
    }

    @objc func handleSortLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            if #available(iOS 10.0, *) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            handleSortShortcut()
        }
    }

    @objc func handleSortShortcut() {
        model.sort(by: model.sortModel.currentSort, desc: !model.sortModel.desc)
    }

    @objc func handleEditing() {
        isEditing = !isEditing
        navigationItem.rightBarButtonItems = isEditing ? [UIBarButtonItem(barButtonSystemItem: .done,
                                                                          target: self,
                                                                          action: #selector(handleEditing))]
            : rightBarButtonItems()
        navigationItem.setHidesBackButton(isEditing, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension MediaCategoryViewController {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        reloadData()
        isSearching = true
        delegate?.enableCategorySwitching(for: self, enable: false)
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        // Empty the text field and reset the research
        searchBar.text = ""
        searchDataSource.shouldReloadFor(searchString: "")
        searchBar.setShowsCancelButton(false, animated: true)
        isSearching = false
        delegate?.enableCategorySwitching(for: self, enable: true)
        reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        delegate?.enableCategorySwitching(for: self, enable: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchDataSource.shouldReloadFor(searchString: searchText)
        reloadData()
        if searchText.isEmpty {
            self.searchBar.resignFirstResponder()
        }
    }
}

// MARK: - UICollectionViewDelegate - Private Helpers

private extension MediaCategoryViewController {
    @available(iOS 13.0, *)
    private func generateUIMenuForContent(at indexPath: IndexPath) -> UIMenu {
        let modelContentArray = isSearching ? searchDataSource.searchData : model.anyfiles
        let index = indexPath.row
        let modelContent = modelContentArray.objectAtIndex(index: index)

        let actionList = EditButtonsFactory.buttonList(for: model.anyfiles.first)
        let actions = EditButtonsFactory.generate(buttons: actionList)

        return UIMenu(title: "", image: nil, identifier: nil, children: actions.map {
            switch $0.identifier {
            case .addToPlaylist:
                return $0.action({
                    [weak self] _ in
                    if let modelContent = modelContent {
                        self?.editController.editActions.objects = self?.objects(from: modelContent) ?? []
                        self?.editController.editActions.addToPlaylist()
                    }
                })
            case .rename:
                return $0.action({
                    [weak self] _ in
                    if let modelContent = modelContent {
                        self?.editController.editActions.objects = [modelContent]
                        self?.editController.editActions.rename()
                    }
                })
            case .delete:
                return $0.action({
                    [weak self] _ in
                    if let modelContent = modelContent {
                        self?.editController.editActions.objects = [modelContent]
                        self?.editController.editActions.delete()
                    }
                })
            case .share:
                return $0.action({
                    [weak self] _ in
                    if let modelContent = modelContent {
                        self?.editController.editActions.objects = self?.objects(from: modelContent) ?? []
                        if let cell = self?.collectionView.cellForItem(at: indexPath) {
                            self?.editController.editActions.share(origin: cell)
                        }
                    }
                })
            }
        })
    }
}

// MARK: - UICollectionViewDelegate

extension MediaCategoryViewController {
    private func selectedItem(at indexPath: IndexPath) {
        let mediaObjectArray = isSearching ? searchDataSource.searchData : model.anyfiles
        let modelContent = mediaObjectArray.objectAtIndex(index: indexPath.row)

        if let media = modelContent as? VLCMLMedia {
            play(media: media, at: indexPath)
            createSpotlightItem(media: media)
        } else if let mediaCollection = modelContent as? MediaCollectionModel {
            let collectionViewController = CollectionCategoryViewController(services,
                                                                            mediaCollection: mediaCollection)

            collectionViewController.navigationItem.rightBarButtonItems = collectionViewController.rightBarButtonItems()

            navigationController?.pushViewController(collectionViewController, animated: true)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedItem(at: indexPath)
    }

    @available(iOS 13.0, *)
    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
                                 point: CGPoint) -> UIContextMenuConfiguration? {
        let modelContent = self.isSearching ? self.searchDataSource.searchData.objectAtIndex(index: indexPath.row) : self.model.anyfiles[indexPath.row]
        let cell = collectionView.cellForItem(at: indexPath)
        var thumbnail: UIImage? = nil
        if let cell = cell as? MovieCollectionViewCell {
            thumbnail = cell.thumbnailView.image
        } else if let cell = cell as? MediaCollectionViewCell {
            thumbnail = cell.thumbnailView.image
        }
        let configuration = UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: {
            guard let thumbnail = thumbnail else {
                return nil
            }
            return CollectionViewCellPreviewController(thumbnail: thumbnail, with: modelContent)
        }, actionProvider: {
            [weak self] action in
            return self?.generateUIMenuForContent(at: indexPath)
        })
        return configuration
    }

    @available(iOS 13.0, *)
    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        if let indexPath = configuration.identifier as? IndexPath {
            if let cell = collectionView.cellForItem(at: indexPath) as? BaseCollectionViewCell {
                if !(cell.media is VLCMLMedia) {
                    self.selectedItem(at: indexPath)
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension MediaCategoryViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearching ? searchDataSource.searchData.count : model.anyfiles.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier:model.cellType.defaultReuseIdentifier, for: indexPath) as? BaseCollectionViewCell else {
            assertionFailure("you forgot to register the cell or the cell is not a subclass of BaseCollectionViewCell")
            return UICollectionViewCell()
        }

        let mediaObjectArray = isSearching ? searchDataSource.searchData : model.anyfiles
        let mediaObject = mediaObjectArray.objectAtIndex(index: indexPath.row)

        guard mediaObject != nil else {
            assertionFailure("MediaCategoryViewController: Failed to fetch media object.")
            return mediaCell
        }

        if let media = mediaObject as? VLCMLMedia {
            // FIXME: This should be done in the VModel, workaround for the release.
            if media.type() == .video {
                services.medialibraryService.requestThumbnail(for: media)
            }
            assert(media.mainFile() != nil, "The mainfile is nil")
            mediaCell.media = media.mainFile() != nil ? media : nil
        } else {
            mediaCell.media = mediaObject
        }
        mediaCell.isAccessibilityElement = true
        return mediaCell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MediaCategoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if cachedCellSize == .zero {
            //For iOS 10 when rotating we take the value from willTransition to size, for the first layout pass that value is 0 though,
            //so we need the frame.size width. For rotation on iOS 11 this approach doesn't work because at the time when this is called
            //we don't have yet the updated safeare layout frame. This is addressed by relayouting from viewSafeAreaInsetsDidChange
            var toWidth = toSize.width != 0 ? toSize.width : collectionView.frame.size.width
            if #available(iOS 11.0, *) {
                toWidth = collectionView.safeAreaLayoutGuide.layoutFrame.width
            }
            cachedCellSize = model.cellType.cellSizeForWidth(toWidth)
        }
        return cachedCellSize
    }

    override func viewSafeAreaInsetsDidChange() {
        cachedCellSize = .zero
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: model.cellType.edgePadding, left: model.cellType.edgePadding, bottom: model.cellType.edgePadding, right: model.cellType.edgePadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return model.cellType.edgePadding
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return model.cellType.interItemPadding
    }
}

// MARK: - VLCActionSheetDelegate

extension MediaCategoryViewController: ActionSheetDelegate {
    func headerViewTitle() -> String? {
        return NSLocalizedString("HEADER_TITLE_SORT", comment: "")
    }

    // This provide the item to send to the selection action
    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        let enabledSortCriteria = model.sortModel.sortingCriteria

        if indexPath.row < enabledSortCriteria.count {
            return enabledSortCriteria[indexPath.row]
        }
        assertionFailure("VLCMediaCategoryViewController: VLCActionSheetDelegate: IndexPath out of range")
        return nil
    }
}

// MARK: - VLCActionSheetDataSource

extension MediaCategoryViewController: ActionSheetDataSource {
    func numberOfRows() -> Int {
        return model.sortModel.sortingCriteria.count
    }

    func actionSheet(collectionView: UICollectionView,
                     cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ActionSheetCell.identifier,
            for: indexPath) as? ActionSheetCell else {
                assertionFailure("VLCMediaCategoryViewController: VLCActionSheetDataSource: Unable to dequeue reusable cell")
                return UICollectionViewCell()
        }

        let sortingCriterias = model.sortModel.sortingCriteria

        guard indexPath.row < sortingCriterias.count else {
            assertionFailure("VLCMediaCategoryViewController: VLCActionSheetDataSource: IndexPath out of range")
            return cell
        }

        cell.name.text = String(describing: sortingCriterias[indexPath.row])
        return cell
    }
}

// MARK: - ActionSheetSortSectionHeaderDelegate

extension MediaCategoryViewController: ActionSheetSortSectionHeaderDelegate {
    func actionSheetSortSectionHeader(_ header: ActionSheetSortSectionHeader,
                                      onSwitchIsOnChange: Bool) {
        model.sort(by: model.sortModel.currentSort, desc: onSwitchIsOnChange)
    }
}

// MARK: - EditControllerDelegate

extension MediaCategoryViewController: EditControllerDelegate {
    func editController(editController: EditController, cellforItemAt indexPath: IndexPath) -> BaseCollectionViewCell? {
        return collectionView.cellForItem(at: indexPath) as? BaseCollectionViewCell
    }

    func editController(editController: EditController,
                        present viewController: UIViewController) {
        let newNavigationController = UINavigationController(rootViewController: viewController)
        navigationController?.present(newNavigationController, animated: true, completion: nil)
    }

    func editControllerDidFinishEditing(editController: EditController?) {
        // NavigationItems for Collections are create from the parent, there is no need to propagate the information.
        if self is CollectionCategoryViewController {
            handleEditing()
        } else {
            delegate?.setEditingStateChanged(for: self, editing: false)
        }
    }
}

private extension MediaCategoryViewController {
    func setupCollectionView() {
        let cellNib = UINib(nibName: model.cellType.nibName, bundle: nil)
        collectionView?.register(cellNib, forCellWithReuseIdentifier: model.cellType.defaultReuseIdentifier)
        collectionView.allowsMultipleSelection = true
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
        collectionView?.alwaysBounceVertical = true
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(gesture:)))
        longPressGesture.minimumPressDuration = 0.2
        collectionView?.addGestureRecognizer(longPressGesture)
        if #available(iOS 11.0, *) {
            collectionView?.contentInsetAdjustmentBehavior = .always
            //            collectionView?.dragDelegate = dragAndDropManager
            //            collectionView?.dropDelegate = dragAndDropManager
        }
    }

    func constrainOnX(_ location: CGPoint, for width: CGFloat) -> CGPoint {
        var constrainedLocation = location
        if model.cellType.numberOfColumns(for: width) == 1 {
            constrainedLocation.x = width / 2
        }
        return constrainedLocation
    }

    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                break
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            let location = constrainOnX(gesture.location(in: gesture.view!),
                                        for: collectionView.frame.width)
            collectionView.updateInteractiveMovementTargetPosition(location)
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
}

// MARK: - Player

extension MediaCategoryViewController {

    func play(media: VLCMLMedia, at indexPath: IndexPath) {
        let playbackController = PlaybackService.sharedInstance()
        let autoPlayNextItem = UserDefaults.standard.bool(forKey: kVLCAutomaticallyPlayNextItem)

        playbackController.fullscreenSessionRequested = media.type() != .audio
        if !autoPlayNextItem {
            playbackController.play(media)
            return
        }

        var tracks = [VLCMLMedia]()

        if let model = model as? MediaCollectionModel {
            tracks = model.files() ?? []
        } else {
            tracks = (isSearching ? searchDataSource.searchData : model.anyfiles) as? [VLCMLMedia] ?? []
        }
        playbackController.playMedia(at: indexPath.row, fromCollection: tracks)
    }
}
