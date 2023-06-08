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
import UIKit

class MovieCollectionViewCell: BaseCollectionViewCell {
    @IBOutlet weak var checkboxImageView: UIImageView!

    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var newLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var sizeLabel: UILabel!

    @IBOutlet weak var selectionOverlay: UIView!

    @IBOutlet weak var mediaView: UIView!
    @IBOutlet weak var groupView: UIView!
    @IBOutlet weak var thumbnailsBackground: UIView!
    @IBOutlet weak var firstThumbnail: UIImageView!
    @IBOutlet weak var secondThumbnail: UIImageView!
    @IBOutlet weak var thirdThumbnail: UIImageView!
    @IBOutlet weak var fourthThumbnail: UIImageView!
    @IBOutlet weak var groupTitleLabel: UILabel!
    @IBOutlet weak var additionalMediaOverlay: UIView!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var groupSizeLabel: UILabel!

    private var thumbnailsArray: [UIImageView] = []
    private let itemCornerRadius: CGFloat = 4.5
    private let groupCornerRadius: CGFloat = 3.0

    override class var edgePadding: CGFloat {
        return 12.5
    }
    override class var interItemPadding: CGFloat {
        return 7.5
    }

    override var isSelected: Bool {
        didSet {
            checkboxImageView.image = isSelected ? UIImage(named: "checkboxSelected")
                : UIImage(named: "checkboxEmpty")
        }
    }

    override var checkImageView: UIImageView? {
        return checkboxImageView
    }

    override var selectionViewOverlay: UIView? {
        return selectionOverlay
    }

    override var secondDescriptionLabelView: UILabel? {
        return sizeLabel
    }

    override var media: VLCMLObject? {
        didSet {
            if let movie = media as? VLCMLMedia {
                update(movie:movie)
            } else if let playlist = media as? VLCMLPlaylist {
                update(playlist:playlist)
            } else if let mediaGroup = media as? VLCMLMediaGroup {
                update(mediaGroup: mediaGroup)
            } else {
                assertionFailure("MovieCollectionViewCell: media: Needs to be of a supported Type.")
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 11.0, *) {
            thumbnailView.accessibilityIgnoresInvertColors = true
        }

        clipsToBounds = true
        layer.cornerRadius = 2

        newLabel.text = NSLocalizedString("NEW", comment: "")
        newLabel.textColor = PresentationTheme.current.colors.orangeUI

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(themeDidChange),
                                       name: .VLCThemeDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self, selector: #selector(dynamicFontSizeChange),
                                       name: UIContentSizeCategory.didChangeNotification,
                                       object: nil)
        selectionOverlay.layer.cornerRadius = itemCornerRadius
        thumbnailView.layer.cornerRadius = itemCornerRadius
        thumbnailsArray = [firstThumbnail, secondThumbnail, thirdThumbnail, fourthThumbnail]
        dynamicFontSizeChange()
        themeDidChange()
    }

    private func setupGroupView() {
        thumbnailsBackground.layer.cornerRadius = itemCornerRadius

        firstThumbnail.layer.cornerRadius = groupCornerRadius
        secondThumbnail.layer.cornerRadius = groupCornerRadius
        thirdThumbnail.layer.cornerRadius = groupCornerRadius
        fourthThumbnail.layer.cornerRadius = groupCornerRadius
        additionalMediaOverlay.layer.cornerRadius = groupCornerRadius
    }

    @objc fileprivate func themeDidChange() {
        let colors = PresentationTheme.current.colors
        backgroundColor = colors.background
        titleLabel?.textColor = colors.cellTextColor
        descriptionLabel?.textColor = colors.cellDetailTextColor
        sizeLabel.textColor = colors.cellDetailTextColor
        groupTitleLabel.textColor = colors.cellTextColor
        groupSizeLabel.textColor = colors.cellDetailTextColor
        titleLabel?.backgroundColor = backgroundColor
        descriptionLabel?.backgroundColor = backgroundColor
        sizeLabel.backgroundColor = backgroundColor
        groupTitleLabel.backgroundColor = backgroundColor
        groupSizeLabel.backgroundColor = backgroundColor
        mediaView.backgroundColor = backgroundColor
        groupView.backgroundColor = backgroundColor
        newLabel.backgroundColor = backgroundColor
        thumbnailsBackground.backgroundColor = colors.thumbnailBackgroundColor
    }

    @objc fileprivate func dynamicFontSizeChange() {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        newLabel.font = UIFont.preferredCustomFont(forTextStyle: .subheadline).bolded
        groupTitleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        sizeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        groupSizeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
    }

    private func setThumbnails(medias: [VLCMLMedia]?) {
        for index in 0...3 {
            if let media = medias?.objectAtIndex(index: index) {
                thumbnailsArray[index].image = media.thumbnailImage()
            }
        }

        let mediasCount = medias?.count ?? 0
        if mediasCount > 4 {
            numberLabel.text = String(format:"+  %i", mediasCount - 4)
            additionalMediaOverlay.isHidden = false
        }
    }

    func update(movie: VLCMLMedia) {
        titleLabel.text = movie.title()
        accessibilityLabel = movie.accessibilityText(editing: false)
        descriptionLabel.text = movie.mediaDuration()
        thumbnailView.image = movie.thumbnailImage()
        let progress = movie.progress
        guard let value = UserDefaults.standard.value(forKey: kVLCSettingContinuePlayback) as? Int else {
            return
        }
        if value <= 0 {
            progressView.isHidden = true
        } else {
            progressView.isHidden = progress < 0
            progressView.progress = progress
        }
        newLabel.isHidden = !movie.isNew
        sizeLabel.text = movie.formatSize()

        progressView.progressViewStyle = .bar

        if !progressView.isHidden {
            if #available(iOS 11.0, *) {
                progressView.layer.cornerRadius = itemCornerRadius
                progressView.clipsToBounds = true
                progressView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                let path = UIBezierPath(roundedRect: progressView.bounds,
                                        byRoundingCorners: [.bottomLeft, .bottomRight],
                                        cornerRadii: CGSize(width: 7, height: 7))
                let maskLayer = CAShapeLayer()
                maskLayer.path = path.cgPath
                progressView.layer.mask = maskLayer
            }
        }
    }

    func update(playlist: VLCMLPlaylist) {
        mediaView.isHidden = true
        progressView.isHidden = true

        setupGroupView()

        setThumbnails(medias: playlist.media)

        groupTitleLabel.text = playlist.title()
        groupSizeLabel.text = playlist.numberOfTracksString()

        groupView.isHidden = false
    }

    func update(mediaGroup: VLCMLMediaGroup) {
        let isSingleMediaGroup = mediaGroup.nbTotalMedia() == 1

        if isSingleMediaGroup && !mediaGroup.userInteracted() {
            guard let media = mediaGroup.media(of: .unknown)?.first else {
                assertionFailure("MovieCollectionViewCell: Failed to fetch media.")
                return
            }
            update(movie: media)
            return
        }

        mediaView.isHidden = true
        progressView.isHidden = true

        setupGroupView()

        setThumbnails(medias: mediaGroup.media(of: .unknown))

        groupTitleLabel.text = mediaGroup.name()
        groupSizeLabel.text = mediaGroup.numberOfTracksString()

        groupView.isHidden = false
    }

    override class func numberOfColumns(for width: CGFloat) -> CGFloat {
        if width <= DeviceDimensions.iPhone14ProMaxPortrait.rawValue {
            return 2
        } else if width <= DeviceDimensions.iPhoneLandscape.rawValue {
            return 3
        } else if width <= DeviceDimensions.iPadLandscape.rawValue {
            return 4
        } else {
            return 5
        }
    }

    override class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        let numberOfCells: CGFloat = numberOfColumns(for: width)
        let aspectRatio: CGFloat = 10.0 / 16.0

        // We have the number of cells and we always have numberofCells + 1 interItemPadding spaces.
        //
        // edgePadding-interItemPadding-[Cell]-interItemPadding-[Cell]-interItemPadding-edgePadding
        //

        let overallWidth = width - (2 * edgePadding)
        let overallCellWidthWithoutPadding = overallWidth - (numberOfCells + 1) * interItemPadding
        let cellWidth = floor(overallCellWidthWithoutPadding / numberOfCells)

        let titleHeight = UIFont.preferredFont(forTextStyle: .headline).lineHeight
        let newHeight = UIFont.preferredCustomFont(forTextStyle: .subheadline).bolded.lineHeight

        // title * 2, newLabel, 3 * 4 paddings for lines

        return CGSize(width: cellWidth, height: cellWidth * aspectRatio + titleHeight * 2 + newHeight + (3 * 3))
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        descriptionLabel.text = ""
        thumbnailView.image = nil
        progressView.isHidden = true
        newLabel.isHidden = true
        checkboxImageView.isHidden = true
        selectionOverlay.isHidden = true
        sizeLabel.isHidden = true
        mediaView.isHidden = false

        firstThumbnail.image = nil
        secondThumbnail.image = nil
        thirdThumbnail.image = nil
        fourthThumbnail.image = nil
        additionalMediaOverlay.isHidden = true
        groupTitleLabel.text = ""
        numberLabel.text = ""
        groupSizeLabel.text = ""
        groupView.isHidden = true
    }
}
