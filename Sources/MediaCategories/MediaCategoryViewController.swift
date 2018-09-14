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

class VLCMediaCategoryViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, UISearchControllerDelegate, IndicatorInfoProvider {
    
    private var services: Services
    private var searchController: UISearchController?
    private let searchDataSource = VLCLibrarySearchDisplayDataSource()
    var category: MediaLibraryBaseModel
    private lazy var editController = VLCEditController(collectionView: self.collectionView!, category: self.category)
    private var cachedCellSize = CGSize.zero

//    @available(iOS 11.0, *)
//    lazy var dragAndDropManager: VLCDragAndDropManager = { () -> VLCDragAndDropManager<T> in
//        VLCDragAndDropManager<T>(subcategory: VLCMediaSubcategories<>)
//    }()

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

    init(services: Services, category: MediaLibraryBaseModel) {
        self.services = services
        self.category = category
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    @objc func reloadData() {
        DispatchQueue.main.async {
            [weak self] in
            self?.collectionView?.reloadData()
            self?.updateUIForContent()
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder: ) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSearchController()
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
    }

    @objc func themeDidChange() {
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
        setNeedsStatusBarAppearanceUpdate()
    }

    func setupCollectionView() {
        let cellNib = UINib(nibName: category.cellType.nibName, bundle: nil)
        collectionView?.register(cellNib, forCellWithReuseIdentifier: category.cellType.defaultReuseIdentifier)
        collectionView?.register(VLCMediaViewEditCell.self, forCellWithReuseIdentifier: VLCMediaViewEditCell.identifier)
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
        collectionView?.alwaysBounceVertical = true
        if #available(iOS 11.0, *) {
//            collectionView?.dragDelegate = dragAndDropManager
//            collectionView?.dropDelegate = dragAndDropManager
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadData()
    }

    func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.delegate = self
        if let textfield = searchController?.searchBar.value(forKey: "searchField") as? UITextField {
            if let backgroundview = textfield.subviews.first {
                backgroundview.backgroundColor = UIColor.white
                backgroundview.layer.cornerRadius = 10
                backgroundview.clipsToBounds = true
            }
        }
    }
    
    func updateUIForContent() {
        let isEmpty = collectionView?.numberOfItems(inSection: 0) == 0

        if isEmpty {
            collectionView?.setContentOffset(.zero, animated: false)
        }
        collectionView?.backgroundView = isEmpty ? emptyView : nil
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = isEmpty ? nil : searchController
        } else {
            navigationItem.titleView = isEmpty ? nil : searchController?.searchBar
        }
    }

    // MARK: Renderer

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Edit

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        // might have an issue if the old datasource was search
        // Most of the edit logic is handled inside editController
        collectionView?.dataSource = editing ? editController : self
        collectionView?.delegate = editing ? editController : self

        editController.toolbarNeedsUpdate(editing: editing)

        let layoutToBe = editing ? editCollectionViewLayout : UICollectionViewFlowLayout()
        collectionView?.setCollectionViewLayout(layoutToBe, animated: false, completion: {
            [weak self] finished in
            guard finished else {
                assertionFailure("VLCMediaSubcategoryViewController: Edit layout transition failed.")
                return
            }
            self?.reloadData()
        })
    }

    // MARK: - Search

    func updateSearchResults(for searchController: UISearchController) {
        searchDataSource.shouldReloadTable(forSearch: searchController.searchBar.text, searchableFiles: category.anyfiles)
        collectionView?.reloadData()
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        collectionView?.dataSource = searchDataSource
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        collectionView?.dataSource = self
    }

    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title:category.indicatorName)
    }

    // MARK: - UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return category.anyfiles.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier:category.cellType.defaultReuseIdentifier, for: indexPath) as? BaseCollectionViewCell else {
            assertionFailure("you forgot to register the cell or the cell is not a subclass of BaseCollectionViewCell")
            return UICollectionViewCell()
        }
        let mediaObject = category.anyfiles[indexPath.row]
        if let media = mediaObject as? VLCMLMedia {
            assert(media.mainFile() != nil, "The mainfile is nil")
            mediaCell.media = media.mainFile() != nil ? media : nil
        } else {
            mediaCell.media = mediaObject
            assertionFailure("The contained file in the category doesn't conform to VLCMLMedia")
        }
        return mediaCell
    }

    // MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let media = category.anyfiles[indexPath.row] as? VLCMLMedia {
            play(media: media)
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if cachedCellSize == .zero {
            cachedCellSize = category.cellType.cellSizeForWidth(collectionView.frame.size.width)
        }
        return cachedCellSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: category.cellType.cellPadding, left: category.cellType.cellPadding, bottom: category.cellType.cellPadding, right: category.cellType.cellPadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return category.cellType.cellPadding
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return category.cellType.cellPadding
    }
}

// MARK: - Sort

extension VLCMediaCategoryViewController {
    // FIXME: Need to add a button for ascending/descending result
    func sortByFileName() {
        // The issue is that for audio we show title which is quite confusing if we use filename
        category.sort(by: .alpha)
    }

    func sortByDate() {
        category.sort(by: .insertionDate)
    }

    func sortBySize() {
        category.sort(by: .fileSize)
    }
}

// MARK: - Player

extension VLCMediaCategoryViewController {
    func play(mediaObject: NSManagedObject) {
        VLCPlaybackController.sharedInstance().playMediaLibraryObject(mediaObject)
    }

    func play(media: VLCMLMedia) {
        VLCPlaybackController.sharedInstance().play(media)
    }
}

// MARK: - MediaLibraryModelView

extension VLCMediaCategoryViewController {
    func dataChanged() {
        reloadData()
    }
}
