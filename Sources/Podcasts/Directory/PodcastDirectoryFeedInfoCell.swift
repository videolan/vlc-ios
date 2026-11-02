/*****************************************************************************
 * PodcastDirectoryFeedInfoCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class PodcastDirectoryFeedInfoCell: UITableViewCell {
    static let reuseIdentifier = "PodcastDirectoryFeedInfoCell"

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMd")
        return formatter
    }()

    private let detailsLabel = PodcastDirectoryFeedInfoCell.makeFootnoteLabel()
    private let categoriesLabel = PodcastDirectoryFeedInfoCell.makeFootnoteLabel()

    private let summaryTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()

    private lazy var rowsView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [detailsLabel, categoriesLabel, summaryTextView])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.setCustomSpacing(4, after: detailsLabel)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var summaryText: NSMutableAttributedString?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private static func makeFootnoteLabel() -> UILabel {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.addSubview(rowsView)

        NSLayoutConstraint.activate([
            rowsView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            rowsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            rowsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            rowsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        applyTheme()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applyTheme),
                                               name: .VLCThemeDidChangeNotification,
                                               object: nil)
    }

    func configure(feed: VLCPodcastIndexFeed, summary: NSMutableAttributedString?) {
        updateDetails(for: feed)
        summaryText = summary
        updateSummary()
    }

    private func updateDetails(for feed: VLCPodcastIndexFeed) {
        var parts: [String] = []

        if feed.episodeCount > 0 {
            parts.append(String(format: NSLocalizedString("PODCAST_EPISODE_COUNT", comment: ""), feed.episodeCount))
        }

        if let date = feed.lastUpdateDate {
            parts.append(String(format: NSLocalizedString("PODCAST_DIRECTORY_UPDATED", comment: ""),
                                PodcastDirectoryFeedInfoCell.dateFormatter.string(from: date)))
        }

        if let code = feed.language?.components(separatedBy: "-").first,
           let language = Locale.current.localizedString(forLanguageCode: code) {
            parts.append(language.localizedCapitalized)
        }

        if feed.isExplicit {
            parts.append(NSLocalizedString("PODCAST_DIRECTORY_EXPLICIT", comment: ""))
        }

        detailsLabel.text = parts.joined(separator: " · ")
        detailsLabel.isHidden = parts.isEmpty

        let categories = VLCPodcastIndexService.localizedTitles(forCategoryNames: feed.categories)
        categoriesLabel.text = categories.joined(separator: " · ")
        categoriesLabel.isHidden = categories.isEmpty
    }

    private func updateSummary() {
        guard let text = summaryText, text.length > 0 else {
            summaryTextView.isHidden = true
            return
        }

        text.addAttribute(.foregroundColor, value: PresentationTheme.current.colors.cellTextColor,
                          range: NSRange(location: 0, length: text.length))
        summaryTextView.attributedText = text
        summaryTextView.isHidden = false
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors

        backgroundColor = colors.background
        contentView.backgroundColor = colors.background
        detailsLabel.textColor = colors.cellDetailTextColor
        categoriesLabel.textColor = colors.cellDetailTextColor
        summaryTextView.tintColor = colors.orangeUI
        summaryTextView.linkTextAttributes = [.foregroundColor: colors.orangeUI]

        updateSummary()
    }
}
