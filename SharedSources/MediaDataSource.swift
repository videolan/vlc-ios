/*****************************************************************************
 * MediaDataSource.swift
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

public class MediaDataSourceAndDelegate: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let cellPadding: CGFloat = 5.0
    private var services: Services
    public weak var delegate: UICollectionViewDelegate?

    public convenience init(services: Services) {
        self.init()
        self.services = services
    }

    public override init() {
        self.services = Services()
        super.init()
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numItems = Int(services.mediaDataSource.numberOfFiles())
        let hasMedia = numItems > 0
        collectionView.backgroundView?.isHidden = hasMedia
        return numItems
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let playlistCell = collectionView.dequeueReusableCell(withReuseIdentifier: VLCPlaylistCollectionViewCell.cellIdentifier(), for: indexPath) as? VLCPlaylistCollectionViewCell {
            playlistCell.mediaObject = services.mediaDataSource.object(at: UInt(indexPath.row))
            return playlistCell
        }
        return UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.collectionView!(collectionView, didSelectItemAt: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let numberOfCells: CGFloat = collectionView.traitCollection.horizontalSizeClass == .regular ? 3.0 : 2.0
        let aspectRatio: CGFloat = 10.0 / 16.0

        // We have the number of cells and we always have numberofCells + 1 padding spaces. -pad-[Cell]-pad-[Cell]-pad-
        // we then have the entire padding, we divide the entire padding by the number of Cells to know how much needs to be substracted from ech cell
        // since this might be an uneven number we ceil
        var cellWidth = collectionView.bounds.size.width / numberOfCells
        cellWidth = cellWidth - ceil(((numberOfCells + 1) * cellPadding) / numberOfCells)

        return CGSize(width:cellWidth, height:cellWidth * aspectRatio)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: cellPadding, left: cellPadding, bottom: cellPadding, right: cellPadding)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
    }
}
