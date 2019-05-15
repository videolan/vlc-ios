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
        thumbnailImageView.clipsToBounds = true
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
        themeDidChange()
    }

    @objc fileprivate func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        titleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        timeLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
        sizeLabel.textColor = PresentationTheme.current.colors.cellTextColor
    }

    func updateForMovie(movie: VLCMLMedia) {
        thumbnailImageView.layer.cornerRadius = 3
        AudioAspectRatio.isActive = false
        VideoAspectRatio.isActive = true
        titleLabel.text = movie.title
        timeLabel.text = movie.mediaDuration()
        sizeLabel.text = movie.formatSize()
        if movie.isThumbnailGenerated() {
            thumbnailImageView.image = UIImage(contentsOfFile: movie.thumbnail.path)
        }
    }

    func updateForAudio(audio: VLCMLMedia) {
        titleLabel.text = audio.title
        timeLabel.text = audio.mediaDuration()
        sizeLabel.text = audio.formatSize()
        if audio.isThumbnailGenerated() {
            thumbnailImageView.image = UIImage(contentsOfFile: audio.thumbnail.path)
        }
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.height / 2
    }

    func updateForArtist(artist: VLCMLArtist) {
        //TODO: add size, number of tracks, thumbnail
        titleLabel.text = artist.name
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.height / 2
    }

    func updateForAlbum(album: VLCMLAlbum) {
        titleLabel.text = album.title
        timeLabel.text = album.albumArtist?.name ?? ""
        //TODO: add size, number of tracks, thumbnail
    }

    func updateForGenre(genre: VLCMLGenre) {
        titleLabel.text = genre.name
        timeLabel.text = genre.numberOfTracksString()
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.height / 2
        //TODO: add thumbnail
    }

    func updateForPlaylist(playlist: VLCMLPlaylist) {
        thumbnailImageView.layer.cornerRadius = 3
        AudioAspectRatio.isActive = false
        VideoAspectRatio.isActive = true
        titleLabel.text = playlist.name
        timeLabel.text = playlist.numberOfTracksString()
        //TODO: add thumbnail
    }

    var isChecked: Bool = false {
         didSet {
            checkboxImageView.image = isChecked ? UIImage(named: "checkboxSelected") : UIImage(named: "checkboxEmpty")
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        timeLabel.text = ""
        sizeLabel.text = ""
        thumbnailImageView.image = nil
        isChecked = false
        thumbnailImageView.layer.cornerRadius = 0
        AudioAspectRatio.isActive = true
        VideoAspectRatio.isActive = false
    }
}
