/*****************************************************************************
 * PodcastArtworkView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class PodcastArtworkView: UIView {
    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let artworkView: VLCNetworkImageView = {
        let imageView = VLCNetworkImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var artworkURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        addSubview(initialsLabel)
        addSubview(artworkView)
        NSLayoutConstraint.activate([
            initialsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            artworkView.topAnchor.constraint(equalTo: topAnchor),
            artworkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            artworkView.trailingAnchor.constraint(equalTo: trailingAnchor),
            artworkView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(initials: String, color: UIColor, textColor: UIColor,
                   cornerRadius: CGFloat, fontSize: CGFloat) {
        applyPlaceholder(initials: initials, color: color, textColor: textColor,
                         cornerRadius: cornerRadius, fontSize: fontSize)
        artworkURL = nil
        clearArtwork()
    }

    func configure(name: String, artworkURL: URL? = nil, cornerRadius: CGFloat, fontSize: CGFloat) {
        applyPlaceholder(initials: VLCPlaceholderArtwork.initials(forName: name),
                         color: VLCPlaceholderArtwork.backgroundColor(forName: name),
                         textColor: VLCPlaceholderArtwork.foregroundColor(forName: name),
                         cornerRadius: cornerRadius,
                         fontSize: fontSize)

        if artworkURL == self.artworkURL && (artworkURL?.isFileURL != true || artworkView.image != nil) {
            return
        }
        self.artworkURL = artworkURL

        clearArtwork()
        guard let artworkURL = artworkURL else {
            return
        }
        artworkView.isHidden = false
        artworkView.setImageWith(artworkURL)
    }

    private func applyPlaceholder(initials: String, color: UIColor, textColor: UIColor,
                                  cornerRadius: CGFloat, fontSize: CGFloat) {
        initialsLabel.text = initials
        initialsLabel.textColor = textColor
        initialsLabel.font = .systemFont(ofSize: fontSize, weight: .heavy)
        backgroundColor = color
        layer.cornerRadius = cornerRadius
        artworkView.layer.cornerRadius = cornerRadius
    }

    private func clearArtwork() {
        artworkView.cancelLoading()
        artworkView.image = nil
        artworkView.isHidden = true
    }
}
