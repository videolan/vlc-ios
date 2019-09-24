/*****************************************************************************
 * VLCMediaViewEditCell.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *          Carola Nitz <nitz.carola@googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class MediaEditCell: BaseCollectionViewCell {

    static let height: CGFloat = 88

    @IBOutlet weak var checkboxImageView: UIImageView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var dragImage: UIImageView!
    @IBOutlet weak var VideoAspectRatio: NSLayoutConstraint!
    @IBOutlet weak var AudioAspectRatio: NSLayoutConstraint!

    override var media: VLCMLObject? {
        didSet {
            if let movie = media as? VLCMLMedia, movie.type() == .video {
                updateForMovie(movie: movie)
            } else if let artist = media as? VLCMLArtist {
                updateForArtist(artist: artist)
            } else if let album = media as? VLCMLAlbum {
                updateForAlbum(album: album)
            } else if let genre = media as? VLCMLGenre {
                updateForGenre(genre: genre)
            } else if let playlist = media as? VLCMLPlaylist {
                updateForPlaylist(playlist: playlist)
            } else if let audio = media as? VLCMLMedia, audio.type() == .audio {
                updateForAudio(audio: audio)
            } else {
                fatalError("needs to be of a supported Type")
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 11.0, *) {
            thumbnailImageView.accessibilityIgnoresInvertColors = true
        }
        thumbnailImageView.clipsToBounds = true
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
        themeDidChange()
    }

    @objc fileprivate func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        titleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        timeLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
        sizeLabel.textColor = PresentationTheme.current.colors.cellTextColor
        dragImage.tintColor = PresentationTheme.current.colors.cellDetailTextColor
    }

    func updateForMovie(movie: VLCMLMedia) {
        thumbnailImageView.layer.cornerRadius = 3
        AudioAspectRatio.isActive = false
        VideoAspectRatio.isActive = true
        titleLabel.text = movie.title
        accessibilityLabel = movie.accessibilityText(editing: true)
        timeLabel.text = movie.mediaDuration()
        sizeLabel.text = movie.formatSize()
        thumbnailImageView.image = movie.thumbnailImage()
    }

    func updateForAudio(audio: VLCMLMedia) {
        titleLabel.text = audio.title
        accessibilityLabel = audio.accessibilityText(editing: true)
        timeLabel.text = audio.mediaDuration()
        sizeLabel.text = audio.formatSize()
        thumbnailImageView.image = audio.thumbnailImage()
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.height / 2
    }

    func updateForArtist(artist: VLCMLArtist) {
        titleLabel.text = artist.artistName()
        accessibilityLabel = artist.accessibilityText()
        timeLabel.text = artist.numberOfTracksString()
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.height / 2
        thumbnailImageView.image = artist.thumbnail()
    }

    func updateForAlbum(album: VLCMLAlbum) {
        titleLabel.text = album.albumName()
        accessibilityLabel = album.accessibilityText(editing: true)
        timeLabel.text = album.albumArtistName()
        sizeLabel.text = album.numberOfTracksString()
        thumbnailImageView.image = album.thumbnail()
    }

    func updateForGenre(genre: VLCMLGenre) {
        titleLabel.text = genre.name
        accessibilityLabel = genre.accessibilityText()
        timeLabel.text = genre.numberOfTracksString()
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.height / 2
        thumbnailImageView.image = genre.thumbnail()
    }

    func updateForPlaylist(playlist: VLCMLPlaylist) {
        thumbnailImageView.layer.cornerRadius = 3
        AudioAspectRatio.isActive = false
        VideoAspectRatio.isActive = true
        titleLabel.text = playlist.name
        accessibilityLabel = playlist.accessibilityText()
        timeLabel.text = playlist.numberOfTracksString()
        thumbnailImageView.image = playlist.thumbnail()
    }

    var isChecked: Bool = false {
         didSet {
            checkboxImageView.image = isChecked ? UIImage(named: "checkboxSelected") : UIImage(named: "checkboxEmpty")
        }
    }

    override class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        let numberOfCells: CGFloat
        if width <= DeviceWidth.iPhonePortrait.rawValue {
            numberOfCells = 1
        } else if width <= DeviceWidth.iPhoneLandscape.rawValue {
            numberOfCells = 2
        } else {
            numberOfCells = 3
        }

        // We have the number of cells and we always have numberofCells + 1 interItemPadding spaces.
        //
        // edgePadding-interItemPadding-[Cell]-interItemPadding-[Cell]-interItemPadding-edgePadding
        //

        let overallWidth = width - (2 * edgePadding)
        let overallCellWidthWithoutPadding = overallWidth - (numberOfCells + 1) * interItemPadding
        let cellWidth = floor(overallCellWidthWithoutPadding / numberOfCells)

        return CGSize(width: cellWidth, height: height)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        timeLabel.text = ""
        sizeLabel.text = ""
        accessibilityLabel = ""
        thumbnailImageView.image = nil
        isChecked = false
        thumbnailImageView.layer.cornerRadius = 0
        AudioAspectRatio.isActive = true
        VideoAspectRatio.isActive = false
    }
}
