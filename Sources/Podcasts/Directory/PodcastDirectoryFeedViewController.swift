/*****************************************************************************
 * PodcastDirectoryFeedViewController.swift
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

class PodcastDirectoryFeedViewController: UIViewController {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMd")
        return formatter
    }()

    private let service: VLCPodcastIndexService
    private let store = PodcastStore.shared
    private var feed: VLCPodcastIndexFeed

    private var summaryText: NSMutableAttributedString?

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let headerView: PodcastShowHeaderView

    private let subscribeIndicator = PulsingConeView(coneSize: 22)

    private let detailsLabel = PodcastDirectoryFeedViewController.makeFootnoteLabel()
    private let categoriesLabel = PodcastDirectoryFeedViewController.makeFootnoteLabel()

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

    @objc init(feed: VLCPodcastIndexFeed, service: VLCPodcastIndexService) {
        self.feed = feed
        self.service = service
        self.headerView = PodcastShowHeaderView(show: PodcastDirectoryFeedViewController.podcastShow(for: feed))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        store.removeObserver(self)
    }

    private static func makeFootnoteLabel() -> UILabel {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    private static func podcastShow(for feed: VLCPodcastIndexFeed) -> PodcastShow {
        return PodcastShow(id: String(feed.feedIdentifier),
                           name: feed.title,
                           episodeCount: feed.episodeCount,
                           artworkURL: feed.artworkURL,
                           websiteURL: feed.websiteURL,
                           author: feed.author)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = feed.title
        navigationItem.largeTitleDisplayMode = .never

        setupUI()
        updateContent()
        applyTheme()

        store.addObserver(self)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(applyTheme),
                                       name: .VLCThemeDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(miniPlayerIsShown),
                                       name: NSNotification.Name(rawValue: VLCPlayerDisplayControllerDisplayMiniPlayer),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(miniPlayerIsHidden),
                                       name: NSNotification.Name(rawValue: VLCPlayerDisplayControllerHideMiniPlayer),
                                       object: nil)

        service.loadDetails(for: feed) { [weak self] feed, _ in
            guard let self = self, let feed = feed else {
                return
            }

            self.feed = feed
            if let summary = feed.summary, !summary.isEmpty {
                self.summaryText = PodcastNotes.attributedString(from: summary)
            }
            self.updateContent()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = false
        setupNavigationBarButtons()

        PlaybackService.sharedInstance().playerDisplayController.isMiniPlayerVisible
            ? miniPlayerIsShown() : miniPlayerIsHidden()
    }

    @objc private func miniPlayerIsShown() {
        scrollView.setMiniPlayerInset(true)
    }

    @objc private func miniPlayerIsHidden() {
        scrollView.setMiniPlayerInset(false)
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerView)
        contentView.addSubview(rowsView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            rowsView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            rowsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            rowsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            rowsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func setupNavigationBarButtons() {
        var items = [subscriptionBarButton()]

        if feed.websiteURL != nil {
            items.append(barButton(symbolName: "safari",
                                   title: NSLocalizedString("PODCAST_OPEN_WEBSITE", comment: ""),
                                   action: #selector(didTapWebsite)))
        }

        navigationItem.rightBarButtonItems = items
    }

    private func subscriptionBarButton() -> UIBarButtonItem {
        switch store.subscriptionState(forFeedURL: feed.feedURL) {
        case .available:
            return barButton(symbolName: "plus",
                             title: NSLocalizedString("PODCAST_SUBSCRIBE", comment: ""),
                             action: #selector(didTapSubscribe))
        case .pending:
            subscribeIndicator.startAnimating()
            return UIBarButtonItem(customView: subscribeIndicator)
        case .subscribed:
            return barButton(symbolName: "checkmark",
                             title: NSLocalizedString("PODCAST_UNSUBSCRIBE", comment: ""),
                             action: #selector(didTapUnsubscribe))
        }
    }

    private func barButton(symbolName: String, title: String, action: Selector) -> UIBarButtonItem {
        if let image = UIImage(systemName: symbolName) {
            let item = UIBarButtonItem(image: image, style: .plain, target: self, action: action)
            item.accessibilityLabel = title
            return item
        }

        return UIBarButtonItem(title: title, style: .plain, target: self, action: action)
    }

    private func updateContent() {
        setupNavigationBarButtons()
        updateDetails()
        updateSummary()
    }

    private func updateDetails() {
        var parts: [String] = []

        if feed.episodeCount > 0 {
            parts.append(String(format: NSLocalizedString("PODCAST_EPISODE_COUNT", comment: ""), feed.episodeCount))
        }

        if let date = feed.lastUpdateDate {
            parts.append(String(format: NSLocalizedString("PODCAST_DIRECTORY_UPDATED", comment: ""),
                                PodcastDirectoryFeedViewController.dateFormatter.string(from: date)))
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

        view.backgroundColor = colors.background
        scrollView.backgroundColor = colors.background
        detailsLabel.textColor = colors.cellDetailTextColor
        categoriesLabel.textColor = colors.cellDetailTextColor
        summaryTextView.tintColor = colors.orangeUI
        summaryTextView.linkTextAttributes = [.foregroundColor: colors.orangeUI]

        updateSummary()
    }

    @objc private func didTapSubscribe() {
        store.addSubscription(mrl: feed.feedURL) { [weak self] result in
            guard let self = self, case .failure(let error) = result else {
                return
            }

            VLCAlertViewController.alertViewManager(title: NSLocalizedString("PODCAST_SUBSCRIBE", comment: ""),
                                                    errorMessage: error.localizedMessage,
                                                    viewController: self)
        }
    }

    @objc private func didTapUnsubscribe() {
        let cancel = VLCAlertButton(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel)
        let unsubscribe = VLCAlertButton(title: NSLocalizedString("PODCAST_UNSUBSCRIBE", comment: ""),
                                         style: .destructive) { [weak self] _ in
            guard let self = self, let show = self.store.show(forFeedURL: self.feed.feedURL) else {
                return
            }

            self.store.unsubscribe(showId: show.id)
        }

        VLCAlertViewController.alertViewManager(title: NSLocalizedString("PODCAST_UNSUBSCRIBE", comment: ""),
                                                errorMessage: NSLocalizedString("PODCAST_UNSUBSCRIBE_MESSAGE",
                                                                                comment: ""),
                                                viewController: self,
                                                buttonsAction: [cancel, unsubscribe])
    }

    @objc private func didTapWebsite() {
        guard let websiteURL = feed.websiteURL else {
            return
        }

        UIApplication.shared.open(websiteURL)
    }
}

// MARK: - MediaLibraryBaseModelObserver

extension PodcastDirectoryFeedViewController: MediaLibraryBaseModelObserver {
    func mediaLibraryBaseModelReloadView() {
        setupNavigationBarButtons()
    }
}
