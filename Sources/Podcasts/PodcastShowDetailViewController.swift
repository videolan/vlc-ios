/*****************************************************************************
 * PodcastShowDetailViewController.swift
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

private enum PodcastEpisodeSortCriteria: Int, CaseIterable {
    case releaseDate
    case title
    case duration

    var title: String {
        switch self {
        case .releaseDate:
            return NSLocalizedString("RELEASE_DATE", comment: "")
        case .title:
            return NSLocalizedString("TITLE", comment: "")
        case .duration:
            return NSLocalizedString("DURATION", comment: "")
        }
    }
}

class PodcastShowDetailViewController: UIViewController {
    private enum PodcastShowSection: Int, CaseIterable {
        case header
        case episodes
    }

    private let show: PodcastShow
    private let store = PodcastStore.shared

    private weak var headerView: PodcastShowHeaderView?

    private var sortCriteria: PodcastEpisodeSortCriteria
    private var sortDescending: Bool

    private var cachedEpisodes: [PodcastEpisode]?

    private var playingEpisodeId: String?

    private var searchQuery = ""

    private var isSearching: Bool {
        return !searchQuery.isEmpty
    }

    private var episodes: [PodcastEpisode] {
        if let cachedEpisodes = cachedEpisodes {
            return cachedEpisodes
        }

        var episodes = store.episodes(forShowId: show.id)
        if isSearching {
            episodes = episodes.filter { matchesSearchQuery($0) }
        }

        let sorted: [PodcastEpisode]
        switch sortCriteria {
        case .releaseDate:
            sorted = episodes.sorted { $0.releaseDate < $1.releaseDate }
        case .title:
            sorted = episodes.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .duration:
            sorted = episodes.sorted { $0.durationValue < $1.durationValue }
        }

        let result = sortDescending ? Array(sorted.reversed()) : sorted
        cachedEpisodes = result
        return result
    }

    private func matchesSearchQuery(_ episode: PodcastEpisode) -> Bool {
        if episode.title.localizedStandardContains(searchQuery) {
            return true
        }
        guard let notes = episode.notes else {
            return false
        }
        return notes.localizedStandardContains(searchQuery)
    }

    // Shows can have thousands of episodes (VLCMLSubscription has no paged query, unlike the
    // audio/video tabs' VLCMediaLibrary calls), so only reveal kVLCDefaultPageSize at a time and
    // grow the window as the user scrolls near the end, mirroring MediaCategoryViewController's
    // willDisplay/kVLCPrefetchDistance pattern.
    private var revealedEpisodeCount = Int(kVLCDefaultPageSize)

    private var visibleEpisodes: ArraySlice<PodcastEpisode> {
        return episodes.prefix(revealedEpisodeCount)
    }

    private var isNavigationTitleVisible = false
    private var headerTitleBottomOffset: CGFloat?

    private var episodeRowHeight = PodcastEpisodeRowCell.height

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44
        tableView.estimatedSectionFooterHeight = 0
        tableView.register(PodcastShowHeaderCell.self, forCellReuseIdentifier: PodcastShowHeaderCell.reuseIdentifier)
        tableView.register(PodcastEpisodeRowCell.self, forCellReuseIdentifier: PodcastEpisodeRowCell.reuseIdentifier)
        tableView.register(PodcastSectionHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PodcastSectionHeaderView.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("SEARCH", comment: "")
        if #available(iOS 26.0, visionOS 26.0, *) {
            searchController.searchBar.searchBarStyle = .minimal
        }
        return searchController
    }()

    init(show: PodcastShow) {
        self.show = show
        let userDefaults = UserDefaults.standard
        if let rawCriteria = userDefaults.object(forKey: "\(kVLCSortDefault)podcastEpisodes") as? Int,
           let criteria = PodcastEpisodeSortCriteria(rawValue: rawCriteria) {
            self.sortCriteria = criteria
        } else {
            self.sortCriteria = .releaseDate
        }
        if userDefaults.object(forKey: "\(kVLCSortDescendingDefault)podcastEpisodes") != nil {
            self.sortDescending = userDefaults.bool(forKey: "\(kVLCSortDescendingDefault)podcastEpisodes")
        } else {
            self.sortDescending = true
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        applyTheme()

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

        store.addObserver(self)
        store.prefetchArtwork(forShowId: show.id)
        refreshPlayingEpisodeId()
        setupNavigationBarButtons()
        setupSearchController()

        navigationItem.backBarButtonItem = UIBarButtonItem(title: NSLocalizedString("EPISODES", comment: ""),
                                                           style: .plain,
                                                           target: nil,
                                                           action: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateNavigationTitleVisibility()
    }

    private func updateNavigationTitleVisibility() {
        if let headerView = headerView, headerView.titleFrame.height > 0 {
            headerTitleBottomOffset = headerView.titleFrame.maxY
        }

        guard let headerTitleBottomOffset = headerTitleBottomOffset else {
            return
        }

        let headerIndexPath = IndexPath(row: 0, section: PodcastShowSection.header.rawValue)
        let titleBottom = tableView.rectForRow(at: headerIndexPath).minY + headerTitleBottomOffset
        let navigationBarBottom = tableView.contentOffset.y + tableView.adjustedContentInset.top

        let shouldBeVisible = isSearching || titleBottom <= navigationBarBottom
        guard shouldBeVisible != isNavigationTitleVisible else {
            return
        }
        isNavigationTitleVisible = shouldBeVisible

        let transition = CATransition()
        transition.duration = 0.2
        transition.type = .fade
        navigationController?.navigationBar.layer.add(transition, forKey: nil)
        title = shouldBeVisible ? show.name : nil
    }

    @objc private func contentSizeCategoryDidChange() {
        episodeRowHeight = PodcastEpisodeRowCell.height
        tableView.reloadData()
    }

    @objc private func playbackStateDidChange() {
        let previousEpisodeId = playingEpisodeId
        refreshPlayingEpisodeId()
        guard previousEpisodeId != playingEpisodeId else {
            return
        }
        tableView.reloadSections(IndexSet(integer: PodcastShowSection.episodes.rawValue), with: .none)
    }

    private func setupNavigationBarButtons() {
        let overflowButton = UIBarButtonItem()
        if #available(iOS 26.0, *) {
            overflowButton.image = UIImage(systemName: "ellipsis")
        } else {
            overflowButton.image = UIImage(named: "EllipseCircle")
        }
        overflowButton.accessibilityLabel = NSLocalizedString("BUTTON_MENU", comment: "")
        if #available(iOS 14.0, *) {
            overflowButton.menu = overflowActions.menu()
        } else {
            overflowButton.target = self
            overflowButton.action = #selector(showOverflowActionSheet)
        }
        var rightBarButtonItems = [overflowButton]

        if #unavailable(iOS 26) {
            let searchImage: UIImage?
            if #available(iOS 13.0, *) {
                searchImage = UIImage(systemName: "magnifyingglass")
            } else {
                searchImage = nil
            }

            let searchButton = UIBarButtonItem(image: searchImage, style: .plain, target: self,
                                               action: #selector(didTapSearch))
            searchButton.accessibilityLabel = NSLocalizedString("SEARCH", comment: "")
            rightBarButtonItems.insert(searchButton, at: 0)
        }

        navigationItem.rightBarButtonItems = rightBarButtonItems
    }

    // iOS 26 keeps the search field in the title bar itself; older systems reveal it from the
    // search button, mirroring the podcasts overview.
    private func setupSearchController() {
        if #available(iOS 26.0, visionOS 26.0, *) {
            navigationItem.preferredSearchBarPlacement = .integrated
            navigationItem.hidesSearchBarWhenScrolling = true
            navigationItem.searchController = searchController
        }
        definesPresentationContext = true
    }

    @objc private func didTapSearch() {
        navigationItem.searchController = searchController
        DispatchQueue.main.async { [weak self] in
            self?.searchController.isActive = true
        }
    }

    private var overflowActions: [PodcastMenuAction] {
        var actions = [
            PodcastMenuAction(title: NSLocalizedString("PODCAST_MARK_ALL_AS_PLAYED", comment: ""),
                              imageName: "checkmark.circle") { [weak self] in self?.markAllEpisodesAsPlayed() }
        ]

        if show.websiteURL != nil {
            actions.append(PodcastMenuAction(title: NSLocalizedString("PODCAST_OPEN_WEBSITE", comment: ""),
                                             imageName: "safari") { [weak self] in self?.openWebsite() })
        }

        actions.append(PodcastMenuAction(title: NSLocalizedString("PODCAST_UNSUBSCRIBE", comment: ""),
                                         imageName: "xmark.circle",
                                         isDestructive: true) { [weak self] in self?.confirmUnsubscribe() })
        return actions
    }

    @objc private func showOverflowActionSheet(_ sender: UIBarButtonItem) {
        overflowActions.presentActionSheet(title: show.name, from: sender, in: self)
    }

    private func markAllEpisodesAsPlayed() {
        store.markAllEpisodes(ofShowId: show.id, played: true)
    }

    private func openWebsite() {
        guard let websiteURL = show.websiteURL else {
            return
        }
        UIApplication.shared.open(websiteURL)
    }

    private func confirmUnsubscribe() {
        let cancel = VLCAlertButton(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel)
        let unsubscribe = VLCAlertButton(title: NSLocalizedString("PODCAST_UNSUBSCRIBE", comment: ""),
                                         style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.store.unsubscribe(showId: self.show.id)
            self.navigationController?.popViewController(animated: true)
        }
        VLCAlertViewController.alertViewManager(title: NSLocalizedString("PODCAST_UNSUBSCRIBE", comment: ""),
                                                errorMessage: NSLocalizedString("PODCAST_UNSUBSCRIBE_MESSAGE",
                                                                                comment: ""),
                                                viewController: self,
                                                buttonsAction: [cancel, unsubscribe])
    }

    @available(iOS 14.0, *)
    private func generateSortMenu() -> UIMenu {
        var sortActions: [UIMenuElement] = []
        for criterion in PodcastEpisodeSortCriteria.allCases {
            let isCurrentSort = criterion == sortCriteria
            let chevronImageName = sortDescending ? "chevron.down" : "chevron.up"
            let actionImage = isCurrentSort ? UIImage(systemName: chevronImageName) : nil

            let action = UIAction(title: criterion.title,
                                  image: actionImage,
                                  state: isCurrentSort ? .on : .off,
                                  handler: { [weak self] _ in
                guard let self = self else { return }
                self.executeSortAction(with: criterion, desc: !self.sortDescending)
            })
            sortActions.append(action)
        }

        if #available(iOS 15.0, *) {
            return UIMenu(title: NSLocalizedString("SORT_BY", comment: ""),
                          image: UIImage(named: "sort"),
                          options: .singleSelection,
                          children: sortActions)
        } else {
            return UIMenu(title: NSLocalizedString("SORT_BY", comment: ""), options: .displayInline, children: sortActions)
        }
    }

    private func executeSortAction(with criteria: PodcastEpisodeSortCriteria, desc: Bool) {
        sortCriteria = criteria
        sortDescending = desc
        revealedEpisodeCount = Int(kVLCDefaultPageSize)
        cachedEpisodes = nil

        let userDefaults = UserDefaults.standard
        userDefaults.set(criteria.rawValue, forKey: "\(kVLCSortDefault)podcastEpisodes")
        userDefaults.set(desc, forKey: "\(kVLCSortDescendingDefault)podcastEpisodes")

        tableView.reloadData()
    }

    deinit {
        store.removeObserver(self)
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors
        view.backgroundColor = colors.background
        tableView.backgroundColor = colors.background
        searchController.searchBar.backgroundColor = colors.background

        if #unavailable(iOS 26) {
            if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField,
               let backgroundView = textField.subviews.first {
                backgroundView.backgroundColor = colors.background
                backgroundView.layer.cornerRadius = 10
                backgroundView.clipsToBounds = true
            }
        }
    }

    private func refreshPlayingEpisodeId() {
        playingEpisodeId = store.isPlaying ? store.nowPlayingEpisodeId : nil
    }

    private func togglePlayback(of episode: PodcastEpisode) {
        if store.nowPlayingEpisodeId == episode.id {
            store.togglePlayPause()
        } else {
            store.play(episodeId: episode.id, showId: show.id)
        }
    }

    private func downloadEpisode(_ episode: PodcastEpisode, at indexPath: IndexPath) {
        guard !store.isDownloading(episodeId: episode.id) else {
            return
        }
        store.downloadEpisode(episodeId: episode.id, showId: show.id)
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    private func confirmDeleteDownload(of episode: PodcastEpisode, at indexPath: IndexPath) {
        confirmPodcastDownloadDeletion { [weak self] in
            guard let self = self else { return }
            self.store.deleteDownloadedEpisode(episodeId: episode.id, showId: self.show.id)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

// MARK: - PodcastEpisodeRowCellDelegate

extension PodcastShowDetailViewController: PodcastEpisodeRowCellDelegate {
    private func episode(for cell: PodcastEpisodeRowCell) -> (PodcastEpisode, IndexPath)? {
        guard let indexPath = tableView.indexPath(for: cell),
              PodcastShowSection(rawValue: indexPath.section) == .episodes,
              indexPath.row < visibleEpisodes.count else {
            return nil
        }
        return (visibleEpisodes[indexPath.row], indexPath)
    }

    func podcastEpisodeRowCellDidTapPlay(_ cell: PodcastEpisodeRowCell) {
        guard let (episode, _) = episode(for: cell) else {
            return
        }
        togglePlayback(of: episode)
    }

    func podcastEpisodeRowCellDidTapDownload(_ cell: PodcastEpisodeRowCell) {
        guard let (episode, indexPath) = episode(for: cell) else {
            return
        }
        downloadEpisode(episode, at: indexPath)
    }

    func podcastEpisodeRowCellDidTapDeleteDownload(_ cell: PodcastEpisodeRowCell) {
        guard let (episode, indexPath) = episode(for: cell) else {
            return
        }
        confirmDeleteDownload(of: episode, at: indexPath)
    }
}

// MARK: - UISearchResultsUpdating / UISearchControllerDelegate

extension PodcastShowDetailViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        applySearchQuery(searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.becomeFirstResponder()
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        if #unavailable(iOS 26) {
            navigationItem.searchController = nil
        }
        applySearchQuery("")
    }

    private func applySearchQuery(_ query: String) {
        guard query != searchQuery else {
            return
        }

        searchQuery = query
        revealedEpisodeCount = Int(kVLCDefaultPageSize)
        cachedEpisodes = nil
        tableView.reloadData()
        updateNavigationTitleVisibility()
    }
}

// MARK: - MediaLibraryBaseModelObserver

extension PodcastShowDetailViewController: MediaLibraryBaseModelObserver {
    func mediaLibraryBaseModelReloadView() {
        cachedEpisodes = nil
        refreshPlayingEpisodeId()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource / UITableViewDelegate

extension PodcastShowDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return PodcastShowSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch PodcastShowSection(rawValue: section) {
        case .header:
            return isSearching ? 0 : 1
        case .episodes, .none:
            return visibleEpisodes.count
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard PodcastShowSection(rawValue: section) == .episodes else {
            return nil
        }

        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: PodcastSectionHeaderView.reuseIdentifier) as? PodcastSectionHeaderView else {
            return nil
        }

        let title = NSLocalizedString("EPISODES", comment: "")
        if #available(iOS 14.0, *) {
            header.configure(title: title, sortTitle: sortCriteria.title, sortMenu: generateSortMenu())
        } else {
            header.configure(title: title)
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return PodcastShowSection(rawValue: indexPath.section) == .header ? 320 : episodeRowHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return PodcastShowSection(rawValue: section) == .episodes ? UITableView.automaticDimension : .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch PodcastShowSection(rawValue: indexPath.section) {
        case .header:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PodcastShowHeaderCell.reuseIdentifier,
                                                           for: indexPath) as? PodcastShowHeaderCell else {
                return UITableViewCell()
            }

            store.requestArtwork(for: show)
            headerView = cell.configure(show: show)
            return cell
        case .episodes, .none:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PodcastEpisodeRowCell.reuseIdentifier,
                                                           for: indexPath) as? PodcastEpisodeRowCell else {
                return UITableViewCell()
            }

            let episode = visibleEpisodes[indexPath.row]
            store.requestArtwork(for: episode)
            cell.configure(episode: episode,
                           showName: show.name,
                           showArtworkURL: show.artworkURL,
                           isPlaying: episode.id == playingEpisodeId,
                           downloading: store.isDownloading(episodeId: episode.id))
            cell.showsSeparator = indexPath.row > 0
            cell.delegate = self
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard PodcastShowSection(rawValue: indexPath.section) == .episodes else {
            return
        }
        let episode = visibleEpisodes[indexPath.row]
        let detailViewController = PodcastEpisodeDetailViewController(episode: episode, show: show)
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationTitleVisibility()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard PodcastShowSection(rawValue: indexPath.section) == .episodes else {
            return
        }
        let revealedCount = visibleEpisodes.count
        guard revealedCount < episodes.count, indexPath.row >= revealedCount - Int(kVLCPrefetchDistance) else {
            return
        }
        revealedEpisodeCount += Int(kVLCDefaultPageSize)
        tableView.reloadData()
    }
}
