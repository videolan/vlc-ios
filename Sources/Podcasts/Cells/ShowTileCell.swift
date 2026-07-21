/*****************************************************************************
 * ShowTileCell.swift
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

class ShowTileCell: UICollectionViewCell {
    static let reuseIdentifier = "ShowTileCell"

    private let artworkView = PodcastArtworkView()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .footnote).semibolded
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let episodeCountLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(artworkView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(episodeCountLabel)

        NSLayoutConstraint.activate([
            artworkView.topAnchor.constraint(equalTo: contentView.topAnchor),
            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artworkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            artworkView.heightAnchor.constraint(equalTo: artworkView.widthAnchor),

            nameLabel.topAnchor.constraint(equalTo: artworkView.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            episodeCountLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1),
            episodeCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            episodeCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        applyTheme()
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(applyTheme),
                                                name: .VLCThemeDidChangeNotification,
                                                object: nil)
    }

    func configure(show: PodcastShow) {
        let color = PodcastStore.shared.swatchColor(forHue: show.hue)
        artworkView.configure(initials: show.initials, color: color, cornerRadius: 14, fontSize: 22)
        nameLabel.text = show.name
        episodeCountLabel.text = String(format: NSLocalizedString("PODCAST_EPISODE_COUNT", comment: ""), show.episodeCount)
        accessibilityLabel = show.name
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors
        nameLabel.textColor = colors.cellTextColor
        episodeCountLabel.textColor = colors.cellDetailTextColor
    }
}
