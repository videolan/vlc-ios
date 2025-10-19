/*****************************************************************************
 * MediaCateogoryViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *          Mike JS. Choi <mkchoi212 # icloud.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import UIKit

@objc protocol MediaCategoryViewControllerDelegate: NSObjectProtocol {
    func needsToUpdateNavigationbarIfNeeded(_ viewController: MediaCategoryViewController)
    func enableCategorySwitching(for viewController: MediaCategoryViewController,
                                 enable: Bool)
    func setEditingStateChanged(for viewController: MediaCategoryViewController, editing: Bool)
    func updateNavigationBarButtons(for viewController: MediaCategoryViewController, isEditing: Bool)
    @available(iOS 14.0, *)
    func generateMenu(for viewController: MediaCategoryViewController) -> UIMenu
    func updateSelectAllButton(for viewController: MediaCategoryViewController)
}

class MediaCategoryViewController: UICollectionViewController, UISearchBarDelegate, IndicatorInfoProvider {
    // MARK: - Properties
    var model: MediaLibraryBaseModel
    private var secondModel: MediaLibraryBaseModel
    private var mediaLibraryService: MediaLibraryService

    var searchBar = UISearchBar(frame: .zero)
    private var currentDataSet: [VLCMLObject] {
        return searchDataSource.isSearching ? searchDataSource.searchData : model.anyfiles
    }
    private let mediaGridCellNibIdentifier = "MediaGridCollectionCell"
    private var searchBarConstraint: NSLayoutConstraint?
    private var searchDataSource: LibrarySearchDataSource
    private let searchBarSize: CGFloat = 50.0
    private let userDefaults = UserDefaults.standard
#if os(iOS)
    private var rendererButton: UIButton
#endif
    private lazy var editController: EditController = {
        let editController = EditController(mediaLibraryService:mediaLibraryService,
                                            model: model,
                                            presentingView: collectionView,
                                            searchDataSource: searchDataSource)
        editController.delegate = self
        return editController
    }()
    private let reloadLock = NSLock()
    private var cachedCellSize = CGSize.zero
    private var toSize = CGSize.zero
    private var longPressGesture: UILongPressGestureRecognizer!
    weak var delegate: MediaCategoryViewControllerDelegate?

    private lazy var statusBarView: UIView = {
        let statusBarFrame: CGRect
#if os(iOS)
        if #available(iOS 13.0, *) {
            statusBarFrame = view.window?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
        } else {
            statusBarFrame = UIApplication.shared.statusBarFrame
        }
#else
        statusBarFrame = CGRectMake(0, 0, 500, 100) // view.window?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
#endif

        let statusBarView = UIView(frame: statusBarFrame)
        return statusBarView
    }()

    private weak var albumHeader: AlbumHeader?
    private lazy var albumFlowLayout = AlbumHeaderLayout()

    private weak var playlistHeader: PlaylistHeader?

    private lazy var navItemTitle: VLCMarqueeLabel = VLCMarqueeLabel()

    private var hasLaunchedBefore: Bool {
        return userDefaults.bool(forKey: kVLCHasLaunchedBefore)
    }

    @objc private lazy var sortActionSheet: ActionSheet = {
        var header: ActionSheetSortSectionHeader
        var isVideoModel: Bool = false
        var collectionModelName: String = ""
        var secondSortModel: SortModel? = nil

        if let model = model as? CollectionModel {
            if model.mediaCollection is VLCMLMediaGroup || model.mediaCollection is VideoModel {
                isVideoModel = true
            }
            collectionModelName = String(describing: type(of: model.mediaCollection)) + model.name
        } else if let model = model as? MediaGroupViewModel {
            isVideoModel = true
            collectionModelName = model.name
        } else if let model = model as? VideoModel {
            isVideoModel = true
            collectionModelName = secondModel.name
            secondSortModel = model.sortModel
        } else {
            collectionModelName = model.name
        }

        header = ActionSheetSortSectionHeader(model: model.sortModel,
                                              secondModel: secondSortModel,
                                              isVideoModel: isVideoModel,
                                              currentModelType: collectionModelName)

        if model is ArtistModel {
            header.updateHeaderForArtists()
        } else if let model = model as? CollectionModel,
                  let mediaCollection = model.mediaCollection as? VLCMLAlbum,
                  !mediaCollection.isUnknownAlbum() {
            header.updateHeaderForAlbums()
        }

        let actionSheet = ActionSheet(header: header)
        header.delegate = self
        actionSheet.delegate = self
        actionSheet.dataSource = self
        actionSheet.modalPresentationStyle = .custom
        actionSheet.setAction { [weak self] item in
            guard let sortingCriteria = item as? VLCMLSortingCriteria else {
                return
            }
            self?.executeSortAction(with: sortingCriteria,
                                    desc: header.actionSwitch.isOn)
        }
        return actionSheet
    }()

    private lazy var sortBarButton: UIBarButtonItem = {
        return UIBarButtonItem(customView: setupSortButton())
    }()

    private lazy var editBarButton: UIBarButtonItem = {
        return setupEditBarButton()
    }()

    private lazy var clearHistoryButton: UIBarButtonItem = {
        return setupClearHistoryButton()
    }()

    private lazy var selectAllBarButton: UIBarButtonItem = {
        return setupSelectAllButton()
    }()

#if os(iOS)
    private lazy var rendererBarButton: UIBarButtonItem = {
        return UIBarButtonItem(customView: rendererButton)
    }()
#endif

    private lazy var emptyView: VLCEmptyLibraryView = {
        let name = String(describing: VLCEmptyLibraryView.self)
        let nib = Bundle.main.loadNibNamed(name, owner: self, options: nil)
        guard let emptyView = nib?.first as? VLCEmptyLibraryView else { fatalError("Can't find nib for \(name)") }

        // Check if no playlists
        if model is PlaylistModel {
            emptyView.contentType = .noPlaylists
        }

        // Check if history page
        if model is HistoryModel {
            emptyView.contentType = .noHistory
        }

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

    private var scrolledCellIndex: IndexPath = IndexPath()
    private(set) var isAllSelected: Bool = false

    //Continue watching last played media
    private var continueWatchingBottomConstraint: NSLayoutConstraint?

    private lazy var continueWatchingButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = PresentationTheme.current.colors.orangeUI
        button.tintColor = PresentationTheme.current.colors.background
        button.setImage(UIImage(named: "iconPlay")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.layer.cornerRadius = 30.0
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
        button.layer.masksToBounds = false
        button.layer.shadowRadius = 6.0
        button.layer.shadowOpacity = 0.5
        button.addTarget(self, action: #selector(continueWatchingButtonPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var lastPlaylist: LastPlayedPlaylistModel? {
        let encodedLastPlaylist = userDefaults.data(forKey: kVLCLastPlayedPlaylist)
        guard let encodedData = encodedLastPlaylist,
              let lastPlayed = NSKeyedUnarchiver(forReadingWith: encodedData).decodeObject(forKey: "root") as? LastPlayedPlaylistModel else {
            return nil
        }
        return lastPlayed
    }

    // Indicating that the current chosen collection to play is playlist, useful for handling Observer
    private var isPlaylistCurrentlyPlaying: Bool {
        return userDefaults.bool(forKey: kVLCIsCurrentlyPlayingPlaylist)
    }

    // catch the selected index from collection view, helper for playbackDidStart
    private var collectionSelectedIndex: IndexPath? = nil

    private var playbackCache: PlaybackCacheHelper = PlaybackCacheHelper.shared

    // MARK: - Initializers

    @available(*, unavailable)
    init() {
        fatalError()
    }

    init(mediaLibraryService: MediaLibraryService, model: MediaLibraryBaseModel) {
        self.mediaLibraryService = mediaLibraryService

        let videoModel = VideoModel(medialibrary: mediaLibraryService)
        videoModel.secondName = model.name

        if model is MediaGroupViewModel {
            self.model = userDefaults.bool(forKey: kVLCSettingsDisableGrouping) ? videoModel : model
            self.secondModel = userDefaults.bool(forKey: kVLCSettingsDisableGrouping) ? model : videoModel
        } else {
            self.model = model
            self.secondModel = videoModel
        }

#if os(iOS)
        self.rendererButton = VLCAppCoordinator.sharedInstance().rendererDiscovererManager.setupRendererButton()

        if PlaybackService.sharedInstance().renderer != nil {
            rendererButton.isSelected = true
        }
#endif
        self.searchDataSource = LibrarySearchDataSource(model: model)

        super.init(collectionViewLayout: UICollectionViewFlowLayout())

        if let model = model as? CollectionModel,
           let collection = model.mediaCollection as? VLCMLAlbum {
            navItemTitle.text = collection.title
        } else if let collection = model as? CollectionModel {
            navItemTitle.text = collection.mediaCollection.title()
        }

        if model is HistoryModel {
            navItemTitle.text = NSLocalizedString("BUTTON_HISTORY", comment: "")
        }

        navItemTitle.textColor = PresentationTheme.current.colors.navigationbarTextColor
        navItemTitle.font = UIFont.preferredCustomFont(forTextStyle: .headline).bolded

        self.navigationItem.titleView = navItemTitle

    }

    @objc private func handleDisableGrouping() {
        let previousModel = model
        model = secondModel
        secondModel = previousModel
        self.searchDataSource = LibrarySearchDataSource(model: model)
        editController = EditController(mediaLibraryService: mediaLibraryService, model: model, presentingView: collectionView, searchDataSource: searchDataSource)
        editController.delegate = self
        model.sort(by: secondModel.sortModel.currentSort, desc: secondModel.sortModel.desc)
        setupCollectionView()
        cachedCellSize = .zero
        collectionView?.collectionViewLayout.invalidateLayout()
        reloadData()
    }

    @objc func miniPlayerIsShown() {
        collectionView.contentInset.bottom = CGFloat(AudioMiniPlayer.height)
        handleContinueWatchingButtonVisibility()
    }

    @objc func miniPlayerIsHidden() {
        collectionView.contentInset.bottom = 0
        handleContinueWatchingButtonVisibility()
    }

    private func updateAlbumHeader() {
        let backgroundColor: UIColor
        if collectionView.contentOffset.y >= 50 {
            backgroundColor = PresentationTheme.current.colors.background.withAlphaComponent(0.4 * (collectionView.contentOffset.y / 100))
        } else {
            backgroundColor = .clear
        }

        if #available(iOS 13.0, *) {
            let standardAppearance = navigationItem.standardAppearance
            let scrollEdgeAppearance = navigationItem.scrollEdgeAppearance
            standardAppearance?.backgroundColor = backgroundColor
            scrollEdgeAppearance?.backgroundColor = backgroundColor
        }

        if let albumHeader = albumHeader,
           let navBar = navigationController?.navigationBar {
            let padding = statusBarView.frame.maxY + navBar.frame.maxY
            let hideNavigationItemTitle: Bool
            if collectionView.contentOffset.y >= albumHeader.frame.maxY - padding {
                hideNavigationItemTitle = false
            } else {
                hideNavigationItemTitle = true
            }

            navigationItem.titleView?.isHidden = hideNavigationItemTitle
            albumHeader.updateUserInterfaceStyle(isStatusBarVisible: !hideNavigationItemTitle)
        }
    }

    private func updateCollectionViewForAlbum() {
        guard let model = model as? CollectionModel, model.mediaCollection is VLCMLAlbum else {
            return
        }

        collectionView?.register(AlbumHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: AlbumHeader.headerID)
        collectionView.collectionViewLayout = albumFlowLayout
        collectionView.translatesAutoresizingMaskIntoConstraints = false
#if os(iOS)
        let isLandscape: Bool = UIDevice.current.orientation.isLandscape
        let constant: CGFloat
        if let navigationBarHeight = navigationController?.navigationBar.frame.height {
            constant = isLandscape ? navigationBarHeight : navigationBarHeight * 2
        } else {
            constant = isLandscape ? searchBarSize : searchBarSize * 2
        }
#else
        let constant: CGFloat
        if let navigationBarHeight = navigationController?.navigationBar.frame.height {
            constant = navigationBarHeight
        } else {
            constant = searchBarSize
        }
#endif

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: -constant),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        navigationItem.titleView?.isHidden = true

        updateAlbumHeader()
    }

    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = NSLocalizedString("SEARCH", comment: "")
        searchBar.backgroundColor = PresentationTheme.current.colors.background
        navigationItem.largeTitleDisplayMode = .never
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
        defer {
            reloadLock.unlock()
        }

        /* this function can be called multiple times from different threads in short
         * intervals, but we may not reload the views without the previous to finish */
        reloadLock.lock()

        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.reloadData()
            }
            return
        }

        // If we are a MediaGroupViewModel, check if there are no empty groups from ungrouping.
        if let mediaGroupModel = model as? MediaGroupViewModel {
            mediaGroupModel.fileArrayQueue.sync {
                mediaGroupModel.files = mediaGroupModel.files.filter() {
                    return $0.nbTotalMedia() != 0
                }
            }
        }

        delegate?.needsToUpdateNavigationbarIfNeeded(self)
        collectionView?.reloadData()
        updateUIForContent()

        if !searchDataSource.isSearching {
            popViewIfNecessary()
        }

        if let tabBarController = tabBarController as? BottomTabBarController,
           let editToolBar = tabBarController.editToolBar(),
           isEditing {
            editToolBar.updateEditToolbar(for: model)
        }
    }

    func isEmptyCollectionView() -> Bool {
        return currentDataSet.isEmpty
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder: ) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSearchBar()
        if let model = model as? CollectionModel {
            if model.mediaCollection is VLCMLAlbum {
                if #available(iOS 13.0, *) {
                    self.navigationItem.standardAppearance = AppearanceManager.navigationBarAlbumAppearance()
                    self.navigationItem.scrollEdgeAppearance = AppearanceManager.navigationBarAlbumAppearance()
                }
                searchBar.removeFromSuperview()
                updateCollectionViewForAlbum()
            }
        }

        addThemeChangeObserver()
    }

    override func viewDidDisappear(_ animated: Bool) {
        if let model = model as? CollectionModel,
           model.mediaCollection is VLCMLAlbum {
            statusBarView.removeFromSuperview()
            view.addSubview(searchBar)
            AppearanceManager.setupUserInterfaceStyle(theme: PresentationTheme.current)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if os(iOS)
        let manager = VLCAppCoordinator.sharedInstance().rendererDiscovererManager
        manager.delegate = self
        if manager.discoverers.isEmpty {
            // Either didn't start or stopped before
            manager.start()
        }
        manager.presentingViewController = self
#endif
        let playbackService = PlaybackService.sharedInstance()
        playbackService.setPlayerHidden(isEditing)
        playbackService.playerDisplayController.isMiniPlayerVisible
        ? miniPlayerIsShown() : miniPlayerIsHidden()

        cachedCellSize = .zero
        collectionView.collectionViewLayout.invalidateLayout()
        setupCollectionView() //Fixes crash that is caused due to layout change
        setNavbarAppearance()
        loadSort()

        addInitializationCommonObservers()
        configureContinueWatchingButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        showGuideOnLaunch()
        updateCollectionViewForAlbum()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        continueWatchingButton.removeFromSuperview()

        removeInitializationCommonObservers()

        if isMovingFromParent {
            removeThemeChangeObserver()
        }
    }

    private func addInitializationCommonObservers() {
        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self, selector: #selector(miniPlayerIsShown),
                                       name: NSNotification.Name(rawValue: VLCPlayerDisplayControllerDisplayMiniPlayer),
                                       object: nil)
        notificationCenter.addObserver(self, selector: #selector(miniPlayerIsHidden),
                                       name: NSNotification.Name(rawValue: VLCPlayerDisplayControllerHideMiniPlayer),
                                       object: nil)
        notificationCenter.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)),
                                       name: UIContentSizeCategory.didChangeNotification,
                                       object: nil)

        if model is MediaGroupViewModel || model is VideoModel {
            notificationCenter.addObserver(self, selector: #selector(handleDisableGrouping),
                                           name: .VLCDisableGroupingDidChangeNotification,
                                           object: nil)
        }

        notificationCenter.addObserver(self, selector: #selector(playbackDidStop),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidStop), object: nil)

        if PlaybackService.sharedInstance().isPlaying && isPlaylistCurrentlyPlaying {
            addPlaybackWillStopObserver()
        }

        notificationCenter.addObserver(self, selector: #selector(playbackDidStart),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidStart), object: nil)
    }

    private func removeInitializationCommonObservers() {
        let notificationCenter = NotificationCenter.default

        notificationCenter.removeObserver(self, name: NSNotification.Name(rawValue: VLCPlayerDisplayControllerDisplayMiniPlayer), object: nil)
        notificationCenter.removeObserver(self, name:  NSNotification.Name(rawValue: VLCPlayerDisplayControllerHideMiniPlayer), object: nil)
        notificationCenter.removeObserver(self, name: UIContentSizeCategory.didChangeNotification, object: nil)

        if model is MediaGroupViewModel || model is VideoModel {
            notificationCenter.removeObserver(self, name: .VLCDisableGroupingDidChangeNotification, object: nil)
        }

        notificationCenter.removeObserver(self, name: Notification.Name(VLCPlaybackServicePlaybackDidStop), object: nil)
    }

    private func addThemeChangeObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification, object: nil)
    }

    private func removeThemeChangeObserver() {
        let notificationCenter = NotificationCenter.default

        notificationCenter.removeObserver(self, name: .VLCThemeDidChangeNotification, object: nil)

        if PlaybackService.sharedInstance().isPlaying && isPlaylistCurrentlyPlaying {
            removePlaybackWillStopObserver()
        }

        notificationCenter.removeObserver(self, name: Notification.Name(VLCPlaybackServicePlaybackDidStart), object: nil)
    }

    func loadSort() {
        let sortingCriteria: VLCMLSortingCriteria
        if let sortingCriteriaDefault = UserDefaults.standard.value(forKey: "\(kVLCSortDefault)\(model.name)") as? UInt {
            sortingCriteria = VLCMLSortingCriteria(rawValue: sortingCriteriaDefault) ?? model.sortModel.currentSort
        } else {
            sortingCriteria = model.sortModel.currentSort
        }
        let desc = UserDefaults.standard.bool(forKey: "\(kVLCSortDescendingDefault)\(model.name)")
        self.model.sort(by: sortingCriteria, desc: desc)
    }

    private func setNavbarAppearance() {
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance = AppearanceManager.navigationbarAppearance()
            navigationController?.navigationBar.scrollEdgeAppearance = AppearanceManager.navigationbarAppearance()
        }
        navigationController?.navigationBar.barTintColor = PresentationTheme.current.colors.navigationbarColor
#if os(iOS)
        setNeedsStatusBarAppearanceUpdate()
#endif
    }

    @objc func themeDidChange() {
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
        searchBar.backgroundColor = PresentationTheme.current.colors.background
        if let marqueeLabel = navigationItem.titleView as? VLCMarqueeLabel {
            marqueeLabel.textColor = PresentationTheme.current.colors.navigationbarTextColor
        }

        continueWatchingButton.tintColor = PresentationTheme.current.colors.background
    }

    private func showGuideOnLaunch() {
        if !hasLaunchedBefore {
            let firstStepController = VLCFirstStepsViewController()
            let navigationController = UINavigationController(rootViewController: firstStepController)
            navigationController.modalPresentationStyle = .formSheet
            self.present(navigationController, animated: true)
            userDefaults.set(true, forKey: kVLCHasLaunchedBefore)
        } else {
            if userDefaults.bool(forKey: kVLCHasActiveSubscription) {
                return
            }

            var lastNagMonth = userDefaults.integer(forKey: kVLCHasNaggedThisMonth)
            let numberOfLaunches = userDefaults.integer(forKey: kVLCNumberOfLaunches)
            let currentMonth = NSCalendar.current.component(.month, from: Date())

            if lastNagMonth == 12 && currentMonth < 12 {
                lastNagMonth = 0
            }

            if lastNagMonth < currentMonth && numberOfLaunches >= 5 {
                userDefaults.setValue(currentMonth, forKey: kVLCHasNaggedThisMonth)
                userDefaults.setValue(0, forKey: kVLCNumberOfLaunches)
                let donationVC = VLCDonationNagScreenViewController(nibName: "VLCDonationNagScreenViewController", bundle: nil)
                let donationNC = UINavigationController(rootViewController: donationVC)
                donationNC.navigationBar.isHidden = true
                donationNC.modalTransitionStyle = .crossDissolve
                donationNC.modalPresentationStyle = .overFullScreen
                self.present(donationNC, animated: true)
            }
        }
    }

    @objc private func playbackDidStop() {
        //Handles the visibility when stop the playback from a full screen video player
        handleContinueWatchingButtonVisibility()
    }

    @objc private func playbackDidStart() {
        if let model = model as? CollectionModel, let playlist = model.mediaCollection as? VLCMLPlaylist, let selectedIndex = collectionSelectedIndex {
            saveCurrentPlaylistInfo(with: playlist.identifier(), playlistTitle: playlist.title(), media: playlist.media?[selectedIndex.row])
            addPlaybackWillStopObserver()
            reloadData()
            userDefaults.set(true, forKey: kVLCIsCurrentlyPlayingPlaylist)
        } else if let playlists = currentDataSet as? [VLCMLPlaylist], let selectedIndex = collectionSelectedIndex {
            let selectedPlaylist = playlists[selectedIndex.row]
            guard let media = PlaybackService.sharedInstance().currentlyPlayingMedia,
                  let mlMedia = VLCMLMedia(forPlaying: media) else { return }

            saveCurrentPlaylistInfo(with: selectedPlaylist.identifier(), playlistTitle: selectedPlaylist.title(), media: mlMedia)
            addPlaybackWillStopObserver()
            reloadData()
            userDefaults.set(true, forKey: kVLCIsCurrentlyPlayingPlaylist)
        } else if isPlaylistCurrentlyPlaying {
            //if the playlist media is already being played and the current model is not Playlist or playlist collection media.
            //This will update the value of last played media, leading to right indication if the app is suddenly closed.
            guard let media = PlaybackService.sharedInstance().currentlyPlayingMedia,
                  let mlMedia = VLCMLMedia(forPlaying: media),
                  let lastPlaylist = lastPlaylist else {
                return
            }
            saveCurrentPlaylistInfo(with: lastPlaylist.identifier, playlistTitle: lastPlaylist.title, media: mlMedia)
        }
    }
    // MARK: - Renderer

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        cachedCellSize = .zero
        toSize = size
        collectionView?.collectionViewLayout.invalidateLayout()
        updateContinueWatchingConstraints()

        if let playlistHeader = playlistHeader {
            playlistHeader.updateAfterRotation()
        }
    }

    // MARK: - Edit

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        resetScrollView()
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // This ensures that the search bar is always visible like a sticky while searching
        if searchDataSource.isSearching {
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
            collectionView.contentInset.top = searchBarSize
        }
        if scrollView.contentOffset.y >= 0 && scrollView.contentInset.top != 0 {
            collectionView.contentInset.top = 0
        }

        if let model = model as? CollectionModel,
           model.mediaCollection is VLCMLAlbum {

            updateAlbumHeader()
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        guard editing != isEditing else {
            // Guard in case where setEditing is called twice with the same state
            return
        }
        super.setEditing(editing, animated: animated)

        editController.shouldResetCells(!isEditing)

        collectionView?.dataSource = editing ? editController : self
        collectionView?.delegate = editing ? editController : self
        if #available(iOS 14.0, *) {
            /// Those changes are highly recommended in order to prevent a UICollectionView gesture
            /// issue when cells are embedding a UIScrollView
            /// See https://code.videolan.org/umxprime/collection-view-bug
            collectionView?.allowsSelectionDuringEditing = editing
            collectionView?.allowsMultipleSelectionDuringEditing = editing
        }

        editController.resetSelections(resetUI: true)
        displayEditToolbar()

        PlaybackService.sharedInstance().setPlayerHidden(editing)

        searchBar.resignFirstResponder()

        // When quitting the edit mode, reset all selection state
        if isEditing == false {
            isAllSelected = false
            selectAllBarButton.image = UIImage(named: "emptySelectAll")
        }

        reloadData()
        // this will set continue button to be hidden, in editing mode
        handleContinueWatchingButtonVisibility()
    }

    private func displayEditToolbar() {
        if let tabBarController = tabBarController as? BottomTabBarController {
            if isEditing {
                tabBarController.editToolBar()?.delegate = editController
                tabBarController.displayEditToolbar(with: model)
            } else {
                tabBarController.hideEditToolbar()
            }
        }
    }

    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        var uiTestAccessibilityIdentifier = model is TrackModel ? VLCAccessibilityIdentifier.songs : nil
        if model is ArtistModel {
            uiTestAccessibilityIdentifier = VLCAccessibilityIdentifier.artists
        }
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

    private func updateUIForContent() {
        if searchDataSource.isSearching {
            return
        }

        let isEmpty = isEmptyCollectionView()
        if isEmpty {
            collectionView?.setContentOffset(.zero, animated: false)
        }
        searchBar.isHidden = isEmpty
        collectionView?.backgroundView = isEmpty ? emptyView : nil
        updateBarButtonItems()
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
        if KeychainCoordinator.passcodeService.hasSecret {
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

    @objc func preferredContentSizeChanged(_ notification: Notification) {
        cachedCellSize = .zero
        collectionView?.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - NavigationItem

extension MediaCategoryViewController {
    private func setupEditBarButton() -> UIBarButtonItem {
        let editButton = UIBarButtonItem(image: UIImage(named: "edit"),
                                         style: .plain, target: self,
                                         action: #selector(handleEditingInsideCollection))
        editButton.tintColor = PresentationTheme.current.colors.orangeUI
        editButton.accessibilityLabel = NSLocalizedString("BUTTON_EDIT", comment: "")
        editButton.accessibilityHint = NSLocalizedString("BUTTON_EDIT_HINT", comment: "")
        return editButton
    }

    private func setupSelectAllButton() -> UIBarButtonItem {
        let selectAll = UIBarButtonItem(image: UIImage(named: "emptySelectAll"),
                                        style: .plain, target: self,
                                        action: #selector(handleSelectAll))
        selectAll.accessibilityLabel = NSLocalizedString("BUTTON_SELECT_ALL", comment: "")
        selectAll.accessibilityHint = NSLocalizedString("BUTTON_SELECT_ALL_HINT", comment: "")
        return selectAll
    }

    private func setupClearHistoryButton() -> UIBarButtonItem {
        let clearHistory = UIBarButtonItem(title: NSLocalizedString("BUTTON_CLEAR", comment: ""),
                                           style: .plain, target: self,
                                           action: #selector(handleClearHistory))
        clearHistory.accessibilityLabel = NSLocalizedString("BUTTON_CLEAR", comment: "")
        return clearHistory
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

    private func leftBarButtonItem() -> [UIBarButtonItem] {
        var leftBarButtonItems = [UIBarButtonItem]()

        leftBarButtonItems.append(selectAllBarButton)
        return leftBarButtonItems
    }

    private func rightBarButtonItems() -> [UIBarButtonItem] {
        var rightBarButtonItems = [UIBarButtonItem]()

        if #available(iOS 14.0, *) {
            let menu = delegate?.generateMenu(for: self)
            rightBarButtonItems.append(UIBarButtonItem(image:
                                                        UIImage(systemName: "ellipsis.circle"),
                                                       menu: menu))
        } else {
            rightBarButtonItems.append(editBarButton)
            // Sort is not available for Playlists
            if let model = model as? CollectionModel, !(model.mediaCollection is VLCMLPlaylist) {
                rightBarButtonItems.append(sortBarButton)
            }
        }
#if os(iOS)
        if !rendererButton.isHidden {
            rightBarButtonItems.append(rendererBarButton)
        }
#endif
        return rightBarButtonItems
    }

    private func updateBarButtonItems() {
        if !isEditing {
            navigationItem.rightBarButtonItems = rightBarButtonItems()
            navigationItem.setHidesBackButton(isEditing, animated: true)
        }

        if self is HistoryCategoryViewController {
            navigationItem.rightBarButtonItem = clearHistoryButton
        }

        if isEmptyCollectionView() {
            navigationItem.rightBarButtonItem = nil
            navigationItem.leftBarButtonItem = nil
        }
    }

    func handleRegroup() {
        guard let mediaGroupViewModel = model as? MediaGroupViewModel else {
            assertionFailure("MediaCategoryViewController: handleRegroup: Mismatching model can't regroup.")
            return
        }

        let cancelButton = VLCAlertButton(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                          style: .cancel)
        let regroupButton = VLCAlertButton(title: NSLocalizedString("BUTTON_REGROUP", comment: ""),
                                           style: .destructive,
                                           action: {
            [unowned self] action in
            self.mediaLibraryService.medialib.regroupAll()
            mediaGroupViewModel.files = self.mediaLibraryService.medialib.mediaGroups() ?? []
            self.delegate?.setEditingStateChanged(for: self, editing: false)
        })

        VLCAlertViewController.alertViewManager(title: NSLocalizedString("BUTTON_REGROUP_TITLE", comment: ""),
                                                errorMessage: NSLocalizedString("BUTTON_REGROUP_DESCRIPTION",
                                                                                comment: ""),
                                                viewController: self,
                                                buttonsAction: [cancelButton,
                                                                regroupButton])
    }

    @objc func executeSortAction(with sortingCriteria: VLCMLSortingCriteria, desc: Bool) {
        model.sort(by: sortingCriteria, desc: desc)
        userDefaults.set(desc,
                         forKey: "\(kVLCSortDescendingDefault)\(model.name)")
        userDefaults.set(sortingCriteria.rawValue,
                         forKey: "\(kVLCSortDefault)\(model.name)")
        sortActionSheet.removeActionSheet()
        reloadData()
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
#if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
            handleSortShortcut()
        }
    }

    @objc func handleClearHistory() {
        let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel)

        let clearAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("BUTTON_CLEAR", comment: ""), style: .destructive) { _ in
            self.mediaLibraryService.medialib.clearHistory(of: .global)
        }

        let alertController: UIAlertController = UIAlertController(title: NSLocalizedString("CLEAR_HISTORY_TITLE", comment: ""),
                                                                   message: NSLocalizedString("CLEAR_HISTORY_MESSAGE", comment: ""),
                                                                   preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(clearAction)

        present(alertController, animated: true)
    }

    @objc func handleSelectAll() {
        isAllSelected = !isAllSelected
        editController.selectAll()
        selectAllBarButton.image = isAllSelected ? UIImage(named: "allSelected")
        : UIImage(named: "emptySelectAll")
    }

    @objc func handleSortShortcut() {
        model.sort(by: model.sortModel.currentSort, desc: !model.sortModel.desc)
    }

    @objc func handleEditingInsideCollection() {
        isEditing = !isEditing
        navigationItem.rightBarButtonItems = isEditing ? [UIBarButtonItem(barButtonSystemItem: .done,
                                                                          target: self,
                                                                          action: #selector(handleEditingInsideCollection))]
        : rightBarButtonItems()
        navigationItem.leftBarButtonItems = leftBarButtonItem()
        if navigationController?.viewControllers.last is ArtistViewController || navigationController?.viewControllers.last is CollectionCategoryViewController {
            delegate?.updateNavigationBarButtons(for: self, isEditing: isEditing)
        }
        navigationItem.setHidesBackButton(isEditing, animated: true)
    }
}

// MARK: - VLCRendererDiscovererManagerDelegate

#if os(iOS)
extension MediaCategoryViewController: VLCRendererDiscovererManagerDelegate {
    @objc func addedRendererItem() {
        updateBarButtonItems()

        if let delegate = delegate as? MediaViewController {
            delegate.updateButtonsFor(self)
        }
    }

    @objc func removedRendererItem() {
        updateBarButtonItems()

        if let delegate = delegate as? MediaViewController,
           VLCAppCoordinator.sharedInstance().rendererDiscovererManager.getAllRenderers().isEmpty {
            delegate.updateButtonsFor(self)
        }
    }
}
#endif

// MARK: - UISearchBarDelegate

extension MediaCategoryViewController {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        reloadData()
        searchDataSource.isSearching = true
        delegate?.enableCategorySwitching(for: self, enable: false)
        searchBar.setShowsCancelButton(true, animated: true)
        // hides continue watching button when searching is active
        handleContinueWatchingButtonVisibility()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        // Empty the text field and reset the research
        searchBar.text = ""
        searchDataSource.shouldReloadFor(searchString: "")
        searchBar.setShowsCancelButton(false, animated: true)
        searchDataSource.isSearching = false
        delegate?.enableCategorySwitching(for: self, enable: true)
        reloadData()
        // shows continue watching button when searching is done
        handleContinueWatchingButtonVisibility()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        delegate?.enableCategorySwitching(for: self, enable: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchDataSource.shouldReloadFor(searchString: searchText)
        reloadData()
    }
}

// MARK: - UICollectionViewDelegate - Private Helpers

private extension MediaCategoryViewController {
    private func generatePlayAction(for modelContent: VLCMLObject?, type: EditButtonType) {
        if let media = modelContent as? VLCMLMedia {
            let playbackController = PlaybackService.sharedInstance()
            let mediaList = playbackController.mediaList
            mediaList.lock()
            switch type {
            case .play:
                playbackController.play(media)
            case .playNextInQueue:
                playbackController.playMediaNextInQueue(media)
                NotificationCenter.default.post(name: .VLCDidAppendMediaToQueue, object: nil)
            case .appendToQueue:
                playbackController.appendMediaToQueue(media)
                NotificationCenter.default.post(name: .VLCDidAppendMediaToQueue, object: nil)
            case .playAsAudio:
                playbackController.playAsAudio = true
                playbackController.play(media)
            default:
                assertionFailure("generatePlayAction: cannot be used with other actions")
            }

            mediaList.unlock()
        } else if let collection = modelContent as? MediaCollectionModel {
            let playbackController = PlaybackService.sharedInstance()
            let mediaList = playbackController.mediaList
            mediaList.lock()
            let files: [VLCMLMedia]?

            if collection is VLCMLAlbum {
                files = collection.files(with: .trackNumber, desc: false)
            } else {
                files = collection.files(with: .default, desc: false)
            }

            switch type {
            case .play:
                playbackController.playCollection(files)
            case .playNextInQueue:
                playbackController.playCollectionNextInQueue(files)
                NotificationCenter.default.post(name: .VLCDidAppendMediaToQueue, object: nil)
            case .appendToQueue:
                playbackController.appendCollectionToQueue(files)
                NotificationCenter.default.post(name: .VLCDidAppendMediaToQueue, object: nil)
            case .playAsAudio:
                playbackController.playAsAudio = true
                playbackController.playCollection(files)
            default:
                assertionFailure("generatePlayAction: cannot be used with other actions")
            }

            mediaList.unlock()
        }

        // handle catching current played playlist or media by queue options from different platlists
        guard let modelContent = modelContent,
              type == .appendToQueue || type == .playNextInQueue else {
            return
        }

        cachePlaylistInfoFromPlayerQueue(for: modelContent)
    }

    @available(iOS 13.0, *)
    private func generateUIMenuForContent(at indexPath: IndexPath) -> UIMenu {
        let index = indexPath.row
        let modelContent = currentDataSet.objectAtIndex(index: index)
        collectionSelectedIndex = indexPath
        // Remove addToMediaGroup from quick actions since it is applicable only to multiple media
        let actionList = EditButtonsFactory.buttonList(for: model).filter({
            return $0 != .addToMediaGroup
        })
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
            case .addToMediaGroup:
                return $0.action() { _ in }
            case .removeFromMediaGroup:
                return $0.action({
                    [weak self] _ in
                    if let modelContent = modelContent {
                        self?.editController.editActions.objects = [modelContent]
                        self?.editController.editActions.removeFromMediaGroup()
                    }
                })
            case .rename:
                return $0.action({
                    [weak self] _ in
                    if let modelContent = modelContent {
                        self?.editController.editActions.objects = [modelContent]
                        self?.editController.editActions.rename() {
                            [weak self] state in
                            if state == .success {
                                self?.reloadData()
                            }
                        }
                    }
                })
            case .delete:
                return $0.action({
                    [weak self] _ in
                    if let modelContent = modelContent {
                        self?.editController.editActions.objects = [modelContent]
                        self?.editController.editActions.delete() {
                            [weak self] state in
                            if state == .success {
                                self?.searchDataSource.deleteInSearch(index: index)
                            }
                        }
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
            case .play:
                return $0.action({
                    _ in
                    self.generatePlayAction(for: modelContent, type: .play)
                })
            case .playNextInQueue:
                return $0.action({
                    _ in
                    self.generatePlayAction(for: modelContent, type: .playNextInQueue)
                })
            case .appendToQueue:
                return $0.action({
                    _ in
                    self.generatePlayAction(for: modelContent, type: .appendToQueue)
                })
            case .playAsAudio:
                return $0.action({
                    _ in
                    self.generatePlayAction(for: modelContent, type: .playAsAudio)
                })
            }
        })
    }
}

// MARK: - UICollectionViewDelegate

extension MediaCategoryViewController {
    override func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        // Set collectionView.isEditing to true
        return true
    }


    override func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        // Put the collection view into editing mode.
        delegate?.setEditingStateChanged(for: self, editing: true)
    }


    private func selectedItem(at indexPath: IndexPath) {
        let modelContent = currentDataSet.objectAtIndex(index: indexPath.row)
        collectionSelectedIndex = indexPath
        // Reset the play as audio variable
        let playbackService = PlaybackService.sharedInstance()
        playbackService.playAsAudio = false

        if let mediaGroup = modelContent as? VLCMLMediaGroup,
           mediaGroup.nbTotalMedia() == 1 && !mediaGroup.userInteracted() {
            // We handle only mediagroups of video
            guard let media = mediaGroup.media(of: .unknown)?.first else {
                assertionFailure("MediaCategoryViewController: Failed to fetch mediagroup video.")
                return
            }
            play(media: media, at: indexPath)
            createSpotlightItem(media: media)
            return
        }

        if let media = modelContent as? VLCMLMedia {
            play(media: media, at: indexPath)
            createSpotlightItem(media: media)
        } else if let artist = modelContent as? VLCMLArtist {
            let artistViewController = ArtistViewController(mediaLibraryService: mediaLibraryService, mediaCollection: artist)
            navigationController?.pushViewController(artistViewController, animated: true)
        } else if let mediaCollection = modelContent as? MediaCollectionModel {
            let collectionViewController = CollectionCategoryViewController(mediaLibraryService,
                                                                            mediaCollection: mediaCollection)

            collectionViewController.delegate = delegate
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
        let modelContent = currentDataSet.objectAtIndex(index: indexPath.row)
        let cell = collectionView.cellForItem(at: indexPath)
        var thumbnail: UIImage? = nil
        if let cell = cell as? MovieCollectionViewCell {
            thumbnail = cell.thumbnailView.image
        } else if let cell = cell as? MediaCollectionViewCell {
            let image: UIImage?
            if cell.isMediaBeingPlayed {
                image = cell.backupThumbnail
            } else {
                image = cell.thumbnailView.image
            }
            thumbnail = image
        } else if let cell = cell as? MediaGridCollectionCell {
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

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let model = model as? CollectionModel else {
            return .init(width: 0, height: 0)
        }

        if model.mediaCollection is VLCMLAlbum {
            return albumFlowLayout.getHeaderSize(with: collectionView.frame.size.width)
        } else if model.mediaCollection is VLCMLPlaylist {
            return PlaylistHeader.getHeaderSize(with: collectionView.frame.size.width)
        } else {
            return .init(width: 0, height: 0)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension MediaCategoryViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentDataSet.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier:model.cellType.defaultReuseIdentifier, for: indexPath) as? BaseCollectionViewCell else {
            assertionFailure("you forgot to register the cell or the cell is not a subclass of BaseCollectionViewCell")
            return UICollectionViewCell()
        }

        let mediaObject = currentDataSet.objectAtIndex(index: indexPath.row)

        guard mediaObject != nil else {
            assertionFailure("MediaCategoryViewController: Failed to fetch media object.")
            return mediaCell
        }

        if let mediaGroup = mediaObject as? VLCMLMediaGroup {
            guard let mediaArray = mediaGroup.media(of: .unknown) else {
                assertionFailure("MediaCategoryViewController: Failed to retrieve media array")
                return mediaCell
            }

            // we show up to 4 thumbnails per group, so request those
            for index in 0...3 {
                if let media = mediaArray.objectAtIndex(index: index) {
                    mediaLibraryService.requestThumbnail(for: media)
                }
            }
        } else if let media = mediaObject as? VLCMLMedia {
            if media.type() == .unknown || media.type() == .video {
                mediaLibraryService.requestThumbnail(for: media)
                assert(media.mainFile() != nil, "The mainfile is nil")
            }
        }

        if let mediaCell = mediaCell as? MediaCollectionViewCell {
            mediaCell.delegate = self
            mediaCell.isEditing = false
        }

        // For Playlists Model, check for the last playlist from all playlists
        if let model = mediaObject as? VLCMLPlaylist, isLastPlayedPlaylist(model) {
            setLastPlayed(for: mediaCell)
        } else if let model = model as? CollectionModel,
                  let playlist = model.mediaCollection as? VLCMLPlaylist,
                  isLastPlayedPlaylist(playlist),
                  let media = mediaObject as? VLCMLMedia,
                  let lastMedia = lastPlaylist?.lastPlayedMedia,
                  lastMedia.identifier == media.identifier() && lastMedia.title == media.title {

            // Check if collection model is a playlist and it is the last played media. This check is done inside a playlist
            setLastPlayed(for: mediaCell)
        }

        mediaCell.media = mediaObject
        mediaCell.isAccessibilityElement = true

        return mediaCell
    }

    // Helper function to check if a playlist is the last played playlist
    func isLastPlayedPlaylist(_ playlist: VLCMLPlaylist?) -> Bool {
        guard let playlist = playlist, let lastPlaylist = lastPlaylist else {
            return false
        }

        return playlist.title() == lastPlaylist.title && playlist.identifier() == lastPlaylist.identifier
    }

    // Helper function to set the lastPlayed property for the cell
    func setLastPlayed(for mediaCell: UICollectionViewCell?) {
        if let cell = mediaCell as? MediaCollectionViewCell {
            cell.lastPlayed = true
        } else if let cell = mediaCell as? MovieCollectionViewCell {
            cell.lastPlayed = true
        }
    }

    private func setupAlbumHeaderReusableView(headerView: AlbumHeader, collection: VLCMLAlbum) -> UICollectionReusableView {
        let thumbnail = collection.thumbnail()
        headerView.updateImage(with: thumbnail)
        headerView.collection = collection
        headerView.updateThumbnailTitle(collection.title)

        headerView.shouldDisablePlayButtons(false)
        headerView.updateParentView(parent: view)
        albumHeader = headerView

        return headerView
    }

    private func setupPlaylistHeaderReusableView(headerView: PlaylistHeader, collection: VLCMLPlaylist) -> UICollectionReusableView {
        headerView.updateImage(with: collection.thumbnail())
        headerView.updateTitle(with: collection.title())
        headerView.collection = collection
        headerView.sortModel = model.sortModel
        playlistHeader = headerView
        return headerView
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        if let collectionModel = model as? CollectionModel,
           let collection = collectionModel.mediaCollection as? VLCMLAlbum,
           let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: AlbumHeader.headerID, for: indexPath) as? AlbumHeader {
            return setupAlbumHeaderReusableView(headerView: header, collection: collection)
        } else if let collectionModel = model as? CollectionModel,
                  let collection = collectionModel.mediaCollection as? VLCMLPlaylist,
                  let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PlaylistHeader.headerID, for: indexPath) as? PlaylistHeader {
            return setupPlaylistHeaderReusableView(headerView: header, collection: collection)
        }

        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MediaCategoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if cachedCellSize == .zero {
            //For iOS 10 when rotating we take the value from willTransition to size, for the first layout pass that value is 0 though,
            //so we need the frame.size width. For rotation on iOS 11 this approach doesn't work because at the time when this is called
            //we don't have yet the updated safeare layout frame. This is addressed by relayouting from viewSafeAreaInsetsDidChange

            // In case of nested views, the safe area may not be updated.
            // Getting its parent's safe area gives us the true updated safe area.
            let toWidth = parent?.view.safeAreaLayoutGuide.layoutFrame.width ?? collectionView.safeAreaLayoutGuide.layoutFrame.width
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
    private func getTypeName(of mediaCollection: MediaCollectionModel) -> String {
        return String(describing: type(of: mediaCollection))
    }

    func handleLayoutChange(gridLayout: Bool) {
        var prefix: String = ""
        var suffix: String = ""

        var collectionModelName: String = ""
        var isVideoModel = false
        if let model = model as? CollectionModel {
            if model.mediaCollection is VLCMLMediaGroup || model.mediaCollection is VideoModel {
                isVideoModel = true
            }
            collectionModelName = getTypeName(of: model.mediaCollection)
        } else if model is VideoModel || model is MediaGroupViewModel {
            isVideoModel = true
        }

        prefix = isVideoModel ? kVLCVideoLibraryGridLayout : kVLCAudioLibraryGridLayout
        suffix = collectionModelName + model.name
        userDefaults.set(gridLayout, forKey: "\(prefix)\(suffix)")
        setupCollectionView()
        cachedCellSize = .zero
        collectionView?.collectionViewLayout.invalidateLayout()
        reloadData()
    }

    func actionSheetSortSectionHeaderShouldHideFeatArtists(onSwitchIsOnChange: Bool) {
        userDefaults.set(onSwitchIsOnChange, forKey: "\(kVLCAudioLibraryHideFeatArtists)")
        setupCollectionView()
        cachedCellSize = .zero
        model.sort(by: model.sortModel.currentSort, desc: model.sortModel.desc)
        reloadData()
    }

    func actionSheetSortSectionHeaderShouldHideTrackNumbers(onSwitchIsOnChange: Bool) {
        userDefaults.set(onSwitchIsOnChange, forKey: "\(kVLCAudioLibraryHideTrackNumbers)")
        setupCollectionView()
        cachedCellSize = .zero
        model.sort(by: model.sortModel.currentSort, desc: model.sortModel.desc)
        reloadData()
    }

    func actionSheetSortSectionHeader(_ header: ActionSheetSortSectionHeader, onSwitchIsOnChange: Bool, type: ActionSheetSortHeaderOptions) {
        var prefix: String = ""
        var suffix: String = ""
        if type == .descendingOrder {
            model.sort(by: model.sortModel.currentSort, desc: onSwitchIsOnChange)
            prefix = kVLCSortDescendingDefault
            suffix = model is VideoModel ? secondModel.name : model.name
            userDefaults.set(onSwitchIsOnChange, forKey: "\(prefix)\(suffix)")
            setupCollectionView()
            cachedCellSize = .zero
            collectionView?.collectionViewLayout.invalidateLayout()
            reloadData()
        } else if type == .layoutChange {
            handleLayoutChange(gridLayout: onSwitchIsOnChange)
        }
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

    func editControllerDidSelectMultipleItem(editContrller: EditController) {
        searchBar.isUserInteractionEnabled = false
        searchBar.alpha = 0.5
        if let tabBarController = tabBarController as? BottomTabBarController,
           let editToolBar = tabBarController.editToolBar() {
            editToolBar.enableEditActions(true)
        }
    }

    func editControllerDidDeSelectMultipleItem() {
        searchBar.isUserInteractionEnabled = true
        searchBar.alpha = 1
        if let tabBarController = tabBarController as? BottomTabBarController,
           let editToolBar = tabBarController.editToolBar() {
            editToolBar.enableEditActions(false)
        }
    }

    func editControllerDidFinishEditing(editController: EditController?) {
        if let model = model as? CollectionModel,
           model.mediaCollection is VLCMLMediaGroup {
            // The media group's view can be discarded when the group is emptied, there is a need to propagate the information.
            delegate?.setEditingStateChanged(for: self, editing: false)
        } else if self is CollectionCategoryViewController {
            // NavigationItems for other Collections are created from the parent, there is no need to propagate the information.
            handleEditingInsideCollection()
        } else {
            delegate?.setEditingStateChanged(for: self, editing: false)
        }
    }

    func editControllerGetCurrentThumbnail() -> UIImage? {
        if let model = model as? CollectionModel {
            return model.thumbnail
        }

        return nil
    }

    func editControllerGetAlbumHeaderSize(with width: CGFloat) -> CGSize {
        return albumFlowLayout.getHeaderSize(with: width)
    }

    func editControllerUpdateNavigationBar(offset: CGFloat) {
        if let model = model as? CollectionModel,
           model.mediaCollection is VLCMLAlbum {

            let backgroundColor: UIColor
            if offset >= 50 {
                backgroundColor = PresentationTheme.current.colors.background.withAlphaComponent(0.4 * (offset / 100))
            } else {
                backgroundColor = .clear
            }

            if #available(iOS 13.0, *) {
                let standardAppearance = navigationItem.standardAppearance
                let scrollEdgeAppearance = navigationItem.scrollEdgeAppearance
                standardAppearance?.backgroundColor = backgroundColor
                scrollEdgeAppearance?.backgroundColor = backgroundColor
            }

            if let albumHeader = albumHeader,
               let navBar = navigationController?.navigationBar {
                let padding = statusBarView.frame.maxY + navBar.frame.maxY
                let hideNavigationBarTitle: Bool
                if offset >= albumHeader.frame.maxY - padding {
                    hideNavigationBarTitle = false
                } else {
                    hideNavigationBarTitle = true
                }

                navigationItem.titleView?.isHidden = hideNavigationBarTitle
            }
        }
    }

    func editControllerSetNavigationItemTitle(with title: String?) {
        var newTitle = title

        if title == nil {
            if let controller = navigationController?.viewControllers.last as? AudioViewController {
                controller.resetTitleView()
                return
            } else if let controller = navigationController?.viewControllers.last as? ArtistViewController {
                controller.resetTitleView()
                return
            } else if let controller = navigationController?.viewControllers.last as? PlaylistViewController {
                controller.resetTitleView()
                return
            } else if let controller = navigationController?.viewControllers.last as? VideoViewController {
                controller.resetTitleView()
                return
            } else if let controller = navigationController?.viewControllers.last as? CollectionCategoryViewController,
                      let model = controller.model as? CollectionModel,
                      let collection = model.mediaCollection as? VLCMLAlbum {
                newTitle = collection.title
            } else if let controller = navigationController?.viewControllers.last as? CollectionCategoryViewController,
                      let model = controller.model as? CollectionModel,
                      let collection = model.mediaCollection as? VLCMLGenre {
                newTitle = collection.title()
            } else if let controller = navigationController?.viewControllers.last as? CollectionCategoryViewController,
                      let model = controller.model as? CollectionModel,
                      let collection = model.mediaCollection as? VLCMLPlaylist {
                newTitle = collection.title()
            } else if let controller = navigationController?.viewControllers.last as? CollectionCategoryViewController,
                      let model = controller.model as? CollectionModel,
                      let collection = model.mediaCollection as? VLCMLMediaGroup {
                newTitle = collection.title()
            }
        }

        navItemTitle.text = newTitle
        navigationController?.viewControllers.last?.navigationItem.titleView = navItemTitle
        navigationController?.viewControllers.last?.navigationItem.titleView?.sizeToFit()
    }

    func editControllerUpdateIsAllSelected(with allSelected: Bool) {
        isAllSelected = allSelected
        delegate?.updateSelectAllButton(for: self)
    }
}

private extension MediaCategoryViewController {
    func setupCollectionView() {
        collectionView.register(AlbumHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: AlbumHeader.headerID)
        collectionView.register(PlaylistHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PlaylistHeader.headerID)

        if model.cellType.nibName == mediaGridCellNibIdentifier {
            //GridCells are made programmatically so we register the cell class directly.
            collectionView?.register(MediaGridCollectionCell.self,
                                     forCellWithReuseIdentifier: model.cellType.defaultReuseIdentifier)
        } else {
            //MediaCollectionCells are created via xibs so we register the cell via UINib.
            let cellNib = UINib(nibName: model.cellType.nibName, bundle: nil)
            collectionView?.register(cellNib,
                                     forCellWithReuseIdentifier: model.cellType.defaultReuseIdentifier)
        }
        collectionView.allowsMultipleSelection = true
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
        collectionView?.alwaysBounceVertical = true
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(gesture:)))
        longPressGesture.minimumPressDuration = 0.2
        collectionView?.addGestureRecognizer(longPressGesture)
        collectionView?.contentInsetAdjustmentBehavior = .always
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

// MARK: - MediaLibraryBaseModelObserver

extension MediaCategoryViewController: MediaLibraryBaseModelObserver {
    func mediaLibraryBaseModelReloadView() {
        reloadData()
    }
}

// MARK: - Player

extension MediaCategoryViewController {
    func play(media: VLCMLMedia, at indexPath: IndexPath) {
        let playbackController = PlaybackService.sharedInstance()
        var autoPlayNextItem: Bool = userDefaults.bool(forKey: kVLCAutomaticallyPlayNextItem)

        playbackController.fullscreenSessionRequested = media.type() != .audio

        if let model = model as? CollectionModel,
           model.mediaCollection is VLCMLPlaylist {
            autoPlayNextItem = userDefaults.bool(forKey: kVLCPlaylistPlayNextItem)
        }

        if !autoPlayNextItem {
            playbackController.play(media)
            return
        }

        var tracks = [VLCMLMedia]()
        var index = indexPath.row

        if let mediaGroupModel = model as? MediaGroupViewModel {
            mediaGroupModel.fileArrayQueue.sync {
                var singleGroup = [VLCMLMediaGroup]()

                if searchDataSource.isSearching,
                   let dataSet = currentDataSet as? [VLCMLMediaGroup] {
                    singleGroup = dataSet
                } else {
                    singleGroup = mediaGroupModel.files
                }

                // Filter single groups
                singleGroup = singleGroup.filter() {
                    return $0.nbTotalMedia() == 1 && !$0.userInteracted()
                }

                singleGroup.forEach() {
                    guard let media = $0.media(of: .unknown)?.first else {
                        assertionFailure("MediaCategoryViewController: play: Failed to fetch media.")
                        return
                    }
                    tracks.append(media)
                }
                index = tracks.firstIndex(where: { $0.identifier() == media.identifier() }) ?? 0
            }
        } else if let model = model as? MediaCollectionModel {
            tracks = model.files() ?? []
        } else {
            tracks = currentDataSet as? [VLCMLMedia] ?? []
        }
        playbackController.playMedia(at: index, fromCollection: tracks)
    }

    func saveCurrentPlaylistInfo(with playlistId: Int64?, playlistTitle: String?, media: VLCMLMedia?) {
        guard let media = media, let playlistId = playlistId, let playlistTitle = playlistTitle else {
            return
        }

        let lastMedia = LastPlayed(identifier: media.identifier(), title: media.title)
        let playlistInfo = LastPlayedPlaylistModel(identifier: playlistId, title: playlistTitle, lastPlayedMedia: lastMedia)
        userDefaults.setValue(NSKeyedArchiver.archivedData(withRootObject: playlistInfo), forKey: kVLCLastPlayedPlaylist)
    }

    private func addPlaybackWillStopObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playlistPlaybackWillStop(_:)),
                                               name: NSNotification.Name(rawValue: VLCPlaybackServicePlaybackWillStop),
                                               object: nil)
    }

    @objc func playlistPlaybackWillStop(_ notification: NSNotification) {
        // Checking playlist info existed in queue dictionary, this handling indicating last media when playing action is done through queue options[appendToQueue, playNextAtQueue]
        if let lastPlayed = notification.userInfo?[VLCLastPlaylistPlayedMedia] as? VLCMLMedia {
            let currentPlaylistMediaQueue = playbackCache.getCurrentPlaylistMediasQueue()
            if let queueLastPlaylist = currentPlaylistMediaQueue[lastPlayed.identifier()] {
                saveCurrentPlaylistInfo(with: queueLastPlaylist.identifier, playlistTitle: queueLastPlaylist.title, media: lastPlayed)
            } else if let lastPlaylist = lastPlaylist {
                saveCurrentPlaylistInfo(with: lastPlaylist.identifier, playlistTitle: lastPlaylist.title, media: lastPlayed)
            }
        }

        reloadData()
        removePlaybackWillStopObserver()
        userDefaults.setValue(false, forKey: kVLCIsCurrentlyPlayingPlaylist)
        playbackCache.clearQueuePlaylistInfo()
    }

    private func removePlaybackWillStopObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: VLCPlaybackServicePlaybackWillStop),
                                                  object: nil
        )
    }

    private func cachePlaylistInfoFromPlayerQueue(for contentModel: VLCMLObject) {
        if let playlists = currentDataSet as? [VLCMLPlaylist], let model = contentModel as? VLCMLPlaylist {
            guard let index = playlists.firstIndex(where: {
                $0.identifier() == model.identifier() && $0.title() == model.title()
            }) else {
                return
            }

            let selectedPlaylist = playlists[index]
            guard let medias = selectedPlaylist.media else {
                return
            }

            let playlistInfo = LastPlayed(identifier: selectedPlaylist.identifier(), title: selectedPlaylist.title())
            playbackCache.appendCurrentlyPlayingPlaylistInfoQueue(medias: medias, playlistInfo)
        } else if let media = contentModel as? VLCMLMedia,
                  let collection = model as? CollectionModel,
                  let playlist = collection.mediaCollection as? VLCMLPlaylist {

            let playlistInfo = LastPlayed(identifier: playlist.identifier(), title: playlist.title())
            playbackCache.appendCurrentlyPlayingMediaInfoQueue(media: media, playlistInfo)
        }
    }
}

// MARK: - MediaCollectionViewCellDelegate

extension MediaCategoryViewController: MediaCollectionViewCellDelegate {
    func mediaCollectionViewCellHandleDelete(of cell: MediaCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
              let modelContent = currentDataSet.objectAtIndex(index: indexPath.row) else {
            return
        }

        editController.editActions.objects = [modelContent]
        editController.editActions.delete() { [weak self] state in
            if state == .success {
                self?.searchDataSource.deleteInSearch(index: indexPath.row)

                // If the media deleted is in the media list, the play queue should also be updated
                let playbackService = PlaybackService.sharedInstance()
                guard playbackService.playerIsSetup,
                      let mlMediaUrl = (modelContent as? VLCMLMedia)?.mainFile()?.mrl,
                      playbackService.mediaListContains(mlMediaUrl) else {
                    return
                }

                playbackService.removeMediaFromMediaList(at: UInt(indexPath.row))
            }
        }
    }

    func mediaCollectionViewCellMediaTapped(in cell: MediaCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }

        selectedItem(at: indexPath)
        collectionView.reloadData()
    }

    func mediaCollectionViewCellSetScrolledCellIndex(of cell: MediaCollectionViewCell?) {
        if let cell = cell {
            guard let indexPath = collectionView.indexPath(for: cell) else {
                return
            }

            scrolledCellIndex = indexPath
        }
    }

    func mediaCollectionViewCellGetScrolledCell() -> MediaCollectionViewCell? {
        if scrolledCellIndex.isEmpty {
            return nil
        }

        let cell = collectionView.cellForItem(at: scrolledCellIndex)
        if let cell = cell as? MediaCollectionViewCell {
            return cell
        }

        return nil
    }

    func mediaCollectionViewCellGetModel() -> MediaLibraryBaseModel? {
        return model
    }

    private func resetScrollView() {
        if let mediaCell = mediaCollectionViewCellGetScrolledCell() {
            mediaCell.resetScrollView()
        }
    }
}

// MARK: - Continue Watching Last Media Button

extension MediaCategoryViewController {
    private func configureContinueWatchingButton() {
        if let model = model as? CollectionModel, model.mediaCollection is VLCMLMediaGroup {
            addContinueWatchingButton()
        } else if model is MediaGroupViewModel {
            addContinueWatchingButton()
        }
    }

    private func addContinueWatchingButton() {
        guard let keyWindow = UIApplication.shared.delegate?.window else { return }
        keyWindow?.addSubview(continueWatchingButton)

        setContinueWatchingButtonConstraints()
        handleContinueWatchingButtonVisibility()
    }

    @objc private func continueWatchingButtonPressed() {
        let playbackService = PlaybackService.sharedInstance()
        if let lastMedia = mediaLibraryService.medialib.videoHistory()?.first {
            playbackService.play(lastMedia)
        }
    }

    private func handleContinueWatchingButtonVisibility() {
        continueWatchingButton.isHidden = shouldHideContinueWatchingButton()
    }

    private func shouldHideContinueWatchingButton() -> Bool {
        if PlaybackService.sharedInstance().playerDisplayController.isMiniPlayerVisible {
            return true
        }

        if let historyCount = mediaLibraryService.medialib.videoHistory()?.count, historyCount == 0 {
            return true
        }

        if isEditing || searchDataSource.isSearching {
            return true
        }

        return false
    }

    private func setContinueWatchingButtonConstraints() {
        guard let keywindow = UIApplication.shared.delegate?.window else { return }
        guard var layoutGuide = keywindow?.layoutMarginsGuide else { return }

        if #available(iOS 11.0, *) {
            layoutGuide = keywindow!.safeAreaLayoutGuide
        }

        var tabBarHeight: CGFloat = 0.0
        if let tabBarController = tabBarController as? BottomTabBarController,
           let tabBarHeightConstraint = tabBarController.tabBarHeightConstraint {
            tabBarHeight = tabBarHeightConstraint.constant
        } else if let tabBarController = tabBarController {
            tabBarHeight = tabBarController.tabBar.frame.size.height
        }
        continueWatchingBottomConstraint = continueWatchingButton.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -tabBarHeight)

        NSLayoutConstraint.activate([
            continueWatchingButton.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -15),
            continueWatchingBottomConstraint!,
            continueWatchingButton.widthAnchor.constraint(equalToConstant: 60),
            continueWatchingButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    //Helper functions for handling constraints when orientation state is changed
    private func updateContinueWatchingConstraints() {
        DispatchQueue.main.async {
            var tabBarHeight: CGFloat = 0.0
            if let tabBarController = self.tabBarController as? BottomTabBarController,
               let tabBarHeightConstraint = tabBarController.tabBarHeightConstraint {
                tabBarHeight = tabBarHeightConstraint.constant
            } else if let tabBarController = self.tabBarController {
                tabBarHeight = tabBarController.tabBar.frame.size.height
            }

            self.continueWatchingBottomConstraint?.constant = -tabBarHeight
            self.continueWatchingButton.layoutIfNeeded()
        }
    }
}
