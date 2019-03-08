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
            if let media = media as? VLCMLMedia {
                updateForMedia(media: media)
            } else if let artist = media as? VLCMLArtist {
                updateForArtist(artist: artist)
            } else if let album = media as? VLCMLAlbum {
                updateForAlbum(album: album)
            } else if let genre = media as? VLCMLGenre {
                updateForGenre(genre: genre)
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

    func updateForMedia(media: VLCMLMedia) {
        thumbnailImageView.layer.cornerRadius = 3
        AudioAspectRatio.isActive = false
        VideoAspectRatio.isActive = true
        titleLabel.text = media.title
        timeLabel.text = media.mediaDuration()
        sizeLabel.text = media.formatSize()
        if media.isThumbnailGenerated() {
            thumbnailImageView.image = UIImage(contentsOfFile: media.thumbnail.absoluteString)
        }
    }

    func updateForArtist(artist: VLCMLArtist) {
        //TODO: add size, number of tracks, thumbnail
        titleLabel.text = artist.name
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.height / 2
    }

    func updateForAlbum(album: VLCMLAlbum) {
        titleLabel.text = album.title
        timeLabel.text = album.albumArtist != nil ? album.albumArtist.name : ""
        //TODO: add size, number of tracks, thumbnail
    }

    func updateForGenre(genre: VLCMLGenre) {
        titleLabel.text = genre.name
        timeLabel.text = genre.numberOfTracksString()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.height / 2
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
