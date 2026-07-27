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
        tableView.register(ShowsSectionCell.self, forCellReuseIdentifier: ShowsSectionCell.reuseIdentifier)
        tableView.register(PodcastEpisodeCell.self, forCellReuseIdentifier: PodcastEpisodeCell.reuseIdentifier)
        tableView.register(PodcastSectionHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PodcastSectionHeaderView.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var emptyStateView: PodcastsEmptyStateView = {
        let view = PodcastsEmptyStateView()
        view.onSearchPodcasts = { [weak self] in
            // TODO: no podcast directory/search API exists yet, only add-by-feed-URL.
        }

        view.onAddViaRSS = { [weak self] in
            self?.presentAddSubscriptionAlert()
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
        title = NSLocalizedString("PODCAST_CONTENT_TITLE", comment: "")
        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(title: NSLocalizedString("PODCAST_CONTENT_TITLE", comment: ""),
                                       image: UIImage(systemName: "mic"),
                                       selectedImage: UIImage(systemName: "mic.fill"))
        } else {
            tabBarItem = UITabBarItem(title: NSLocalizedString("PODCAST_CONTENT_TITLE", comment: ""),
                                       image: nil, selectedImage: nil)
        }
        tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.podcasts
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        setupNavigationBarButtons()

        view.addSubview(tableView)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -20),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])

        applyTheme()
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(applyTheme),
                                                name: .VLCThemeDidChangeNotification,
                                                object: nil)
        store.addObserver(self)
        updateContentVisibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateContentVisibility()
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

        let addButton = UIBarButtonItem(image: addImage, style: .plain, target: self,
                                         action: #selector(didTapAdd))
        addButton.accessibilityLabel = NSLocalizedString("PODCAST_ADD_BUTTON", comment: "")

        navigationItem.rightBarButtonItems = [addButton, searchButton]
    }

    private func updateContentVisibility() {
        guard !isSearching else {
            tableView.isHidden = false
            emptyStateView.isHidden = true
            return
        }
        let isEmpty = store.shows.isEmpty
        tableView.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
    }

    @objc private func applyTheme() {
        view.backgroundColor = PresentationTheme.current.colors.background
        tableView.backgroundColor = PresentationTheme.current.colors.background
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
                       leading: .artwork(name: show?.name ?? "", artworkURL: show?.artworkURL),
                       showName: show?.name,
                       downloading: store.isDownloading(episodeId: episode.id),
                       onTapLeading: { [weak self] in
                           self?.openShow(forEpisode: episode)
                       },
                       onDownload: { [weak self] in
                           self?.downloadEpisode(episode, at: indexPath)
                       },
                       onDeleteDownload: { [weak self] in
                           self?.confirmDeleteDownload(of: episode, at: indexPath)
                       })
    }

    private func downloadEpisode(_ episode: PodcastEpisode, at indexPath: IndexPath) {
        guard !store.isDownloading(episodeId: episode.id) else {
            return
        }
        store.downloadEpisode(episodeId: episode.id, showId: episode.showId) { [weak self] _ in
            self?.tableView.reloadData()
        }
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    private func confirmDeleteDownload(of episode: PodcastEpisode, at indexPath: IndexPath) {
        let alertController = UIAlertController(title: NSLocalizedString("PODCAST_DELETE_DOWNLOAD_TITLE", comment: ""),
                                                 message: NSLocalizedString("PODCAST_DELETE_DOWNLOAD_MESSAGE", comment: ""),
                                                 preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_DELETE", comment: ""),
                                                style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.store.deleteDownloadedEpisode(episodeId: episode.id, showId: episode.showId)
            self.tableView.reloadData()
        })
        present(alertController, animated: true)
    }

    @objc private func didTapAdd() {
        presentAddSubscriptionAlert()
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
        let addAction = UIAlertAction(title: NSLocalizedString("PODCAST_ADD_BUTTON", comment: ""),
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

            self.store.addSubscription(mrl: url) { [weak self] result in
                if case .failure(let reason) = result {
                    self?.presentAddSubscriptionError(reason)
                }
            }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(addAction)
        present(alertController, animated: true)
    }

    private func presentAddSubscriptionError(_ reason: PodcastAddSubscriptionError) {
        VLCAlertViewController.alertViewManager(title: NSLocalizedString("PODCAST_ADD_BUTTON", comment: ""),
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
                self?.openShow(forEpisode: episode)
            }
            return cell
        case .shows:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ShowsSectionCell.reuseIdentifier,
                                                           for: indexPath) as? ShowsSectionCell else {
                return UITableViewCell()
            }

            cell.shows = store.shows
            cell.onSelectShow = { [weak self] show in
                self?.openShow(show)
            }
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isSearching {
            openShow(forEpisode: filteredEpisodes[indexPath.row])
        } else if visibleSections[indexPath.section] == .latestEpisodes {
            openShow(forEpisode: store.latestEpisodes[indexPath.row])
        }
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
