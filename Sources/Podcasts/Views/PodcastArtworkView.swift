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
    private let artworkView: VLCNetworkImageView = {
        let imageView = VLCNetworkImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
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
        addSubview(artworkView)
        NSLayoutConstraint.activate([
            artworkView.topAnchor.constraint(equalTo: topAnchor),
            artworkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            artworkView.trailingAnchor.constraint(equalTo: trailingAnchor),
            artworkView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(name: String, artworkURL: URL? = nil, cornerRadius: CGFloat) {
        layer.cornerRadius = cornerRadius

        if artworkURL == self.artworkURL && (artworkURL?.isFileURL != true || artworkView.image != nil) {
            artworkView.setImage(artworkView.image, placeholderName: name)
            return
        }
        self.artworkURL = artworkURL

        artworkView.cancelLoading()
        artworkView.setImage(nil, placeholderName: name)
        guard let artworkURL = artworkURL else {
            return
        }
        artworkView.setImageWith(artworkURL)
    }
}
