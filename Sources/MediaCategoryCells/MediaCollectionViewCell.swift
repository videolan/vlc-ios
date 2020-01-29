/*****************************************************************************
 * MediaCollectionViewCell.swift
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

class MediaCollectionViewCell: BaseCollectionViewCell {

    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var newLabel: UILabel!
    @IBOutlet private weak var thumbnailWidth: NSLayoutConstraint!
    @IBOutlet private weak var sizeLabel: UILabel!
    @IBOutlet weak var descriptionStackView: UIStackView!

    @IBOutlet weak var checkboxImageView: UIImageView!
    @IBOutlet weak var selectionOverlay: UIView!
    @IBOutlet weak var dragIndicatorImageView: UIImageView!

    private var separatorLabel: UILabel = UILabel()

    override var media: VLCMLObject? {
        didSet {
            if let media = media as? VLCMLMedia {
                if media.subtype() == .albumTrack {
                    update(audiotrack: media)
                } else {
                    update(movie: media)
                }
            } else if let album = media as? VLCMLAlbum {
                update(album:album)
            } else if let artist = media as? VLCMLArtist {
                update(artist:artist)
            } else if let playlist = media as? VLCMLPlaylist {
                update(playlist: playlist)
            } else if let genre = media as? VLCMLGenre {
                update(genre: genre)
            } else {
                assertionFailure("MovieCollectionViewCell: media: Needs to be of a supported Type.")
            }
        }
    }

    override var checkImageView: UIImageView? {
        return checkboxImageView
    }

    override var selectionViewOverlay: UIView? {
        return selectionOverlay
    }

    override var descriptionSeparatorLabel: UILabel? {
        return separatorLabel
    }

    override var secondDescriptionLabelView: UILabel? {
        return sizeLabel
    }

    override var isSelected: Bool {
        didSet {
            checkboxImageView.image = isSelected ? UIImage(named: "checkboxSelected")
                : UIImage(named: "checkboxEmpty")
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 11.0, *) {
            thumbnailView.accessibilityIgnoresInvertColors = true
        }
        newLabel.text = NSLocalizedString("NEW", comment: "")
        newLabel.textColor = PresentationTheme.current.colors.orangeUI
        separatorLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        separatorLabel.setContentHuggingPriority(.required, for: .horizontal)
        separatorLabel.font = sizeLabel.font
        let isIpad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        thumbnailWidth.constant = isIpad ? 72 : 56
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
        themeDidChange()
    }

    @objc fileprivate func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        titleLabel?.textColor = PresentationTheme.current.colors.cellTextColor
        descriptionLabel?.textColor = PresentationTheme.current.colors.cellDetailTextColor
        sizeLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
        separatorLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
        dragIndicatorImageView.tintColor = PresentationTheme.current.colors.cellDetailTextColor
    }

    func update(audiotrack: VLCMLMedia) {
        titleLabel.text = audiotrack.title()
        accessibilityLabel = audiotrack.accessibilityText(editing: false)
        var descriptionText = audiotrack.albumTrackArtistName()
        if let albumTitle = audiotrack.albumTrack?.album?.title, !albumTitle.isEmpty {
            descriptionText += " - " + albumTitle
        }
        descriptionLabel.text = descriptionText
        newLabel.isHidden = !audiotrack.isNew
        thumbnailView.image = audiotrack.thumbnailImage()
        sizeLabel.text = audiotrack.formatSize()
        separatorLabel.text = "·"
        separatorLabel.isHidden = true
        descriptionStackView.insertArrangedSubview(separatorLabel, at: 1)
    }

    func update(album: VLCMLAlbum) {
        newLabel.isHidden = true
        titleLabel.text = album.albumName()
        accessibilityLabel = album.accessibilityText(editing: false)
        descriptionLabel.text = album.albumArtistName()
        thumbnailView.image = album.thumbnail()
    }

    func update(artist: VLCMLArtist) {
        newLabel.isHidden = true
        thumbnailView.layer.masksToBounds = true
        thumbnailView.layer.cornerRadius = thumbnailView.frame.size.width / 2.0
        titleLabel.text = artist.artistName()
        accessibilityLabel = artist.accessibilityText()
        descriptionLabel.text = artist.numberOfTracksString()
        thumbnailView.image = artist.thumbnail()
    }

    func update(movie: VLCMLMedia) {
        titleLabel.text = movie.title()
        accessibilityLabel = movie.accessibilityText(editing: false)
        descriptionLabel.text = movie.mediaDuration()
        thumbnailView.image = movie.thumbnailImage()
        newLabel.isHidden = !movie.isNew
    }

    func update(playlist: VLCMLPlaylist) {
        newLabel.isHidden = true
        titleLabel.text = playlist.name
        accessibilityLabel = playlist.accessibilityText()
        descriptionLabel.text = playlist.numberOfTracksString()
        thumbnailView.image = playlist.thumbnail()
    }

    func update(genre: VLCMLGenre) {
        newLabel.isHidden = true
        titleLabel.text = genre.name
        accessibilityLabel = genre.accessibilityText()

        thumbnailView.image = genre.thumbnail()
        descriptionLabel.text = genre.numberOfTracksString()
    }

    override class func numberOfColumns(for width: CGFloat) -> CGFloat {
        if width <= DeviceWidth.iPhonePortrait.rawValue {
            return 1
        } else if width <= DeviceWidth.iPadLandscape.rawValue {
            return 2
        } else {
            return 3
        }
    }

    override class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        let numberOfCells: CGFloat = numberOfColumns(for: width)

        // We have the number of cells and we always have numberofCells + 1 interItemPadding spaces.
        //
        // edgePadding-interItemPadding-[Cell]-interItemPadding-[Cell]-interItemPadding-edgePadding
        //

        let overallWidth = width - (2 * edgePadding)
        let overallCellWidthWithoutPadding = overallWidth - (numberOfCells + 1) * interItemPadding
        let cellWidth = floor(overallCellWidthWithoutPadding / numberOfCells)

        let isIpad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        return CGSize(width: cellWidth, height: isIpad ? 94 : 60)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        accessibilityLabel = ""
        descriptionLabel.text = ""
        thumbnailView.image = nil
        newLabel.isHidden = true
        checkboxImageView.isHidden = true
        selectionOverlay.isHidden = true
        dragIndicatorImageView.isHidden = true
        sizeLabel.isHidden = true
        separatorLabel.isHidden = true
    }
}
