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
    static let reuseIdentifier = "PodcastEpisodeCell"

    private let artworkView = PodcastArtworkView()

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

    private let downloadButton = PodcastDownloadButton()

    private var artworkTapTarget: (() -> Void)?
    private var downloadTapTarget: (() -> Void)?
    private var cancelDownloadTapTarget: (() -> Void)?
    private var deleteDownloadTapTarget: (() -> Void)?

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
        accessibilityIdentifier = VLCAccessibilityIdentifier.podcastEpisode

        contentView.addSubview(artworkView)
        contentView.addSubview(textStack)
        contentView.addSubview(downloadButton)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapArtwork))
        artworkView.addGestureRecognizer(tap)

        downloadButton.addTarget(self, action: #selector(didTapDownload), for: .touchUpInside)

        NSLayoutConstraint.activate([
            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            artworkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            artworkView.widthAnchor.constraint(equalToConstant: 56),
            artworkView.heightAnchor.constraint(equalToConstant: 56),

            textStack.leadingAnchor.constraint(equalTo: artworkView.trailingAnchor, constant: 12),
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
                    name: String,
                    artworkURL: URL?,
                    showName: String?,
                    downloading: Bool = false,
                    onTapArtwork: (() -> Void)? = nil,
                    onDownload: (() -> Void)? = nil,
                    onCancelDownload: (() -> Void)? = nil,
                    onDeleteDownload: (() -> Void)? = nil) {
        PodcastStore.shared.requestArtwork(for: episode)

        artworkView.configure(name: name, artworkURL: artworkURL, cornerRadius: 8, fontSize: 16)

        if let showName = showName {
            showNameLabel.isHidden = false
            showNameLabel.text = showName
        } else {
            showNameLabel.isHidden = true
        }

        let hasDuration = episode.durationValue > 0

        var detailComponents: [String] = []
        if let number = episode.numberText {
            detailComponents.append(number)
        }
        detailComponents.append(episode.date)
        if hasDuration {
            detailComponents.append(episode.duration)
        }

        titleLabel.text = episode.title
        detailLabel.text = detailComponents.joined(separator: " · ")
        progressBar.isHidden = !episode.hasProgress
        progressBar.progress = episode.progressFraction
        downloadButton.configure(downloaded: episode.downloaded, downloading: downloading)

        artworkTapTarget = onTapArtwork
        downloadTapTarget = onDownload
        cancelDownloadTapTarget = onCancelDownload
        deleteDownloadTapTarget = onDeleteDownload

        artworkView.isUserInteractionEnabled = onTapArtwork != nil
        accessibilityLabel = ([episode.title] + detailComponents).joined(separator: ", ")
    }

    @objc private func didTapArtwork() {
        artworkTapTarget?()
    }

    @objc private func didTapDownload() {
        if downloadButton.isDownloading {
            cancelDownloadTapTarget?()
        } else if downloadButton.isDownloaded {
            deleteDownloadTapTarget?()
        } else {
            downloadTapTarget?()
        }
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors
        backgroundColor = colors.background
        contentView.backgroundColor = colors.background
        titleLabel.textColor = colors.cellTextColor
        showNameLabel.textColor = colors.cellDetailTextColor
        detailLabel.textColor = colors.cellDetailTextColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artworkTapTarget = nil
        downloadTapTarget = nil
        cancelDownloadTapTarget = nil
        deleteDownloadTapTarget = nil
        progressBar.isHidden = true
    }
}
