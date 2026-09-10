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
    private static let sharedService = VLCPodcastIndexService()

    private let service = PodcastDirectoryViewController.sharedService
    private let store = PodcastStore.shared

    private var shelves: [VLCPodcastIndexShelf] = []
    private var laidOutWidth: CGFloat = 0

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(VLCOnAirRailCell.self, forCellReuseIdentifier: VLCOnAirRailCell.reuseIdentifier)
        tableView.register(PodcastSectionHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PodcastSectionHeaderView.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
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

        setupNavigationBarButtons()
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
        notificationCenter.addObserver(self,
                                       selector: #selector(miniPlayerIsShown),
                                       name: NSNotification.Name(rawValue: VLCPlayerDisplayControllerDisplayMiniPlayer),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(miniPlayerIsHidden),
                                       name: NSNotification.Name(rawValue: VLCPlayerDisplayControllerHideMiniPlayer),
                                       object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true

        service.loadShelvesIfNeeded()

        PlaybackService.sharedInstance().playerDisplayController.isMiniPlayerVisible
            ? miniPlayerIsShown() : miniPlayerIsHidden()
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

    @objc private func miniPlayerIsShown() {
        tableView.setMiniPlayerInset(true)
    }

    @objc private func miniPlayerIsHidden() {
        tableView.setMiniPlayerInset(false)
    }

    private func setupNavigationBarButtons() {
        let languageImage: UIImage?
        let searchImage: UIImage?
        if #available(iOS 14.2, *) {
            languageImage = UIImage(systemName: "globe.europe.africa")
        } else if #available(iOS 13.0, *) {
            languageImage = UIImage(systemName: "globe")
        } else {
            languageImage = nil
        }
        if #available(iOS 13.0, *) {
            searchImage = UIImage(systemName: "magnifyingglass")
        } else {
            searchImage = nil
        }

        let languageButton = UIBarButtonItem(image: languageImage, style: .plain, target: self,
                                             action: #selector(didTapLanguage))
        languageButton.accessibilityLabel = NSLocalizedString("PODCAST_DIRECTORY_LANGUAGE", comment: "")

        let searchButton = UIBarButtonItem(image: searchImage, style: .plain, target: self,
                                           action: #selector(didTapSearch))
        searchButton.accessibilityLabel = NSLocalizedString("SEARCH", comment: "")

        navigationItem.rightBarButtonItems = [searchButton, languageButton]
    }

    @objc private func shelvesDidUpdate() {
        let previous = shelves
        shelves = service.shelves
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
            item.downsamplesArtwork = true
            if store.subscriptionState(forFeedURL: feed.feedURL, title: feed.title) == .subscribed {
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

    private func updateContentState() {
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

    private func backgroundView() -> UIView {
        return VLCRadioErrorView(message: NSLocalizedString("PODCAST_DIRECTORY_ERROR", comment: ""),
                                 retryTarget: self,
                                 retryAction: #selector(retryLoading))
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
        let searchViewController = VLCPodcastDirectoryListViewController(service: service, shelf: nil)
        navigationController?.pushViewController(searchViewController, animated: true)
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

// MARK: - UITableViewDataSource / UITableViewDelegate

extension PodcastDirectoryViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return shelves.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        return VLCOnAirRailCell.height(withTileSide: railTileSide, subtitles: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
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
        refreshVisibleRails()
    }
}
