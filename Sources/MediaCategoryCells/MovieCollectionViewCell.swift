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
    @IBOutlet weak var collectionOverlay: UIView!
    @IBOutlet weak var numberOfTracks: UILabel!
    override class var edgePadding: CGFloat {
        return 12.5
    }
    override class var interItemPadding: CGFloat {
        return 7.5
    }

    override var media: VLCMLObject? {
        didSet {
            if let movie = media as? VLCMLMedia {
                update(movie:movie)
            } else if let playlist = media as? VLCMLPlaylist {
                update(playlist:playlist)
            } else {
                fatalError("wrong object")
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 11.0, *) {
            thumbnailView.accessibilityIgnoresInvertColors = true
        }
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
        var title = movie.title
        if UserDefaults.standard.bool(forKey: kVLCOptimizeItemNamesForDisplay) == true {
            title = (title as NSString).deletingPathExtension
        }
        titleLabel.text = title
        accessibilityLabel = movie.accessibilityText(editing: false)
        descriptionLabel.text = movie.mediaDuration()
        thumbnailView.image = movie.thumbnailImage()
        let progress = movie.progress
        progressView.isHidden = progress == 0
        progressView.progress = progress
        newLabel.isHidden = !movie.isNew
    }

    func update(playlist: VLCMLPlaylist) {
        collectionOverlay.isHidden = false
        numberOfTracks.text = String(playlist.media?.count ?? 0)
        titleLabel.text = playlist.name
        accessibilityLabel = playlist.accessibilityText()
        descriptionLabel.text = playlist.numberOfTracksString()
        thumbnailView.image = playlist.thumbnail()
    }

    override class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        let numberOfCells: CGFloat
        if width <= DeviceWidth.iPhonePortrait.rawValue {
            numberOfCells = 2
        } else if width <= DeviceWidth.iPhoneLandscape.rawValue {
            numberOfCells = 3
        } else if width <= DeviceWidth.iPadLandscape.rawValue {
            numberOfCells = 4
        } else {
            numberOfCells = 5
        }
        let aspectRatio: CGFloat = 10.0 / 16.0

        // We have the number of cells and we always have numberofCells + 1 interItemPadding spaces.
        //
        // edgePadding-interItemPadding-[Cell]-interItemPadding-[Cell]-interItemPadding-edgePadding
        //

        let overallWidth = width - (2 * edgePadding)
        let overallCellWidthWithoutPadding = overallWidth - (numberOfCells + 1) * interItemPadding
        let cellWidth = floor(overallCellWidthWithoutPadding / numberOfCells)

        // 17 * 2 for title, 14 for new + duration, 3 * 4 paddings for lines
        return CGSize(width: cellWidth, height: cellWidth * aspectRatio + (17 * 2) + 14 + (3 * 4))
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        descriptionLabel.text = ""
        thumbnailView.image = nil
        progressView.isHidden = true
        newLabel.isHidden = true
        collectionOverlay.isHidden = true
        numberOfTracks.text = ""
    }
}
