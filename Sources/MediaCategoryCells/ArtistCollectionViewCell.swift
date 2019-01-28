/*****************************************************************************
 * ArtistCollectionViewCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class ArtistCollectionViewCell: BaseCollectionViewCell {

    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    override class var cellPadding: CGFloat {
        return 5.0
    }

    override var media: VLCMLObject? {
        didSet {
            guard let artist = media as? VLCMLArtist else {
                fatalError("needs to be of Type VLCMLArtist")
            }
            update(artist:artist)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
        themeDidChange()
        thumbnailView.layer.cornerRadius = thumbnailView.frame.size.width / 2.0
    }

    @objc fileprivate func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        titleLabel?.textColor = PresentationTheme.current.colors.cellTextColor
    }

    func update(artist: VLCMLArtist) {
        titleLabel.text = artist.name
//        if artist.isThumbnailGenerated() {
//            thumbnailView.image = UIImage(contentsOfFile: artist.thumbnail.absoluteString)
//        }
    }

    override class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        let numberOfCells: CGFloat = round(width / 320)

        // We have the number of cells and we always have numberofCells + 1 padding spaces. -pad-[Cell]-pad-[Cell]-pad-
        // we then have the entire padding, we divide the entire padding by the number of Cells to know how much needs to be substracted from ech cell
        // since this might be an uneven number we ceil
        var cellWidth = width / numberOfCells
        cellWidth = cellWidth - ceil(((numberOfCells + 1) * cellPadding) / numberOfCells)

        return CGSize(width: cellWidth, height: 80)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        thumbnailView.image = nil
    }
}
