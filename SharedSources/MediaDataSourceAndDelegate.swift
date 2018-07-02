/*****************************************************************************
 * MediaDataSourceAndDelegate.swift
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
extension Notification.Name {
    static let VLCTracksDidChangeNotification = Notification.Name("kTracksDidChangeNotification")
    static let VLCAllVideosDidChangeNotification = Notification.Name("kAllVideosDidChangeNotification")
}

class MediaDataSourceAndDelegate: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let cellPadding: CGFloat = 5.0
    private var services: Services
    private var mediaType: VLCMediaType
    weak var delegate: UICollectionViewDelegate?

    @available(*, unavailable)
    override init() {
        fatalError()
    }

    init(services: Services, type: VLCMediaType) {
        self.services = services
        mediaType = type
        super.init()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(services.mediaDataSource.numberOfFiles(subcategory: mediaType.subcategory))
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let playlistCell = collectionView.dequeueReusableCell(withReuseIdentifier: VLCPlaylistCollectionViewCell.cellIdentifier(), for: indexPath) as? VLCPlaylistCollectionViewCell {
            if let mediaObject = services.mediaDataSource.object(at: indexPath.row, subcategory: mediaType.subcategory) as? NSManagedObject {
                playlistCell.mediaObject = mediaObject
            }
            return playlistCell
        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.collectionView!(collectionView, didSelectItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

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
