//
//  VideoViewController.swift
//  VLC-iOS
//
//  Created by Carola Nitz on 11/28/17.
//  Copyright © 2017 VideoLAN. All rights reserved.
//

import Foundation


public protocol VLCVideoControllerDelegate: class {
    func videoViewControllerDidSelectMediaObject(VLCVideoViewController: VLCVideoViewController, mediaObject:NSManagedObject)
}

public class VLCVideoViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout
{
    private var mediaDataSource: VLCMediaDataSource
    private let cellPadding:CGFloat = 5.0
    public weak var delegate: VLCVideoControllerDelegate?

    @available(iOS 11.0, *)
    lazy var dragAndDropManager:VLCDragAndDropManager = {
        let dragAndDropManager = VLCDragAndDropManager()
        dragAndDropManager.delegate = mediaDataSource
        return dragAndDropManager
    }()

    public convenience init(mediaDataSource:VLCMediaDataSource) {
        self.init(collectionViewLayout: UICollectionViewFlowLayout())
        self.mediaDataSource = mediaDataSource
    }

    public override init(collectionViewLayout layout: UICollectionViewLayout) {
        self.mediaDataSource = VLCMediaDataSource()
        super.init(collectionViewLayout: layout)
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {

        setupCollectionView()
        setupNavigationbar()

        _ = (MLMediaLibrary.sharedMediaLibrary() as AnyObject).perform(#selector(MLMediaLibrary.libraryDidAppear))
        mediaDataSource.updateContents(forSelection: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.mediaDataSource.addAllFolders()
            self.mediaDataSource.addRemainingFiles()
            self.collectionView?.reloadData()
        }
    }

    func setupCollectionView(){
        let playlistnib = UINib(nibName: "VLCPlaylistCollectionViewCell", bundle:nil)
        collectionView?.register(playlistnib, forCellWithReuseIdentifier: VLCPlaylistCollectionViewCell.cellIdentifier())
        collectionView?.backgroundColor = .white
        if #available(iOS 11.0, *) {
            collectionView?.dragDelegate = dragAndDropManager
            collectionView?.dropDelegate = dragAndDropManager
        }
    }

    func setupNavigationbar() {
        title = "Videos"
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
            let attributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
            navigationController?.navigationBar.largeTitleTextAttributes = attributes
        }
        self.navigationItem.leftBarButtonItem  = UIBarButtonItem.themedRevealMenuButton(withTarget: self, andSelector: #selector(revealMenu))
    }

    @objc func revealMenu() {
        VLCSidebarController.sharedInstance().toggleSidebar()
    }

    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(Int(mediaDataSource.numberOfFiles()))
        return Int(mediaDataSource.numberOfFiles())
    }

    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.videoViewControllerDidSelectMediaObject(VLCVideoViewController: self, mediaObject:mediaDataSource.object(at: UInt(indexPath.row)))
    }

    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let playlistCell = collectionView.dequeueReusableCell(withReuseIdentifier: VLCPlaylistCollectionViewCell.cellIdentifier(), for: indexPath) as? VLCPlaylistCollectionViewCell {
            playlistCell.mediaObject = mediaDataSource.object(at: UInt(indexPath.row))
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
}
