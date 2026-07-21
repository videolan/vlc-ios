/*****************************************************************************
 * ContinueListeningCarouselCell.swift
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

class ContinueListeningCarouselCell: UICollectionViewCell {
    static let reuseIdentifier = "ContinueListeningCarouselCell"

    private let artworkView = PodcastArtworkView()
    private let progressBar = PodcastProgressBar()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .footnote).semibolded
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let showNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.lineBreakMode = .byTruncatingTail
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
        artworkView.configure(initials: "", color: .clear, cornerRadius: 12, fontSize: 30)
        artworkView.addSubview(progressBar)

        contentView.addSubview(artworkView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(showNameLabel)

        NSLayoutConstraint.activate([
            artworkView.topAnchor.constraint(equalTo: contentView.topAnchor),
            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artworkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            artworkView.heightAnchor.constraint(equalTo: artworkView.widthAnchor),

            progressBar.leadingAnchor.constraint(equalTo: artworkView.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: artworkView.trailingAnchor),
            progressBar.bottomAnchor.constraint(equalTo: artworkView.bottomAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 4),

            titleLabel.topAnchor.constraint(equalTo: artworkView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            showNameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            showNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            showNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        applyTheme()
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(applyTheme),
                                                name: .VLCThemeDidChangeNotification,
                                                object: nil)
    }

    func configure(episode: PodcastEpisode, show: PodcastShow?) {
        let color = PodcastStore.shared.swatchColor(forHue: show?.hue ?? 0)
        artworkView.configure(initials: show?.initials ?? "", color: color, cornerRadius: 12, fontSize: 30)
        progressBar.progress = episode.progressFraction
        titleLabel.text = episode.title
        showNameLabel.text = show?.name
        accessibilityLabel = "\(episode.title), \(show?.name ?? "")"
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors
        titleLabel.textColor = colors.cellTextColor
        showNameLabel.textColor = colors.cellDetailTextColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        progressBar.progress = 0
    }
}
