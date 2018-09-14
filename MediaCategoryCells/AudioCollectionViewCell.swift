/*****************************************************************************
 * AudioCollectionViewCell.swift
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

class AudioCollectionViewCell: BaseCollectionViewCell {

    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var newLabel: UILabel!

    override var media: VLCMLObject? {
        didSet {
            guard let albumTrack = media as? VLCMLMedia else {
                fatalError("needs to be of Type VLCMLMovie")
            }
            update(audiotrack:albumTrack)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        newLabel.text = NSLocalizedString("NEW", comment: "")
        newLabel.textColor = PresentationTheme.current.colors.orangeUI
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
        themeDidChange()
        thumbnailView.layer.cornerRadius = thumbnailView.frame.size.width / 2.0
    }

    @objc fileprivate func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        titleLabel?.textColor = PresentationTheme.current.colors.cellTextColor
        descriptionLabel?.textColor = PresentationTheme.current.colors.cellDetailTextColor
    }

    func update(audiotrack: VLCMLMedia) {
        titleLabel.text = audiotrack.title
        descriptionLabel.text = audiotrack.mediaDuration()
        if audiotrack.isThumbnailGenerated() {
            thumbnailView.image = UIImage(contentsOfFile: audiotrack.thumbnail.absoluteString)
        }
        newLabel.isHidden = !audiotrack.isNew()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        descriptionLabel.text = ""
        thumbnailView.image = nil
        newLabel.isHidden = true
    }
}
