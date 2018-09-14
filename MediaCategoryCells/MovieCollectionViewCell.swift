/*****************************************************************************
 * MovieCollectionViewCell.swift
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

class MovieCollectionViewCell: BaseCollectionViewCell {

    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var newLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    override class var cellPadding: CGFloat {
        return 5.0
    }

    override var media: VLCMLObject? {
        didSet {
            guard let movie = media as? VLCMLMedia else {
                fatalError("needs to be of Type VLCMLMovie")
            }
            update(movie:movie)
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

    func update(movie: VLCMLMedia) {
        titleLabel.text = movie.title
        descriptionLabel.text = movie.mediaDuration()
        if movie.isThumbnailGenerated() {
            thumbnailView.image = UIImage(contentsOfFile: movie.thumbnail.absoluteString)
        }
        let progress = movie.mediaProgress()
        progressView.isHidden = progress == 0
        progressView.progress = progress
        newLabel.isHidden = !movie.isNew()
    }

    override class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        let numberOfCells: CGFloat = round(width / 250)
        let aspectRatio: CGFloat = 10.0 / 16.0

        // We have the number of cells and we always have numberofCells + 1 padding spaces. -pad-[Cell]-pad-[Cell]-pad-
        // we then have the entire padding, we divide the entire padding by the number of Cells to know how much needs to be substracted from ech cell
        // since this might be an uneven number we ceil
        var cellWidth = width / numberOfCells
        cellWidth = cellWidth - ceil(((numberOfCells + 1) * cellPadding) / numberOfCells)

        // 3*20 for the labels + 24 for 3*8 which is the padding
        return CGSize(width: cellWidth, height: cellWidth * aspectRatio + 3*20+24)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        descriptionLabel.text = ""
        thumbnailView.image = nil
        progressView.isHidden = true
        newLabel.isHidden = true
    }
}
