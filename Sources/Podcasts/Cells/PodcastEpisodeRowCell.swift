/*****************************************************************************
 * PodcastEpisodeRowCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol PodcastEpisodeRowCellDelegate: AnyObject {
    func podcastEpisodeRowCellDidTapPlay(_ cell: PodcastEpisodeRowCell)
    func podcastEpisodeRowCellDidTapDownload(_ cell: PodcastEpisodeRowCell)
    func podcastEpisodeRowCellDidTapDeleteDownload(_ cell: PodcastEpisodeRowCell)
}

class PodcastEpisodeRowCell: UITableViewCell {
    static let reuseIdentifier = "PodcastEpisodeRowCell"

    private static let horizontalPadding: CGFloat = 16
    private static let verticalPadding: CGFloat = 8
    private static let artworkSize: CGFloat = 72
    private static let artworkRadius: CGFloat = 9
    private static let artworkTextGap: CGFloat = 12
    private static let textLineGap: CGFloat = 3
    private static let statusIndicatorSize: CGFloat = 8
    private static let statusIndicatorGap: CGFloat = 6
    private static let playButtonSize: CGFloat = 44
    private static let downloadButtonWidth: CGFloat = 44
    private static let downloadButtonHeight: CGFloat = 26
    private static let actionGap: CGFloat = 8
    private static let playedAlpha: CGFloat = 0.55

    private static let playImage: UIImage? = {
        guard #available(iOS 13.0, *) else {
            return UIImage(named: "iconPlay")
        }
        return UIImage(systemName: "play.fill",
                       withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular))
    }()

    private static let pauseImage: UIImage? = {
        guard #available(iOS 13.0, *) else {
            return UIImage(named: "pauseIcon")
        }
        return UIImage(systemName: "pause.fill",
                       withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular))
    }()

    private static let unplayedImage: UIImage? = {
        guard #available(iOS 13.0, *) else {
            let size = CGSize(width: statusIndicatorSize, height: statusIndicatorSize)
            let dot = UIGraphicsImageRenderer(size: size).image { context in
                context.cgContext.setFillColor(UIColor.white.cgColor)
                context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            }
            return dot.withRenderingMode(.alwaysTemplate)
        }
        return UIImage(systemName: "circle.fill",
                       withConfiguration: UIImage.SymbolConfiguration(pointSize: statusIndicatorSize,
                                                                      weight: .regular))
    }()

    private static let playedImage: UIImage? = {
        guard #available(iOS 13.0, *) else {
            return nil
        }
        return UIImage(systemName: "checkmark.circle.fill",
                       withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .regular))
    }()

    static var height: CGFloat {
        let dateHeight = UIFont.preferredCustomFont(forTextStyle: .caption1).lineHeight
        let titleHeight = UIFont.preferredCustomFont(forTextStyle: .subheadline).semibolded.lineHeight
        let snippetHeight = UIFont.preferredCustomFont(forTextStyle: .footnote).lineHeight

        let textHeight = dateHeight + 2 * titleHeight + 2 * snippetHeight + 2 * textLineGap
        let actionsHeight = playButtonSize + actionGap + downloadButtonHeight

        return (2 * verticalPadding + max(artworkSize, actionsHeight, textHeight)).rounded(.up)
    }

    weak var delegate: PodcastEpisodeRowCellDelegate?

    var showsSeparator = true {
        didSet {
            separatorView.isHidden = !showsSeparator
        }
    }

    private let separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let artworkView = PodcastArtworkView()

    private let dateStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = PodcastEpisodeRowCell.statusIndicatorGap
        return stack
    }()

    private let textStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = PodcastEpisodeRowCell.textLineGap
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let statusIndicatorView: UIImageView = {
        let imageView = UIImageView()
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        return imageView
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .subheadline).semibolded
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let snippetLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let downloadButton = PodcastDownloadButton()

    private var isPlaying = false
    private var isUnplayed = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectedBackgroundView = UIView()

        dateStack.addArrangedSubview(statusIndicatorView)
        dateStack.addArrangedSubview(dateLabel)

        textStack.addArrangedSubview(dateStack)
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(snippetLabel)

        contentView.addSubview(separatorView)
        contentView.addSubview(artworkView)
        contentView.addSubview(textStack)
        contentView.addSubview(playButton)
        contentView.addSubview(downloadButton)

        playButton.addTarget(self, action: #selector(didTapPlay), for: .touchUpInside)
        downloadButton.contentEdgeInsets = .zero
        downloadButton.addTarget(self, action: #selector(didTapDownload), for: .touchUpInside)

        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                 constant: PodcastEpisodeRowCell.horizontalPadding),
            artworkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            artworkView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor,
                                             constant: PodcastEpisodeRowCell.verticalPadding),
            artworkView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor,
                                                constant: -PodcastEpisodeRowCell.verticalPadding),
            artworkView.widthAnchor.constraint(equalToConstant: PodcastEpisodeRowCell.artworkSize),
            artworkView.heightAnchor.constraint(equalToConstant: PodcastEpisodeRowCell.artworkSize),

            textStack.leadingAnchor.constraint(equalTo: artworkView.trailingAnchor,
                                               constant: PodcastEpisodeRowCell.artworkTextGap),
            textStack.trailingAnchor.constraint(equalTo: playButton.leadingAnchor,
                                                constant: -PodcastEpisodeRowCell.artworkTextGap),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor,
                                           constant: PodcastEpisodeRowCell.verticalPadding),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor,
                                              constant: -PodcastEpisodeRowCell.verticalPadding),

            playButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -PodcastEpisodeRowCell.horizontalPadding),
            playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor,
                                                constant: -(PodcastEpisodeRowCell.downloadButtonHeight
                                                            + PodcastEpisodeRowCell.actionGap) / 2),
            playButton.widthAnchor.constraint(equalToConstant: PodcastEpisodeRowCell.playButtonSize),
            playButton.heightAnchor.constraint(equalToConstant: PodcastEpisodeRowCell.playButtonSize),
            playButton.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor,
                                            constant: PodcastEpisodeRowCell.verticalPadding),

            downloadButton.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
            downloadButton.topAnchor.constraint(equalTo: playButton.bottomAnchor,
                                                constant: PodcastEpisodeRowCell.actionGap),
            downloadButton.widthAnchor.constraint(equalToConstant: PodcastEpisodeRowCell.downloadButtonWidth),
            downloadButton.heightAnchor.constraint(equalToConstant: PodcastEpisodeRowCell.downloadButtonHeight),
            downloadButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor,
                                                   constant: -PodcastEpisodeRowCell.verticalPadding)
        ])

        isAccessibilityElement = true
        accessibilityTraits = .button

        applyTheme()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applyTheme),
                                               name: .VLCThemeDidChangeNotification,
                                               object: nil)
    }

    func configure(episode: PodcastEpisode,
                   showName: String?,
                   showArtworkURL: URL?,
                   isPlaying: Bool,
                   downloading: Bool) {
        self.isPlaying = isPlaying

        artworkView.configure(name: showName ?? episode.title,
                              artworkURL: episode.artworkURL ?? showArtworkURL,
                              cornerRadius: PodcastEpisodeRowCell.artworkRadius,
                              fontSize: 20)

        isUnplayed = episode.isUnplayed
        let indicatorImage = isUnplayed ? PodcastEpisodeRowCell.unplayedImage
            : (episode.isPlayed ? PodcastEpisodeRowCell.playedImage : nil)
        statusIndicatorView.image = indicatorImage
        statusIndicatorView.isHidden = indicatorImage == nil
        updateStatusIndicatorColor()
        var dateText = episode.date.uppercased()
        if let number = episode.numberText {
            dateText = number + " · " + dateText
        }
        if let time = timeText(for: episode) {
            dateText += " · " + time.uppercased()
        }
        setDateText(dateText, unplayed: isUnplayed)

        titleLabel.text = episode.title

        let snippet = episode.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        snippetLabel.text = snippet
        let hasSnippet = !(snippet?.isEmpty ?? true)
        snippetLabel.isHidden = !hasSnippet

        downloadButton.configure(downloaded: episode.downloaded, downloading: downloading)
        updatePlayButtonImage()

        textStack.alpha = episode.isPlayed ? PodcastEpisodeRowCell.playedAlpha : 1

        var accessibilityComponents = [episode.title]
        if let number = episode.numberText {
            accessibilityComponents.append(number)
        }
        accessibilityComponents.append(episode.date)
        if let time = timeText(for: episode) {
            accessibilityComponents.append(time)
        }
        accessibilityLabel = accessibilityComponents.joined(separator: ", ")
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: NSLocalizedString("PLAY_PAUSE_BUTTON", comment: ""),
                                        target: self,
                                        selector: #selector(didTapPlay)),
            UIAccessibilityCustomAction(name: downloadButton.accessibilityLabel ?? "",
                                        target: self,
                                        selector: #selector(didTapDownload))
        ]
    }

    private func updateStatusIndicatorColor() {
        let colors = PresentationTheme.current.colors
        statusIndicatorView.tintColor = isUnplayed ? colors.orangeUI : colors.cellDetailTextColor
    }

    private func setDateText(_ text: String, unplayed: Bool) {
        let color = unplayed
            ? PresentationTheme.current.colors.orangeUI
            : PresentationTheme.current.colors.cellDetailTextColor
        dateLabel.attributedText = NSAttributedString(string: text,
                                                      attributes: [.kern: 0.2,
                                                                   .font: dateLabel.font as Any,
                                                                   .foregroundColor: color])
    }

    private func timeText(for episode: PodcastEpisode) -> String? {
        if let remaining = episode.remainingText {
            return String(format: NSLocalizedString("PODCAST_TIME_LEFT", comment: ""), remaining)
        }
        return episode.durationText
    }

    private func updatePlayButtonImage() {
        playButton.tintColor = PresentationTheme.current.colors.orangeUI
        playButton.setImage(isPlaying ? PodcastEpisodeRowCell.pauseImage : PodcastEpisodeRowCell.playImage,
                            for: .normal)
    }

    @objc private func didTapPlay() {
        delegate?.podcastEpisodeRowCellDidTapPlay(self)
    }

    @objc private func didTapDownload() {
        if downloadButton.isDownloaded {
            delegate?.podcastEpisodeRowCellDidTapDeleteDownload(self)
        } else {
            delegate?.podcastEpisodeRowCellDidTapDownload(self)
        }
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors
        backgroundColor = colors.background
        contentView.backgroundColor = colors.background
        selectedBackgroundView?.backgroundColor = colors.pageBackground
        separatorView.backgroundColor = colors.mediaCategorySeparatorColor
        updateStatusIndicatorColor()
        setDateText(dateLabel.attributedText?.string ?? "", unplayed: isUnplayed)
        titleLabel.textColor = colors.cellTextColor
        snippetLabel.textColor = colors.lightTextColor
        updatePlayButtonImage()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
        textStack.alpha = 1
    }
}
