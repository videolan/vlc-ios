/*****************************************************************************
 * PodcastEpisodeCell.swift
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

class PodcastEpisodeCell: UITableViewCell {
    enum Leading {
        case artwork(name: String, artworkURL: URL?)
        case playButton
    }

    static let reuseIdentifier = "PodcastEpisodeCell"

    private let artworkView = PodcastArtworkView()

    private let playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        // TODO: - Add action
        return button
    }()

    private let showNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .subheadline).semibolded
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let progressBar: PodcastProgressBar = {
        let bar = PodcastProgressBar()
        bar.isHidden = true
        return bar
    }()

    // Status-only: reflects whether the episode is already cached, since the media library
    // caches subscription episodes automatically and exposes no manual per-episode trigger.
    private let downloadButton = PodcastDownloadButton()

    private var artworkTapTarget: (() -> Void)?

    private lazy var leadingContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [showNameLabel, titleLabel, detailLabel, progressBar])
        stack.axis = .vertical
        stack.spacing = 2
        stack.setCustomSpacing(6, after: detailLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none

        leadingContainer.addSubview(artworkView)
        leadingContainer.addSubview(playButton)

        contentView.addSubview(leadingContainer)
        contentView.addSubview(textStack)
        contentView.addSubview(downloadButton)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapLeading))
        leadingContainer.addGestureRecognizer(tap)

        downloadButton.isUserInteractionEnabled = false

        NSLayoutConstraint.activate([
            leadingContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leadingContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            leadingContainer.widthAnchor.constraint(equalToConstant: 56),
            leadingContainer.heightAnchor.constraint(equalToConstant: 56),

            artworkView.leadingAnchor.constraint(equalTo: leadingContainer.leadingAnchor),
            artworkView.trailingAnchor.constraint(equalTo: leadingContainer.trailingAnchor),
            artworkView.topAnchor.constraint(equalTo: leadingContainer.topAnchor),
            artworkView.bottomAnchor.constraint(equalTo: leadingContainer.bottomAnchor),

            playButton.centerXAnchor.constraint(equalTo: leadingContainer.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: leadingContainer.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 40),
            playButton.heightAnchor.constraint(equalToConstant: 40),

            textStack.leadingAnchor.constraint(equalTo: leadingContainer.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -8),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            progressBar.heightAnchor.constraint(equalToConstant: 3),

            downloadButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            downloadButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: 32),
            downloadButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        applyTheme()
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(applyTheme),
                                                name: .VLCThemeDidChangeNotification,
                                                object: nil)
    }

    func configure(episode: PodcastEpisode,
                    leading: Leading,
                    showName: String?,
                    onTapLeading: (() -> Void)? = nil) {
        switch leading {
        case .artwork(let name, let artworkURL):
            artworkView.isHidden = false
            playButton.isHidden = true
            artworkView.configure(name: name, artworkURL: artworkURL, cornerRadius: 8, fontSize: 16)
        case .playButton:
            artworkView.isHidden = true
            playButton.isHidden = false
        }

        if let showName = showName {
            showNameLabel.isHidden = false
            showNameLabel.text = showName
        } else {
            showNameLabel.isHidden = true
        }

        titleLabel.text = episode.title
        detailLabel.text = "\(episode.date) · \(episode.duration)"
        progressBar.isHidden = !episode.hasProgress
        progressBar.progress = episode.progressFraction
        downloadButton.configure(downloaded: episode.downloaded)

        artworkTapTarget = onTapLeading

        leadingContainer.isUserInteractionEnabled = onTapLeading != nil
        accessibilityLabel = "\(episode.title), \(episode.date), \(episode.duration)"
    }

    @objc private func didTapLeading() {
        artworkTapTarget?()
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors
        backgroundColor = colors.background
        contentView.backgroundColor = colors.background
        titleLabel.textColor = colors.cellTextColor
        showNameLabel.textColor = colors.cellDetailTextColor
        detailLabel.textColor = colors.cellDetailTextColor

        playButton.backgroundColor = colors.orangeUI
        playButton.layer.cornerRadius = 20
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            playButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
            playButton.tintColor = colors.background
        } else {
            playButton.setImage(UIImage(named: "iconPlay"), for: .normal)
            playButton.tintColor = colors.background
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artworkTapTarget = nil
        progressBar.isHidden = true
    }
}
