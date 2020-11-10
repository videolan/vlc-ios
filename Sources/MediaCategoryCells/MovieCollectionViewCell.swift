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
    @IBOutlet weak var checkboxImageView: UIImageView!

    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var newLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var descriptionStackView: UIStackView!

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
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
        selectionOverlay.layer.cornerRadius = 6
        thumbnailsArray = [firstThumbnail, secondThumbnail, thirdThumbnail, fourthThumbnail]
        themeDidChange()
    }

    private func setupGroupView() {
        thumbnailsBackground.layer.cornerRadius = 6

        var color: UIColor = UIColor.gray.withAlphaComponent(0.08)
        if PresentationTheme.current.colors.isDark {
            color = UIColor.black.withAlphaComponent(0.25)
        }

        thumbnailsBackground.backgroundColor = color

        firstThumbnail.layer.cornerRadius = 3
        secondThumbnail.layer.cornerRadius = 3
        thirdThumbnail.layer.cornerRadius = 3
        fourthThumbnail.layer.cornerRadius = 3
        additionalMediaOverlay.layer.cornerRadius = 3
    }

    @objc fileprivate func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        titleLabel?.textColor = PresentationTheme.current.colors.cellTextColor
        descriptionLabel?.textColor = PresentationTheme.current.colors.cellDetailTextColor
        sizeLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
        groupTitleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        groupSizeLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
    }

    private func setThumbnails(medias: [VLCMLMedia]?) {
        for index in 0...3 {
            if let media = medias?.objectAtIndex(index: index) {
                thumbnailsArray[index].image = media.thumbnailImage()
            }
        }

        let mediasCount = medias?.count ?? 0
        if mediasCount > 4 {
            numberLabel.text = String(mediasCount - 4)
            additionalMediaOverlay.isHidden = false
        }
    }

    func update(movie: VLCMLMedia) {
        titleLabel.text = movie.title()
        accessibilityLabel = movie.accessibilityText(editing: false)
        descriptionLabel.text = movie.mediaDuration()
        thumbnailView.image = movie.thumbnailImage()
        let progress = movie.progress
        progressView.isHidden = progress == 0
        progressView.progress = progress
        newLabel.isHidden = !movie.isNew
        sizeLabel.text = movie.formatSize()
        thumbnailView.layer.cornerRadius = 6

        progressView.progressViewStyle = .bar

        if !progressView.isHidden {
            if #available(iOS 11.0, *) {
                progressView.layer.cornerRadius = 7
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

        thumbnailsBackground.isHidden = false
        groupView.isHidden = false
    }

    func update(mediaGroup: VLCMLMediaGroup) {
        let isSingleMediaGroup = mediaGroup.nbMedia() == 1

        if isSingleMediaGroup && !mediaGroup.userInteracted() {
            guard let media = mediaGroup.media(of: .video)?.first else {
                assertionFailure("MovieCollectionViewCell: Failed to fetch media.")
                return
            }
            update(movie: media)
            return
        }

        mediaView.isHidden = true
        progressView.isHidden = true

        setupGroupView()

        setThumbnails(medias: mediaGroup.media(of: .video))

        groupTitleLabel.text = mediaGroup.name()
        groupSizeLabel.text = mediaGroup.numberOfTracksString()

        thumbnailsBackground.isHidden = false
        groupView.isHidden = false
    }

    override class func numberOfColumns(for width: CGFloat) -> CGFloat {
        if width <= DeviceWidth.iPhonePortrait.rawValue {
            return 2
        } else if width <= DeviceWidth.iPhoneLandscape.rawValue {
            return 3
        } else if width <= DeviceWidth.iPadLandscape.rawValue {
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

        // 17 * 2 for title, 14 for new + duration, 3 * 4 paddings for lines
        return CGSize(width: cellWidth, height: cellWidth * aspectRatio + (16 * 2) + 14 + (3 * 3))
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
        thumbnailsBackground.isHidden = true
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
