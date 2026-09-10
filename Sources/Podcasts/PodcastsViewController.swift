/*****************************************************************************
 * PodcastsViewController.swift
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

class PodcastsViewController: UIViewController {
    private enum PodcastSection: Int, CaseIterable {
        case continueListening
        case latestEpisodes
        case shows
    }

    private let store = PodcastStore.shared

    private var isSubscribing = false

    // MARK: Search

    private var isSearching = false
    private var filteredEpisodes: [PodcastEpisode] = []

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = NSLocalizedString("SEARCH", comment: "")
        return searchController
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 76
        tableView.register(ContinueListeningSectionCell.self,
                            forCellReuseIdentifier: ContinueListeningSectionCell.reuseIdentifier)
        tableView.register(VLCOnAirRailCell.self, forCellReuseIdentifier: VLCOnAirRailCell.reuseIdentifier)
        tableView.register(PodcastEpisodeCell.self, forCellReuseIdentifier: PodcastEpisodeCell.reuseIdentifier)
        tableView.register(PodcastSectionHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PodcastSectionHeaderView.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return refreshControl
    }()

    private lazy var subscribeIndicator: UIActivityIndicatorView = {
        let style: UIActivityIndicatorView.Style
#if os(visionOS)
        style = .large
#else
        if #available(iOS 13.0, *) {
            style = .large
        } else {
            style = .whiteLarge
        }
#endif
        let indicator = UIActivityIndicatorView(style: style)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var emptyStateView: PodcastsEmptyStateView = {
        let view = PodcastsEmptyStateView()
        view.onAddViaRSS = { [weak self] in
            self?.presentAddSubscriptionAlert()
        }
        view.onBrowseDirectory = { [weak self] in
            self?.showDirectory()
        }
        return view
    }()

    init(mediaLibraryService: MediaLibraryService) {
        super.init(nibName: nil, bundle: nil)
        PodcastStore.shared.configure(mediaLibraryService: mediaLibraryService)
        setupTabBarItem()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        store.removeObserver(self)
    }

    private func setupTabBarItem() {
        title = NSLocalizedString("ONAIR_PODCASTS", comment: "")
        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(title: title,
                                       image: UIImage(systemName: "mic"),
                                       selectedImage: UIImage(systemName: "mic.fill"))
        } else {
            tabBarItem = UITabBarItem(title: title,
                                       image: nil, selectedImage: nil)
        }
        tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.podcasts
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        definesPresentationContext = true

        setupNavigationBarButtons()

        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(subscribeIndicator)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -20),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            subscribeIndicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            subscribeIndicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])

        tableView.refreshControl = refreshControl

        applyTheme()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(applyTheme),
                                       name: .VLCThemeDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(refreshDidEnd),
                                       name: .VLCPodcastsRefreshDidEnd,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(miniPlayerIsShown),
                                       name: NSNotification.Name(rawValue: VLCPlayerDisplayControllerDisplayMiniPlayer),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(miniPlayerIsHidden),
                                       name: NSNotification.Name(rawValue: VLCPlayerDisplayControllerHideMiniPlayer),
                                       object: nil)
        store.addObserver(self)
        updateContentVisibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PlaybackService.sharedInstance().playerDisplayController.isMiniPlayerVisible
            ? miniPlayerIsShown() : miniPlayerIsHidden()
        updateContentVisibility()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.tableView.reloadData()
        }
    }

    @objc private func miniPlayerIsShown() {
        tableView.setMiniPlayerInset(true)
    }

    @objc private func miniPlayerIsHidden() {
        tableView.setMiniPlayerInset(false)
    }

    @objc private func handleRefresh() {
        if !store.refreshAllSubscriptions() {
            refreshControl.endRefreshing()
        }
    }

    @objc private func refreshDidEnd() {
        refreshControl.endRefreshing()
    }

    private func setupNavigationBarButtons() {
        let searchImage: UIImage?
        let addImage: UIImage?
        if #available(iOS 13.0, *) {
            searchImage = UIImage(systemName: "magnifyingglass")
            addImage = UIImage(systemName: "plus")
        } else {
            searchImage = nil
            addImage = nil
        }

        let searchButton = UIBarButtonItem(image: searchImage, style: .plain, target: self,
                                            action: #selector(didTapSearch))
        searchButton.accessibilityLabel = NSLocalizedString("SEARCH", comment: "")

        let addButton: UIBarButtonItem
        if #available(iOS 14.0, *) {
            addButton = UIBarButtonItem(image: addImage, style: .plain, target: nil, action: nil)
            addButton.menu = addActions().menu()
        } else {
            addButton = UIBarButtonItem(image: addImage, style: .plain, target: self,
                                        action: #selector(didTapAdd(_:)))
        }
        addButton.accessibilityLabel = NSLocalizedString("PODCAST_SUBSCRIBE", comment: "")

        navigationItem.rightBarButtonItems = [addButton, searchButton]
    }

    private func addActions() -> [PodcastMenuAction] {
        return [PodcastMenuAction(title: NSLocalizedString("PODCAST_ADD_VIA_RSS", comment: ""),
                                  imageName: "link") { [weak self] in
                    self?.presentAddSubscriptionAlert()
                },
                PodcastMenuAction(title: NSLocalizedString("PODCAST_DIRECTORY_BROWSE", comment: ""),
                                  imageName: "square.grid.2x2") { [weak self] in
                    self?.showDirectory()
                }]
    }

    private func showDirectory() {
        navigationController?.pushViewController(PodcastDirectoryViewController(), animated: true)
    }

    private func updateContentVisibility() {
        guard !isSearching else {
            tableView.isHidden = false
            emptyStateView.isHidden = true
            return
        }

        let isEmpty = store.shows.isEmpty
        tableView.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty || isSubscribing
    }

    @objc private func applyTheme() {
        view.backgroundColor = PresentationTheme.current.colors.background
        tableView.backgroundColor = PresentationTheme.current.colors.background
        subscribeIndicator.color = PresentationTheme.current.colors.cellTextColor
    }

    @objc private func didTapSearch() {
        navigationItem.searchController = searchController
        searchController.isActive = true
    }

    private func performSearch(_ searchText: String) {
        let allEpisodes = store.continueListeningEpisodes + store.latestEpisodes
        guard !searchText.isEmpty else {
            filteredEpisodes = allEpisodes
            return
        }
        filteredEpisodes = allEpisodes.filter { episode in
            if episode.title.range(of: searchText, options: .caseInsensitive) != nil {
                return true
            }
            return store.show(withId: episode.showId)?.name.range(of: searchText, options: .caseInsensitive) != nil
        }
    }

    private func endSearch() {
        isSearching = false
        filteredEpisodes = []
        searchController.isActive = false
        navigationItem.searchController = nil
        tableView.reloadData()
        updateContentVisibility()
    }

    private func configureEpisodeCell(_ cell: PodcastEpisodeCell, for episode: PodcastEpisode, at indexPath: IndexPath) {
        let show = store.show(withId: episode.showId)
        cell.configure(episode: episode,
                       name: show?.name ?? "",
                       artworkURL: episode.artworkURL ?? show?.artworkURL,
                       showName: show?.name,
                       downloading: store.isDownloading(episodeId: episode.id),
                       onTapArtwork: { [weak self] in
                           self?.openShow(forEpisode: episode)
                       },
                       onDownload: { [weak self] in
                           self?.downloadEpisode(episode, at: indexPath)
                       },
                       onCancelDownload: { [weak self] in
                           self?.cancelDownload(of: episode, at: indexPath)
                       },
                       onDeleteDownload: { [weak self] in
                           self?.confirmDeleteDownload(of: episode, at: indexPath)
                       })
    }

    private func downloadEpisode(_ episode: PodcastEpisode, at indexPath: IndexPath) {
        guard !store.isDownloading(episodeId: episode.id) else {
            return
        }
        store.downloadEpisode(episodeId: episode.id, showId: episode.showId)
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    private func cancelDownload(of episode: PodcastEpisode, at indexPath: IndexPath) {
        guard store.cancelDownload(episodeId: episode.id, showId: episode.showId) else {
            return
        }
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    private func confirmDeleteDownload(of episode: PodcastEpisode, at indexPath: IndexPath) {
        confirmPodcastDownloadDeletion { [weak self] in
            guard let self = self else { return }
            self.store.deleteDownloadedEpisode(episodeId: episode.id, showId: episode.showId)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    @objc private func didTapAdd(_ sender: UIBarButtonItem) {
        addActions().presentActionSheet(title: nil, from: sender, in: self)
    }

    private func presentAddSubscriptionAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("PODCAST_ADD_VIA_RSS", comment: ""),
                                                 message: nil,
                                                 preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = NSLocalizedString("PODCAST_ADD_RSS_PLACEHOLDER", comment: "")
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel)
        let addAction = UIAlertAction(title: NSLocalizedString("PODCAST_SUBSCRIBE", comment: ""),
                                      style: .default) { [weak self, weak alertController] _ in
            guard let self = self else { return }

            let text = alertController?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else {
                self.presentAddSubscriptionError(.emptyInput)
                return
            }
            guard let url = URL(string: text), let scheme = url.scheme, url.host != nil else {
                self.presentAddSubscriptionError(.invalidURL)
                return
            }
            guard scheme == "http" || scheme == "https" else {
                self.presentAddSubscriptionError(.unsupportedScheme)
                return
            }

            self.subscribe(to: [PodcastFeedRequest(url: url)])
        }

        alertController.addAction(cancelAction)
        alertController.addAction(addAction)
        present(alertController, animated: true)
    }

    func subscribe(to feeds: [PodcastFeedRequest]) {
        guard !isSubscribing, !feeds.isEmpty else {
            return
        }

        loadViewIfNeeded()
        beginSubscribing()

        guard feeds.count > 1 else {
            addSubscription(to: feeds[0])
            return
        }

        addSubscriptions(feeds, at: 0, failureCount: 0) { [weak self] failureCount in
            guard let self = self else { return }

            self.endSubscribing()

            guard failureCount > 0 else {
                return
            }

            VLCAlertViewController.alertViewManager(title: NSLocalizedString("PODCAST_SUBSCRIBE", comment: ""),
                                                    errorMessage: String(format: NSLocalizedString("PODCAST_SUBSCRIBE_PARTIAL", comment: ""),
                                                                         failureCount, feeds.count),
                                                    viewController: self)
        }
    }

    private func addSubscription(to feed: PodcastFeedRequest) {
        store.addSubscription(mrl: feed.url) { [weak self] result in
            guard let self = self else { return }

            guard case .failure(let reason) = result else {
                self.endSubscribing()
                return
            }

            guard let fallbackURL = feed.fallbackURL else {
                self.endSubscribing()
                self.presentAddSubscriptionError(reason)
                return
            }

            self.addSubscription(to: PodcastFeedRequest(url: fallbackURL))
        }
    }

    private func addSubscriptions(_ feeds: [PodcastFeedRequest], at index: Int, failureCount: Int,
                                  completion: @escaping (Int) -> Void) {
        guard index < feeds.count else {
            completion(failureCount)
            return
        }

        store.addSubscription(mrl: feeds[index].url) { [weak self] result in
            guard let self = self else { return }

            guard case .failure = result else {
                self.addSubscriptions(feeds, at: index + 1, failureCount: failureCount,
                                      completion: completion)
                return
            }

            guard let fallbackURL = feeds[index].fallbackURL else {
                self.addSubscriptions(feeds, at: index + 1, failureCount: failureCount + 1,
                                      completion: completion)
                return
            }

            self.store.addSubscription(mrl: fallbackURL) { [weak self] fallbackResult in
                guard let self = self else { return }

                var updatedFailureCount = failureCount
                if case .failure = fallbackResult {
                    updatedFailureCount += 1
                }
                self.addSubscriptions(feeds, at: index + 1, failureCount: updatedFailureCount,
                                      completion: completion)
            }
        }
    }

    private func beginSubscribing() {
        isSubscribing = true
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
        subscribeIndicator.startAnimating()
        updateContentVisibility()
    }

    private func endSubscribing() {
        isSubscribing = false
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }
        subscribeIndicator.stopAnimating()
        updateContentVisibility()
    }

    private func presentAddSubscriptionError(_ reason: PodcastAddSubscriptionError) {
        VLCAlertViewController.alertViewManager(title: NSLocalizedString("PODCAST_SUBSCRIBE", comment: ""),
                                                errorMessage: reason.localizedMessage,
                                                viewController: self)
    }

    private func openShow(_ show: PodcastShow) {
        let detailViewController = PodcastShowDetailViewController(show: show)
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    private func openShow(forEpisode episode: PodcastEpisode) {
        guard let show = store.show(withId: episode.showId) else {
            return
        }
        openShow(show)
    }

    private func openEpisode(_ episode: PodcastEpisode) {
        guard let show = store.show(withId: episode.showId) else {
            return
        }
        let detailViewController = PodcastEpisodeDetailViewController(episode: episode, show: show)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

// MARK: - UITableViewDataSource / UITableViewDelegate

extension PodcastsViewController: UITableViewDataSource, UITableViewDelegate {
    private var visibleSections: [PodcastSection] {
        var sections: [PodcastSection] = []
        if !store.continueListeningEpisodes.isEmpty {
            sections.append(.continueListening)
        }
        sections.append(.latestEpisodes)

        if !store.shows.isEmpty {
            sections.append(.shows)
        }
        return sections
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? 1 : visibleSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return filteredEpisodes.count
        }
        switch visibleSections[section] {
        case .continueListening, .shows:
            return 1
        case .latestEpisodes:
            return store.latestEpisodes.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !isSearching else {
            return nil
        }
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: PodcastSectionHeaderView.reuseIdentifier) as? PodcastSectionHeaderView else {
            return nil
        }
        switch visibleSections[section] {
        case .continueListening:
            header.configure(title: NSLocalizedString("PODCAST_CONTINUE_LISTENING", comment: ""))
        case .latestEpisodes:
            header.configure(title: NSLocalizedString("PODCAST_LATEST_EPISODES", comment: ""))
        case .shows:
            header.configure(title: NSLocalizedString("PODCAST_SHOWS", comment: ""))
        }
        return header
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearching {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PodcastEpisodeCell.reuseIdentifier,
                                                           for: indexPath) as? PodcastEpisodeCell else {
                return UITableViewCell()
            }
            configureEpisodeCell(cell, for: filteredEpisodes[indexPath.row], at: indexPath)
            return cell
        }

        switch visibleSections[indexPath.section] {
        case .continueListening:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ContinueListeningSectionCell.reuseIdentifier,
                                                           for: indexPath) as? ContinueListeningSectionCell else {
                return UITableViewCell()
            }

            cell.episodes = store.continueListeningEpisodes
            cell.onSelectEpisode = { [weak self] episode in
                self?.store.playEpisode(episodeId: episode.id, showId: episode.showId)
            }
            return cell
        case .shows:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: VLCOnAirRailCell.reuseIdentifier,
                                                           for: indexPath) as? VLCOnAirRailCell else {
                return UITableViewCell()
            }

            let shows = store.shows
            shows.forEach { store.requestArtwork(for: $0) }
            cell.delegate = self
            cell.configure(items: shows.map { VLCOnAirRailItem(show: $0) }, showsSubtitles: true, showsAddTile: false)
            return cell
        case .latestEpisodes:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PodcastEpisodeCell.reuseIdentifier,
                                                           for: indexPath) as? PodcastEpisodeCell else {
                return UITableViewCell()
            }

            configureEpisodeCell(cell, for: store.latestEpisodes[indexPath.row], at: indexPath)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard !isSearching else {
            return UITableView.automaticDimension
        }
        switch visibleSections[indexPath.section] {
        case .shows:
            return VLCOnAirRailCell.height(withSubtitles: true)
        case .continueListening:
            return ContinueListeningSectionCell.height(forWidth: tableView.bounds.width)
        case .latestEpisodes:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isSearching {
            openShow(forEpisode: filteredEpisodes[indexPath.row])
        } else if visibleSections[indexPath.section] == .latestEpisodes {
            openEpisode(store.latestEpisodes[indexPath.row])
        }
    }
}

// MARK: - VLCOnAirRailCellDelegate

extension PodcastsViewController: VLCOnAirRailCellDelegate {
    func railCell(_ cell: VLCOnAirRailCell, didSelectItemAt index: Int) {
        let shows = store.shows
        guard shows.indices.contains(index) else {
            return
        }
        openShow(shows[index])
    }
}

// MARK: - MediaLibraryBaseModelObserver

extension PodcastsViewController: MediaLibraryBaseModelObserver {
    func mediaLibraryBaseModelReloadView() {
        if isSearching {
            performSearch(searchController.searchBar.text ?? "")
        }
        tableView.reloadData()
        updateContentVisibility()
    }
}

// MARK: - UISearchBarDelegate / UISearchControllerDelegate

extension PodcastsViewController: UISearchBarDelegate, UISearchControllerDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performSearch(searchText)
        isSearching = !searchText.isEmpty
        tableView.reloadData()
        updateContentVisibility()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        endSearch()
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        endSearch()
    }
}
