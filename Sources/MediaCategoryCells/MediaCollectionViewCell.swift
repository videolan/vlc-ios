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
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var newLabel: UILabel!

    override var media: VLCMLObject? {
        didSet {
            if let albumTrack = media as? VLCMLMedia, albumTrack.subtype() == .albumTrack {
                update(audiotrack:albumTrack)
            } else if let album = media as? VLCMLAlbum {
                update(album:album)
            } else if let artist = media as? VLCMLArtist {
                update(artist:artist)
            } else if let movie = media as? VLCMLMedia, movie.subtype() == .unknown {
                update(movie:movie)
            } else if let playlist = media as? VLCMLPlaylist {
                update(playlist: playlist)
            } else if let genre = media as? VLCMLGenre {
                update(genre: genre)
            } else {
                fatalError("needs to be of Type VLCMLMedia or VLCMLAlbum")
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

    func update(audiotrack: VLCMLMedia) {
        titleLabel.text = audiotrack.title
        descriptionLabel.text = audiotrack.albumTrackArtistName()
        newLabel.isHidden = !audiotrack.isNew
        thumbnailView.image = audiotrack.thumbnailImage()
    }

    func update(album: VLCMLAlbum) {
        titleLabel.text = album.albumName()
        descriptionLabel.text = album.albumArtistName()
        thumbnailView.image = album.thumbnail()
    }

    func update(artist: VLCMLArtist) {
        thumbnailView.layer.masksToBounds = true
        thumbnailView.layer.cornerRadius = thumbnailView.frame.size.width / 2.0
        titleLabel.text = artist.artistName()
        descriptionLabel.text = artist.numberOfTracksString()
        thumbnailView.image = artist.thumbnail()
    }

    func update(movie: VLCMLMedia) {
        titleLabel.text = movie.title
        descriptionLabel.text = movie.mediaDuration()
        if movie.isThumbnailGenerated() {
            thumbnailView.image = UIImage(contentsOfFile: movie.thumbnail.path)
        }
        newLabel.isHidden = !movie.isNew
    }

    func update(playlist: VLCMLPlaylist) {
        newLabel.isHidden = true
        titleLabel.text = playlist.name
        descriptionLabel.text = playlist.numberOfTracksString()
        thumbnailView.image = playlist.thumbnail()
    }

    func update(genre: VLCMLGenre) {
        newLabel.isHidden = true
        titleLabel.text = genre.name

        thumbnailView.image = genre.thumbnail()
        descriptionLabel.text = genre.numberOfTracksString()
    }

    override class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        let numberOfCells: CGFloat
        if width <= DeviceWidth.iPhonePortrait.rawValue {
            numberOfCells = 1
        } else if width <= DeviceWidth.iPhoneLandscape.rawValue {
            numberOfCells = 2
        } else if width <= DeviceWidth.iPadLandscape.rawValue {
            numberOfCells = 3
        } else {
            numberOfCells = 4
        }

        // We have the number of cells and we always have numberofCells + 1 interItemPadding spaces.
        //
        // edgePadding-interItemPadding-[Cell]-interItemPadding-[Cell]-interItemPadding-edgePadding
        //

        let overallWidth = width - (2 * edgePadding)
        let overallCellWidthWithoutPadding = overallWidth - (numberOfCells + 1) * interItemPadding
        let cellWidth = floor(overallCellWidthWithoutPadding / numberOfCells)

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
