/*****************************************************************************
 * AudioCollectionViewCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class AudioCollectionViewCell: BaseCollectionViewCell {

    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var newLabel: UILabel!
    override class var cellPadding: CGFloat {
        return 5.0
    }

    override var media: VLCMLObject? {
        didSet {
            if let albumTrack = media as? VLCMLMedia {
                update(audiotrack:albumTrack)
            } else if let album = media as? VLCMLAlbum {
                update(album:album)
            } else {
                fatalError("needs to be of Type VLCMLMedia or VLCMLAlbum")
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        newLabel.text = NSLocalizedString("NEW", comment: "")
        newLabel.textColor = PresentationTheme.current.colors.orangeUI
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
        themeDidChange()
    }

    @objc fileprivate func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        titleLabel?.textColor = PresentationTheme.current.colors.cellTextColor
        descriptionLabel?.textColor = PresentationTheme.current.colors.cellDetailTextColor
    }

    func update(audiotrack: VLCMLMedia) {
        thumbnailView.layer.cornerRadius = thumbnailView.frame.size.width / 2.0
        titleLabel.text = audiotrack.title
        descriptionLabel.text = audiotrack.albumTrack.artist.name
        if audiotrack.isThumbnailGenerated() {
            thumbnailView.image = UIImage(contentsOfFile: audiotrack.thumbnail.absoluteString)
        }
        newLabel.isHidden = !audiotrack.isNew()
    }

    func update(album: VLCMLAlbum) {
        titleLabel.text = album.title
        descriptionLabel.text = album.albumArtist.name
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
        descriptionLabel.text = ""
        thumbnailView.image = nil
        newLabel.isHidden = true
    }
}
