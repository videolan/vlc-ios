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
    let cellPadding: CGFloat = 5.0
    private var services: Services
    private var searchController: UISearchController?
    private let searchDataSource = VLCLibrarySearchDisplayDataSource()
    var category: MediaLibraryBaseModel

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
        let playlistnib = UINib(nibName: "VLCPlaylistCollectionViewCell", bundle: nil)
        collectionView?.register(playlistnib, forCellWithReuseIdentifier: VLCPlaylistCollectionViewCell.cellIdentifier())
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

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
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
        if let playlistCell = collectionView.dequeueReusableCell(withReuseIdentifier: VLCPlaylistCollectionViewCell.cellIdentifier(), for: indexPath) as? VLCPlaylistCollectionViewCell {
            if let mediaObject = category.anyfiles[indexPath.row] as? NSManagedObject {
                playlistCell.mediaObject = mediaObject
            }

            if let media = category.anyfiles[indexPath.row] as? VLCMLMedia {
                playlistCell.media = media
                if media.mainFile() == nil {
                    playlistCell.media = nil
                }
            }
            return playlistCell
        }
        return UICollectionViewCell()
    }

    // MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let mediaObject = category.anyfiles[indexPath.row] as? NSManagedObject {
            play(mediaObject: mediaObject)
        } else if let media = category.anyfiles[indexPath.row] as? VLCMLMedia {
            play(media: media)
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        if isEditing {
            let contentInset = collectionView.contentInset
            let insetToRemove = contentInset.left + contentInset.right + (cellPadding * 2)
            return CGSize(width: collectionView.frame.width - insetToRemove, height: VLCMediaViewEditCell.height)
        }

        let numberOfCells: CGFloat = collectionView.traitCollection.horizontalSizeClass == .regular ? 3.0 : 2.0
        let aspectRatio: CGFloat = 10.0 / 16.0

        // We have the number of cells and we always have numberofCells + 1 padding spaces. -pad-[Cell]-pad-[Cell]-pad-
        // we then have the entire padding, we divide the entire padding by the number of Cells to know how much needs to be substracted from ech cell
        // since this might be an uneven number we ceil
        var cellWidth = collectionView.bounds.size.width / numberOfCells
        cellWidth = cellWidth - ceil(((numberOfCells + 1) * cellPadding) / numberOfCells)

        return CGSize(width: cellWidth, height: cellWidth * aspectRatio)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: cellPadding, left: cellPadding, bottom: cellPadding, right: cellPadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
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
