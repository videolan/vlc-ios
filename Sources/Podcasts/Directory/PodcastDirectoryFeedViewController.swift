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
    private enum Section: Int, CaseIterable {
        case show
        case episodes
    }

    private enum ShowRow: Int, CaseIterable {
        case header
        case info
    }

    private let service: VLCPodcastIndexService
    private let store = VLCAppCoordinator.sharedInstance().podcastStore
    private var feed: VLCPodcastIndexFeed
    private let show: PodcastShow

    private var summaryText: NSMutableAttributedString?
    private var episodes: [VLCPodcastIndexEpisode] = []
    private var playingEpisodeURL: URL?

    private var episodeRowHeight = PodcastEpisodeRowCell.height

    private let subscribeIndicator = PulsingConeView(coneSize: 22)

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44
        tableView.estimatedSectionFooterHeight = 0
        tableView.register(PodcastShowHeaderCell.self, forCellReuseIdentifier: PodcastShowHeaderCell.reuseIdentifier)
        tableView.register(PodcastDirectoryFeedInfoCell.self,
                           forCellReuseIdentifier: PodcastDirectoryFeedInfoCell.reuseIdentifier)
        tableView.register(PodcastEpisodeRowCell.self, forCellReuseIdentifier: PodcastEpisodeRowCell.reuseIdentifier)
        tableView.register(PodcastSectionHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PodcastSectionHeaderView.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    @objc init(feed: VLCPodcastIndexFeed, service: VLCPodcastIndexService) {
        self.feed = feed
        self.service = service
        self.show = PodcastDirectoryFeedViewController.podcastShow(for: feed)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        store.removeObserver(self)
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

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupNavigationBarButtons()
        applyTheme()
        refreshPlayingEpisodeURL()

        store.addObserver(self)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(applyTheme),
                                       name: .VLCThemeDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(contentSizeCategoryDidChange),
                                       name: UIContentSizeCategory.didChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(playbackStateDidChange),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidStart),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(playbackStateDidChange),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidPause),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(playbackStateDidChange),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidResume),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(playbackStateDidChange),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidStop),
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
            self.setupNavigationBarButtons()
            self.tableView.reloadRows(at: [IndexPath(row: ShowRow.info.rawValue, section: Section.show.rawValue)],
                                      with: .none)
        }

        service.loadRecentEpisodes(for: feed) { [weak self] episodes, _ in
            guard let self = self, !episodes.isEmpty else {
                return
            }

            self.episodes = episodes
            self.tableView.reloadSections(IndexSet(integer: Section.episodes.rawValue), with: .none)
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
        tableView.setMiniPlayerInset(true)
    }

    @objc private func miniPlayerIsHidden() {
        tableView.setMiniPlayerInset(false)
    }

    @objc private func contentSizeCategoryDidChange() {
        episodeRowHeight = PodcastEpisodeRowCell.height
        tableView.reloadData()
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

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors

        view.backgroundColor = colors.background
        tableView.backgroundColor = colors.background
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

    private func podcastEpisode(for episode: VLCPodcastIndexEpisode) -> PodcastEpisode {
        return PodcastEpisode(id: String(episode.episodeIdentifier),
                              showId: show.id,
                              title: episode.title,
                              artworkURL: episode.artworkURL,
                              releaseDate: episode.releaseDate,
                              durationValue: Int64(episode.duration * 1000),
                              progress: nil,
                              lastPlayedDate: nil,
                              downloaded: false,
                              playCount: 0,
                              seasonNumber: UInt32(clamping: episode.seasonNumber),
                              episodeNumber: UInt32(clamping: episode.episodeNumber),
                              author: nil,
                              notesHTML: episode.summary)
    }

    private func configure(_ cell: PodcastEpisodeRowCell, at indexPath: IndexPath) {
        let episode = episodes[indexPath.row]
        cell.configure(episode: podcastEpisode(for: episode),
                       showName: feed.title,
                       showArtworkURL: feed.artworkURL,
                       isPlaying: episode.enclosureURL == playingEpisodeURL,
                       downloading: false,
                       inLibrary: false)
        cell.showsSeparator = indexPath.row > 0
        cell.delegate = self
    }

    private var currentEpisodeURL: URL? {
        let playbackService = PlaybackService.sharedInstance()
        return playbackService.playerIsSetup ? playbackService.currentlyPlayingMedia?.url : nil
    }

    private func refreshPlayingEpisodeURL() {
        playingEpisodeURL = PlaybackService.sharedInstance().isPlaying ? currentEpisodeURL : nil
    }

    @objc private func playbackStateDidChange() {
        let previousURL = playingEpisodeURL
        refreshPlayingEpisodeURL()
        guard previousURL != playingEpisodeURL else {
            return
        }

        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            guard Section(rawValue: indexPath.section) == .episodes,
                  let cell = tableView.cellForRow(at: indexPath) as? PodcastEpisodeRowCell else {
                continue
            }
            configure(cell, at: indexPath)
        }
    }

    private func togglePlayback(at index: Int) {
        if currentEpisodeURL == episodes[index].enclosureURL {
            PlaybackService.sharedInstance().playPause()
        } else {
            stream(from: index)
        }
    }

    private func stream(from index: Int) {
        let playsNext = UserDefaults.standard.bool(forKey: kVLCAutomaticallyPlayNextItem)
        let mediaList = VLCMediaList()

        for episode in playsNext ? episodes[index...] : episodes[index...index] {
            guard let media = VLCMedia(url: episode.enclosureURL) else {
                continue
            }

            media.metaData.title = episode.title
            media.metaData.artist = feed.title
            media.metaData.artworkURL = episode.artworkURL ?? feed.artworkURL
            mediaList.add(media)
        }

        let playbackService = PlaybackService.sharedInstance()
        playbackService.expectsAudioOnlyContent = true
        playbackService.fullscreenSessionRequested = episodes[index].isVideo
        playbackService.playMediaList(mediaList, firstIndex: 0, subtitlesFilePath: nil)

        VLCAppCoordinator.sharedInstance().mediaLibraryService.currentlyPlayingCollection = nil
    }
}

// MARK: - PodcastEpisodeRowCellDelegate

extension PodcastDirectoryFeedViewController: PodcastEpisodeRowCellDelegate {
    func podcastEpisodeRowCellDidTapPlay(_ cell: PodcastEpisodeRowCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              Section(rawValue: indexPath.section) == .episodes,
              indexPath.row < episodes.count else {
            return
        }
        togglePlayback(at: indexPath.row)
    }
}

// MARK: - UITableViewDataSource / UITableViewDelegate

extension PodcastDirectoryFeedViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .show:
            return ShowRow.allCases.count
        case .episodes, .none:
            return episodes.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard Section(rawValue: indexPath.section) == .show else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PodcastEpisodeRowCell.reuseIdentifier,
                                                           for: indexPath) as? PodcastEpisodeRowCell else {
                return UITableViewCell()
            }

            configure(cell, at: indexPath)
            return cell
        }

        switch ShowRow(rawValue: indexPath.row) {
        case .header:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PodcastShowHeaderCell.reuseIdentifier,
                                                           for: indexPath) as? PodcastShowHeaderCell else {
                return UITableViewCell()
            }

            _ = cell.configure(show: show)
            return cell
        case .info, .none:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PodcastDirectoryFeedInfoCell.reuseIdentifier,
                                                           for: indexPath) as? PodcastDirectoryFeedInfoCell else {
                return UITableViewCell()
            }

            cell.configure(feed: feed, summary: summaryText)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard Section(rawValue: section) == .episodes, !episodes.isEmpty,
              let header = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: PodcastSectionHeaderView.reuseIdentifier) as? PodcastSectionHeaderView else {
            return nil
        }

        header.configure(title: NSLocalizedString("PODCAST_LATEST_EPISODES", comment: ""))
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Section(rawValue: section) == .episodes && !episodes.isEmpty ? UITableView.automaticDimension
                                                                            : .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Section(rawValue: indexPath.section) == .show ? UITableView.automaticDimension : episodeRowHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return Section(rawValue: indexPath.section) == .show ? 200 : episodeRowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard Section(rawValue: indexPath.section) == .episodes, indexPath.row < episodes.count else {
            return
        }
        togglePlayback(at: indexPath.row)
    }
}

// MARK: - MediaLibraryBaseModelObserver

extension PodcastDirectoryFeedViewController: MediaLibraryBaseModelObserver {
    func mediaLibraryBaseModelReloadView() {
        setupNavigationBarButtons()
    }
}
