/*****************************************************************************
 * GenreCollectionViewCell.swift
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

class GenreCollectionViewCell: BaseCollectionViewCell {

    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var numberOfTracksLabel: UILabel!

    override var media: VLCMLObject? {
        didSet {
            guard let genre = media as? VLCMLGenre else {
                fatalError("needs to be of Type VLCMLGenre")
            }
            update(genre:genre)
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
        titleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        numberOfTracksLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
    }

    func update(genre: VLCMLGenre) {
        titleLabel.text = genre.name
        numberOfTracksLabel.text = genre.numberOfTracksString()
    }

    override class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        return CGSize(width: width, height: 50)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        numberOfTracksLabel.text = ""
        thumbnailView.image = nil
    }
}
