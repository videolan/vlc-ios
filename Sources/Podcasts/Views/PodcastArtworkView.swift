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
        label.textColor = UIColor.white.withAlphaComponent(0.85)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let remoteArtworkView: VLCNetworkImageView = {
        let imageView = VLCNetworkImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

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
        addSubview(remoteArtworkView)
        NSLayoutConstraint.activate([
            initialsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            remoteArtworkView.topAnchor.constraint(equalTo: topAnchor),
            remoteArtworkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            remoteArtworkView.trailingAnchor.constraint(equalTo: trailingAnchor),
            remoteArtworkView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(initials: String, color: UIColor, cornerRadius: CGFloat, fontSize: CGFloat) {
        initialsLabel.text = initials
        initialsLabel.font = .systemFont(ofSize: fontSize, weight: .heavy)
        backgroundColor = color
        layer.cornerRadius = cornerRadius

        remoteArtworkView.cancelLoading()
        remoteArtworkView.image = nil
        remoteArtworkView.isHidden = true
    }

    func configure(name: String, artworkURL: URL? = nil, cornerRadius: CGFloat, fontSize: CGFloat) {
        configure(initials: VLCPlaceholderArtwork.initials(forName: name),
                  color: VLCPlaceholderArtwork.backgroundColor(forName: name),
                  cornerRadius: cornerRadius,
                  fontSize: fontSize)

        if let artworkURL = artworkURL {
            remoteArtworkView.layer.cornerRadius = cornerRadius
            remoteArtworkView.isHidden = false
            remoteArtworkView.setImageWith(artworkURL)
        }
    }
}
