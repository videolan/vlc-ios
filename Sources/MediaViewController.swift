/*****************************************************************************
 * MediaViewController.swift
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

@objc public protocol VLCMediaViewControllerDelegate: class {
    func mediaViewControllerDidSelectMediaObject(_ mediaViewController: VLCMediaViewController, mediaObject: NSManagedObject)
}

public class VLCMediaViewController: UICollectionViewController, UISearchResultsUpdating, UISearchControllerDelegate, IndicatorInfoProvider {
    private var services: Services
    private var mediaDataSourceAndDelegate: MediaDataSourceAndDelegate?
    private var searchController: UISearchController?
    private let searchDataSource = VLCLibrarySearchDisplayDataSource()
    private var mediaType: VLCMediaType

    public weak var delegate: VLCMediaViewControllerDelegate?

    @available(iOS 11.0, *)
    lazy var dragAndDropManager: VLCDragAndDropManager = {
        let dragAndDropManager = VLCDragAndDropManager(type: mediaType)
        dragAndDropManager.delegate = services.mediaDataSource
        return dragAndDropManager
    }()

    lazy var emptyView: VLCEmptyLibraryView = {
        let name = String(describing: VLCEmptyLibraryView.self)
        let nib = Bundle.main.loadNibNamed(name, owner: self, options: nil)
        guard let emptyView = nib?.first as? VLCEmptyLibraryView else { fatalError("Can't find nib for \(name)") }
        return emptyView
    }()

    @available(*, unavailable)
    init() {
        fatalError()
    }

    init(services: Services, type: VLCMediaType) {
        self.services = services
        mediaType = type

        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
        if mediaType.category == .video {
            NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .VLCAllVideosDidChangeNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .VLCTracksDidChangeNotification, object: nil)
        }
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    @objc func reloadData() {
        collectionView?.reloadData()
        updateUIForContent()
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder: ) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSearchController()
        _ = (MLMediaLibrary.sharedMediaLibrary() as! MLMediaLibrary).libraryDidAppear()
    }

    public override func viewWillAppear(_ animated: Bool) {
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
        mediaDataSourceAndDelegate = MediaDataSourceAndDelegate(services: services, type: mediaType)
        mediaDataSourceAndDelegate?.delegate = self
        let playlistnib = UINib(nibName: "VLCPlaylistCollectionViewCell", bundle: nil)
        collectionView?.register(playlistnib, forCellWithReuseIdentifier: VLCPlaylistCollectionViewCell.cellIdentifier())
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
        collectionView?.alwaysBounceVertical = true
        collectionView?.dataSource = mediaDataSourceAndDelegate
        collectionView?.delegate = mediaDataSourceAndDelegate
        if #available(iOS 11.0, *) {
            collectionView?.dragDelegate = dragAndDropManager
            collectionView?.dropDelegate = dragAndDropManager
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
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

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    // MARK: - MediaDatasourceAndDelegate

    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let mediaObject = services.mediaDataSource.object(at: indexPath.row, subcategory: mediaType.subcategory) as? NSManagedObject {
            delegate?.mediaViewControllerDidSelectMediaObject(self, mediaObject: mediaObject)
        }
    }

    // MARK: - Search

    public func updateSearchResults(for searchController: UISearchController) {
        searchDataSource.shouldReloadTable(forSearch: searchController.searchBar.text, searchableFiles: services.mediaDataSource.allObjects(for: mediaType.subcategory))
        collectionView?.reloadData()
    }

    public func didPresentSearchController(_ searchController: UISearchController) {
        collectionView?.dataSource = searchDataSource
    }

    public func didDismissSearchController(_ searchController: UISearchController) {
        collectionView?.dataSource = mediaDataSourceAndDelegate
    }

    public func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return  services.mediaDataSource.indicatorInfo(for:mediaType.subcategory)
    }
}
