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

    private let artworkView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var artworkURL: URL?
    private var requestedArtworkKey: String?

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

    func configure(initials: String, color: UIColor, cornerRadius: CGFloat, fontSize: CGFloat) {
        initialsLabel.text = initials
        initialsLabel.font = .systemFont(ofSize: fontSize, weight: .medium)
        backgroundColor = color
        layer.cornerRadius = cornerRadius

        artworkURL = nil
        requestedArtworkKey = nil
        artworkView.image = nil
        artworkView.isHidden = true
    }

    func configure(name: String, artworkURL: URL? = nil, cornerRadius: CGFloat, fontSize: CGFloat) {
        configure(initials: VLCPlaceholderArtwork.initials(forName: name),
                  color: VLCPlaceholderArtwork.backgroundColor(forName: name),
                  cornerRadius: cornerRadius,
                  fontSize: fontSize)

        guard let artworkURL = artworkURL, artworkURL.isFileURL else {
            return
        }

        self.artworkURL = artworkURL
        artworkView.layer.cornerRadius = cornerRadius
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        loadArtworkIfNeeded()
    }

    private func loadArtworkIfNeeded() {
        guard let artworkURL = artworkURL else {
            return
        }

        let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 2
        let maxPixelSize = max(bounds.width, bounds.height) * scale
        guard maxPixelSize > 0 else {
            return
        }

        let key = "\(artworkURL.path)|\(Int(maxPixelSize))"
        guard key != requestedArtworkKey else {
            return
        }
        requestedArtworkKey = key

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let image = VLCThumbnailsCache.thumbnail(for: artworkURL, maxPixelSize: maxPixelSize)
            if image == nil {
                APLog("podcast artwork: failed to load \(artworkURL.path)")
            }
            DispatchQueue.main.async {
                guard let self = self, self.requestedArtworkKey == key, let image = image else {
                    return
                }
                self.artworkView.image = image
                self.artworkView.isHidden = false
            }
        }
    }
}
