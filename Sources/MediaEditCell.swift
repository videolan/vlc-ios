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

    override var media: VLCMLObject? {
        didSet {
            guard let media = media as? VLCMLMedia else {
                fatalError("needs to be of Type VLCMLMedia")
            }
            update(media:media)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnailImageView.layer.cornerRadius = 3
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

    func update(media: VLCMLMedia) {
        titleLabel.text = media.title
        timeLabel.text = media.mediaDuration()
        sizeLabel.text = media.formatSize()
        if media.isThumbnailGenerated() {
            thumbnailImageView.image = UIImage(contentsOfFile: media.thumbnail.absoluteString)
        }
    }

    var isChecked: Bool = false {
         didSet {
            checkboxImageView.image = isChecked ? UIImage(named: "checkboxEmpty") : UIImage(named: "checkboxSelected")
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        timeLabel.text = ""
        sizeLabel.text = ""
        thumbnailImageView.image = nil
    }
}
