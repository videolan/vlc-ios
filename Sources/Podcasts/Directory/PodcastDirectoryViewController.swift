/*****************************************************************************
 * PodcastDirectoryViewController.swift
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

class PodcastDirectoryViewController: UIViewController {
    private static let railLimit = 25
    private static let searchDelay: TimeInterval = 0.5
    private static let searchCellIdentifier = "LocalNetworkCell"
    private static let sharedService = VLCPodcastIndexService()

    private let service = PodcastDirectoryViewController.sharedService
    private let store = VLCAppCoordinator.sharedInstance().podcastStore

    private var shelves: [VLCPodcastIndexShelf] = []
    private var laidOutWidth: CGFloat = 0

    private var searchQuery = ""
    private var searchResults: [VLCPodcastIndexFeed] = []
    private var searchTask: URLSessionTask?
    private var isSearchLoading = false
    private var searchFailed = false

    private var isSearching: Bool {
        return !searchQuery.isEmpty
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(VLCOnAirRailCell.self, forCellReuseIdentifier: VLCOnAirRailCell.reuseIdentifier)
        tableView.register(UINib(nibName: "VLCNetworkListCell", bundle: nil),
                           forCellReuseIdentifier: PodcastDirectoryViewController.searchCellIdentifier)
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
        searchController.searchBar.placeholder = NSLocalizedString("PODCAST_DIRECTORY_SEARCH_PLACEHOLDER", comment: "")
        searchController.searchBar.autocapitalizationType = .none
        if #available(iOS 26.0, visionOS 26.0, *) {
            searchController.searchBar.searchBarStyle = .minimal
        }
        return searchController
    }()

    private let loadingView = PulsingConeView()

    deinit {
        store.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("PODCAST_DIRECTORY_TITLE", comment: "")
        navigationItem.largeTitleDisplayMode = .always

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        setupNavigationItem()
        applyTheme()

        store.addObserver(self)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(shelvesDidUpdate),
                                       name: NSNotification.Name.VLCPodcastIndexShelvesDidUpdate,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(applyTheme),
                                       name: .VLCThemeDidChangeNotification,
                                       object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true

        service.loadShelvesIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {
            cancelSearch()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = tableView.bounds.width
        guard width != laidOutWidth else {
            return
        }

        laidOutWidth = width
        tableView.reloadData()
    }

    private var railTileSide: CGFloat {
        let width = tableView.bounds.width
        guard width > 0 else {
            return 0
        }

        return VLCRadioFavoritesGridCell.tileWidth(forWidth: width,
                                                   columns: VLCRadioFavoritesGridCell.columns(forWidth: width))
    }

    private func setupNavigationItem() {
        let languageButton = UIBarButtonItem(image: UIImage(systemName: "globe.europe.africa"), style: .plain, target: self,
                                             action: #selector(didTapLanguage))
        languageButton.accessibilityLabel = NSLocalizedString("PODCAST_DIRECTORY_LANGUAGE", comment: "")
        languageButton.accessibilityIdentifier = VLCAccessibilityIdentifier.podcastLanguage

        definesPresentationContext = true

        if #available(iOS 26.0, visionOS 26.0, *) {
            navigationItem.rightBarButtonItems = [languageButton]
            navigationItem.preferredSearchBarPlacement = .integrated
            navigationItem.hidesSearchBarWhenScrolling = true
            navigationItem.searchController = searchController
        } else {
            let searchButton = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self,
                                               action: #selector(didTapSearch))
            searchButton.accessibilityLabel = NSLocalizedString("SEARCH", comment: "")
            navigationItem.rightBarButtonItems = [searchButton, languageButton]
        }
    }

    @objc private func shelvesDidUpdate() {
        let previous = shelves
        shelves = service.shelves

        guard !isSearching else {
            return
        }

        updateContentState()

        if !previous.isEmpty && shelves.count > previous.count
            && zip(previous, shelves).allSatisfy({ $0.title == $1.title }) {
            tableView.insertSections(IndexSet(previous.count..<shelves.count), with: .fade)
        } else {
            tableView.reloadData()
        }
    }

    private func tileItems(for shelf: VLCPodcastIndexShelf) -> [VLCOnAirRailItem] {
        return shelf.feeds.prefix(Self.railLimit).map { feed in
            let item = VLCOnAirRailItem(name: feed.title, artworkURL: feed.artworkURL)
            item.subtitle = feed.subtitle
            if store.subscriptionState(forFeedURL: feed.feedURL) == .subscribed {
                item.accessoryGlyphName = "checkmark"
                item.accessoryLabel = NSLocalizedString("PODCAST_DIRECTORY_SUBSCRIBED", comment: "")
            }
            return item
        }
    }

    private func configure(_ cell: VLCOnAirRailCell, for shelf: VLCPodcastIndexShelf) {
        cell.configure(items: tileItems(for: shelf), showsSubtitles: true, showsAddTile: false)
    }

    private func refreshVisibleRails() {
        for case let cell as VLCOnAirRailCell in tableView.visibleCells {
            guard let indexPath = tableView.indexPath(for: cell), indexPath.section < shelves.count else {
                continue
            }
            configure(cell, for: shelves[indexPath.section])
        }
    }

    private func refreshVisibleSearchResults() {
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            guard indexPath.row < searchResults.count,
                  let cell = tableView.cellForRow(at: indexPath) as? VLCNetworkListCell else {
                continue
            }
            let feed = searchResults[indexPath.row]
            cell.apply(podcastSubscriptionState: store.subscriptionState(forFeedURL: feed.feedURL))
        }
    }

    private func updateContentState() {
        guard !isSearching else {
            updateSearchState()
            return
        }

        guard shelves.isEmpty else {
            loadingView.stopAnimating()
            tableView.backgroundView = nil
            return
        }

        if service.isLoading {
            tableView.backgroundView = loadingView
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
            tableView.backgroundView = backgroundView()
        }
    }

    private func updateSearchState() {
        guard searchResults.isEmpty else {
            loadingView.stopAnimating()
            tableView.backgroundView = nil
            return
        }

        if isSearchLoading {
            tableView.backgroundView = loadingView
            loadingView.startAnimating()
        } else if searchFailed {
            loadingView.stopAnimating()
            tableView.backgroundView = VLCRadioErrorView(message: NSLocalizedString("PODCAST_DIRECTORY_ERROR", comment: ""),
                                                         retryTarget: self,
                                                         retryAction: #selector(retrySearch))
        } else {
            loadingView.stopAnimating()
            tableView.backgroundView = noResultsView()
        }
    }

    private func backgroundView() -> UIView {
        return VLCRadioErrorView(message: NSLocalizedString("PODCAST_DIRECTORY_ERROR", comment: ""),
                                 retryTarget: self,
                                 retryAction: #selector(retryLoading))
    }

    private func noResultsView() -> UIView {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PresentationTheme.current.colors.cellDetailTextColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = NSLocalizedString("PODCAST_DIRECTORY_NO_RESULTS", comment: "")
        return label
    }

    @objc private func retryLoading() {
        service.reloadShelves()
    }

    @objc private func applyTheme() {
        view.backgroundColor = PresentationTheme.current.colors.background
        tableView.backgroundColor = PresentationTheme.current.colors.background
    }

    @objc private func didTapLanguage() {
        let languageViewController = VLCPodcastDirectoryLanguageViewController(service: service)
        navigationController?.pushViewController(languageViewController, animated: true)
    }

    @objc private func didTapSearch() {
        navigationItem.searchController = searchController
        DispatchQueue.main.async { [weak self] in
            self?.searchController.isActive = true
        }
    }

    private func applySearchQuery(_ query: String) {
        guard query != searchQuery else {
            return
        }

        let wasSearching = isSearching
        searchQuery = query
        cancelSearch()

        if isSearching {
            isSearchLoading = true
            perform(#selector(performSearch), with: nil, afterDelay: PodcastDirectoryViewController.searchDelay)
        } else {
            searchResults = []
            searchFailed = false
        }

        if wasSearching != isSearching || searchResults.isEmpty {
            tableView.reloadData()
        }
        updateContentState()
    }

    private func cancelSearch() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        searchTask?.cancel()
        searchTask = nil
        isSearchLoading = false
    }

    @objc private func retrySearch() {
        guard isSearching else {
            return
        }

        isSearchLoading = true
        updateContentState()
        performSearch()
    }

    @objc private func performSearch() {
        let query = searchQuery
        searchTask = service.searchFeeds(matching: query) { [weak self] feeds, error in
            if let error = error as NSError?, error.domain == NSURLErrorDomain, error.code == NSURLErrorCancelled {
                return
            }
            guard let self = self, query == self.searchQuery else {
                return
            }

            self.searchTask = nil
            self.isSearchLoading = false
            self.searchFailed = error != nil
            if error == nil {
                self.searchResults = feeds
            }
            self.tableView.reloadData()
            self.updateContentState()
        }

        if searchTask == nil {
            isSearchLoading = false
            searchFailed = true
            updateContentState()
        }
    }

    private func showDetails(for feed: VLCPodcastIndexFeed) {
        let feedViewController = PodcastDirectoryFeedViewController(feed: feed, service: service)
        navigationController?.pushViewController(feedViewController, animated: true)
    }

    @objc private func didTapSeeAll(_ sender: UIButton) {
        guard sender.tag < shelves.count else {
            return
        }

        let listViewController = VLCPodcastDirectoryListViewController(service: service,
                                                                       shelf: shelves[sender.tag])
        navigationController?.pushViewController(listViewController, animated: true)
    }
}

// MARK: - UISearchResultsUpdating / UISearchControllerDelegate

extension PodcastDirectoryViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        applySearchQuery(searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.becomeFirstResponder()
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        if #unavailable(iOS 26.0, visionOS 26.0) {
            navigationItem.searchController = nil
        }
        applySearchQuery("")
    }
}

// MARK: - UITableViewDataSource / UITableViewDelegate

extension PodcastDirectoryViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? 1 : shelves.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? searchResults.count : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearching {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PodcastDirectoryViewController.searchCellIdentifier,
                                                           for: indexPath) as? VLCNetworkListCell else {
                return UITableViewCell()
            }

            let feed = searchResults[indexPath.row]
            cell.configure(podcastFeed: feed, subscriptionState: store.subscriptionState(forFeedURL: feed.feedURL))
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: VLCOnAirRailCell.reuseIdentifier,
                                                       for: indexPath) as? VLCOnAirRailCell else {
            return UITableViewCell()
        }

        cell.delegate = self
        cell.tileSide = railTileSide
        configure(cell, for: shelves[indexPath.section])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return isSearching ? VLCNetworkListCell.podcastFeedHeight
                           : VLCOnAirRailCell.height(withTileSide: railTileSide, subtitles: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !isSearching,
              let header = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: PodcastSectionHeaderView.reuseIdentifier) as? PodcastSectionHeaderView else {
            return nil
        }

        header.configure(title: shelves[section].title,
                         actionTitle: NSLocalizedString("SEE_ALL", comment: ""),
                         tag: section,
                         target: self,
                         action: #selector(didTapSeeAll(_:)))
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return isSearching ? .leastNormalMagnitude : UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard isSearching, indexPath.row < searchResults.count else {
            return
        }
        showDetails(for: searchResults[indexPath.row])
    }
}

// MARK: - VLCOnAirRailCellDelegate

extension PodcastDirectoryViewController: VLCOnAirRailCellDelegate {
    func railCell(_ cell: VLCOnAirRailCell, didSelectItemAt index: Int) {
        guard let indexPath = tableView.indexPath(for: cell), indexPath.section < shelves.count else {
            return
        }
        let feeds = shelves[indexPath.section].feeds
        guard feeds.indices.contains(index) else {
            return
        }
        showDetails(for: feeds[index])
    }
}

// MARK: - MediaLibraryBaseModelObserver

extension PodcastDirectoryViewController: MediaLibraryBaseModelObserver {
    func mediaLibraryBaseModelReloadView() {
        if isSearching {
            refreshVisibleSearchResults()
        } else {
            refreshVisibleRails()
        }
    }
}
