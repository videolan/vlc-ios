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

protocol MediaCategoryViewControllerDelegate: NSObjectProtocol {
    func needsToUpdateNavigationbarIfNeeded(_ viewController: MediaCategoryViewController)
    func enableCategorySwitching(for viewController: MediaCategoryViewController,
                               enable: Bool)
}

class MediaCategoryViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, IndicatorInfoProvider {

    var model: MediaLibraryBaseModel
    private var services: Services

    var searchBar = UISearchBar(frame: .zero)
    var isSearching: Bool = false
    private var searchBarConstraint: NSLayoutConstraint?
    private let searchDataSource: LibrarySearchDataSource
    private let searchBarSize: CGFloat = 50.0
    private var rendererButton: UIButton
    private lazy var editController: EditController = {
        let editController = EditController(mediaLibraryService:services.medialibraryService, model: model)
        editController.delegate = self
        return editController
    }()

    private var editToolbarConstraint: NSLayoutConstraint?
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


    lazy var emptyView: VLCEmptyLibraryView = {
        let name = String(describing: VLCEmptyLibraryView.self)
        let nib = Bundle.main.loadNibNamed(name, owner: self, options: nil)
        guard let emptyView = nib?.first as? VLCEmptyLibraryView else { fatalError("Can't find nib for \(name)") }
        return emptyView
    }()

    let editCollectionViewLayout: UICollectionViewFlowLayout = {
        let editCollectionViewLayout = UICollectionViewFlowLayout()
        editCollectionViewLayout.minimumLineSpacing = 1
        editCollectionViewLayout.minimumInteritemSpacing = 0
        return editCollectionViewLayout
    }()

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
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
        navigationItem.rightBarButtonItems = [editButtonItem, UIBarButtonItem(customView: rendererButton)]
    }

    func setupSearchBar() {
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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    @objc func reloadData() {
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.needsToUpdateNavigationbarIfNeeded(self)
            self.collectionView?.reloadData()
            self.updateUIForContent()
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
        setupEditToolbar()
        _ = (MLMediaLibrary.sharedMediaLibrary() as! MLMediaLibrary).libraryDidAppear()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let manager = services.rendererDiscovererManager
        if manager.discoverers.isEmpty {
            // Either didn't start or stopped before
            manager.start()
        }
        manager.presentingViewController = self
        cachedCellSize = .zero
        collectionView.collectionViewLayout.invalidateLayout()
    }

    @objc func themeDidChange() {
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
        searchBar.backgroundColor = PresentationTheme.current.colors.background
        editController.view.backgroundColor = PresentationTheme.current.colors.background
        setNeedsStatusBarAppearanceUpdate()
    }

    func setupEditToolbar() {
        editController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editController.view)
        var guide: LayoutAnchorContainer = view
        if #available(iOS 11.0, *) {
            guide = view.safeAreaLayoutGuide
        }
        editToolbarConstraint = editController.view.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: EditToolbar.height)
        NSLayoutConstraint.activate([
            editToolbarConstraint!,
            editController.view.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            editController.view.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            editController.view.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadData()
    }

    func isEmptyCollectionView() -> Bool {
        return collectionView?.numberOfItems(inSection: 0) == 0
    }

    func updateUIForContent() {
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

    // MARK: Renderer

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
        super.setEditing(editing, animated: animated)
        // might have an issue if the old datasource was search
        // Most of the edit logic is handled inside editController
        collectionView?.dataSource = editing ? editController : self
        collectionView?.delegate = editing ? editController : self

        editController.resetSelections()
        displayEditToolbar()
        let layoutToBe = editing ? editCollectionViewLayout : UICollectionViewFlowLayout()
        collectionView?.setCollectionViewLayout(layoutToBe, animated: false, completion: {
            [unowned self] finished in
            guard finished else {
                assertionFailure("VLCMediaSubcategoryViewController: Edit layout transition failed.")
                return
            }
            self.searchBarConstraint?.constant = -self.searchBarSize
            self.reloadData()
        })
    }

    private func displayEditToolbar() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.editToolbarConstraint?.constant = self?.isEditing == true ? 0 : EditToolbar.height
            self?.view.layoutIfNeeded()
            self?.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self?.isEditing == true ? EditToolbar.height : 0, right: 0)
        }
    }

    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        let uiTestAccessibilityIdentifier = model is TrackModel ? VLCAccessibilityIdentifier.songs : nil
        return IndicatorInfo(title: model.indicatorName, accessibilityIdentifier: uiTestAccessibilityIdentifier)
    }

    // MARK: - UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearching ? searchDataSource.searchData.count : model.anyfiles.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier:model.cellType.defaultReuseIdentifier, for: indexPath) as? BaseCollectionViewCell else {
            assertionFailure("you forgot to register the cell or the cell is not a subclass of BaseCollectionViewCell")
            return UICollectionViewCell()
        }
        let mediaObject = isSearching ? searchDataSource.objectAtIndex(index: indexPath.row) : model.anyfiles[indexPath.row]
        if let media = mediaObject as? VLCMLMedia {
            // FIXME: This should be done in the VModel, workaround for the release.
            services.medialibraryService.requestThumbnail(for: media)
            assert(media.mainFile() != nil, "The mainfile is nil")
            mediaCell.media = media.mainFile() != nil ? media : nil
        } else {
            mediaCell.media = mediaObject
        }
        mediaCell.isAccessibilityElement = true
        return mediaCell
    }

    // MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let modelContent = isSearching ? searchDataSource.objectAtIndex(index: indexPath.row) : model.anyfiles[indexPath.row]

        if let media = modelContent as? VLCMLMedia {
            play(media: media, at: indexPath)
            createSpotlightItem(media: media)
        } else if let mediaCollection = modelContent as? MediaCollectionModel {
            let collectionViewController = CollectionCategoryViewController(services, mediaCollection: mediaCollection)
            navigationController?.pushViewController(collectionViewController, animated: true)
        }
    }

    func createSpotlightItem(media: VLCMLMedia) {
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
            self.searchBar.resignFirstResponder
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MediaCategoryViewController {
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

    func handleSort() {
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

    func handleSortShortcut() {
        model.sort(by: model.sortModel.currentSort, desc: !model.sortModel.desc)
    }
}

// MARK: VLCActionSheetDelegate

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

// MARK: VLCActionSheetDataSource

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
    func editController(editController: EditController, cellforItemAt indexPath: IndexPath) -> MediaEditCell? {
        return collectionView.cellForItem(at: indexPath) as? MediaEditCell
    }

    func editController(editController: EditController,
                        present viewController: UIViewController) {
        let newNavigationController = UINavigationController(rootViewController: viewController)
        navigationController?.present(newNavigationController, animated: true, completion: nil)
    }
}

private extension MediaCategoryViewController {
    func setupCollectionView() {
        let cellNib = UINib(nibName: model.cellType.nibName, bundle: nil)
        collectionView?.register(cellNib, forCellWithReuseIdentifier: model.cellType.defaultReuseIdentifier)
        if let editCell = (model as? EditableMLModel)?.editCellType() {
            let editCellNib = UINib(nibName: editCell.nibName, bundle: nil)
            collectionView?.register(editCellNib, forCellWithReuseIdentifier: editCell.defaultReuseIdentifier)
        }
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
        collectionView?.alwaysBounceVertical = true
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(gesture:)))
        collectionView?.addGestureRecognizer(longPressGesture)
        if #available(iOS 11.0, *) {
            collectionView?.contentInsetAdjustmentBehavior = .always
            //            collectionView?.dragDelegate = dragAndDropManager
            //            collectionView?.dropDelegate = dragAndDropManager
        }
    }

    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {

        switch gesture.state {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                break
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
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
        let playbackController = VLCPlaybackController.sharedInstance()
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
