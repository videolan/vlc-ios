//
//  VideoViewController.swift
//  VLC-iOS
//
//  Created by Carola Nitz on 11/28/17.
//  Copyright © 2017 VideoLAN. All rights reserved.
//

import Foundation

@objc public protocol VLCMediaViewControllerDelegate: class {
    func videoViewControllerDidSelectMediaObject(VLCMediaViewController: VLCMediaViewController, mediaObject:NSManagedObject)
    func videoViewControllerDidSelectSort(VLCMediaViewController: VLCMediaViewController)
}

public class VLCMediaViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, UISearchControllerDelegate
{
    private var services: Services
    private let cellPadding:CGFloat = 5.0
    private var searchController: UISearchController?
    private let searchDataSource = VLCLibrarySearchDisplayDataSource()
    public weak var delegate: VLCMediaViewControllerDelegate?

    @available(iOS 11.0, *)
    lazy var dragAndDropManager:VLCDragAndDropManager = {
        let dragAndDropManager = VLCDragAndDropManager()
        dragAndDropManager.delegate = services.mediaDataSource
        return dragAndDropManager
    }()

    public convenience init(services:Services) {
        self.init(collectionViewLayout: UICollectionViewFlowLayout())
        self.services = services
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: VLCThemeDidChangeNotification, object: nil)
    }

    public override init(collectionViewLayout layout: UICollectionViewLayout) {
        self.services = Services()
        super.init(collectionViewLayout: layout)
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {

        setupCollectionView()
        setupSearchController()
        setupNavigationBar()
        _ = (MLMediaLibrary.sharedMediaLibrary() as AnyObject).perform(#selector(MLMediaLibrary.libraryDidAppear))
        services.mediaDataSource.updateContents(forSelection: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.services.mediaDataSource.addAllFolders()
            self.services.mediaDataSource.addRemainingFiles()
            self.collectionView?.reloadData()
        }
    }

    @objc func themeDidChange() {
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
    }

    func setupCollectionView(){
        let playlistnib = UINib(nibName: "VLCPlaylistCollectionViewCell", bundle:nil)
        collectionView?.register(playlistnib, forCellWithReuseIdentifier: VLCPlaylistCollectionViewCell.cellIdentifier())
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
        collectionView?.alwaysBounceVertical = true
        if #available(iOS 11.0, *) {
            collectionView?.dragDelegate = dragAndDropManager
            collectionView?.dropDelegate = dragAndDropManager
        }
    }

    func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.delegate = self
        if let textfield = searchController?.searchBar.value(forKey: "searchField") as? UITextField {
            if let backgroundview = textfield.subviews.first {
                backgroundview.backgroundColor = UIColor.white
                backgroundview.layer.cornerRadius = 10;
                backgroundview.clipsToBounds = true;
            }
        }
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            navigationItem.titleView = searchController?.searchBar
            searchController?.hidesNavigationBarDuringPresentation = false
        }
    }

    func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Sort", comment: ""), style: .plain, target: self, action: #selector(sort))
    }

    @objc func sort() {
        delegate?.videoViewControllerDidSelectSort(VLCMediaViewController: self)
    }
    //MARK: - CollectionViewDelegate & DataSource
    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(services.mediaDataSource.numberOfFiles())
    }

    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.videoViewControllerDidSelectMediaObject(VLCMediaViewController: self, mediaObject:services.mediaDataSource.object(at: UInt(indexPath.row)))
    }

    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let playlistCell = collectionView.dequeueReusableCell(withReuseIdentifier: VLCPlaylistCollectionViewCell.cellIdentifier(), for: indexPath) as? VLCPlaylistCollectionViewCell {
            playlistCell.mediaObject = services.mediaDataSource.object(at: UInt(indexPath.row))
            return playlistCell
        }
        return UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let numberofCells:CGFloat =  self.traitCollection.horizontalSizeClass == .regular ? 3.0 : 2.0
        let aspectRatio:CGFloat = 10.0 / 16.0

        var cellWidth = view.bounds.size.width / numberofCells
        cellWidth = cellWidth - ceil(((numberofCells + 1) * cellPadding) / numberofCells)

        return CGSize(width:cellWidth, height:cellWidth * aspectRatio)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(cellPadding, cellPadding, cellPadding, cellPadding);
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    //MARK: - Search
    public func updateSearchResults(for searchController: UISearchController) {
        searchDataSource.shouldReloadTable(forSearch: searchController.searchBar.text, searchableFiles: services.mediaDataSource.allObjects())
        collectionView?.reloadData()
    }

    public func didPresentSearchController(_ searchController: UISearchController) {
        collectionView?.dataSource = searchDataSource
    }

    public func didDismissSearchController(_ searchController: UISearchController) {
        collectionView?.dataSource = self
    }
}
