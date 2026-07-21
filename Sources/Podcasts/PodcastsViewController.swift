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
            // TODO
        }

        view.onAddViaRSS = { [weak self] in
            // TODO
        }
        return view
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        setupTabBarItem()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTabBarItem()
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
        let isEmpty = store.shows.isEmpty
        tableView.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
    }

    @objc private func applyTheme() {
        view.backgroundColor = PresentationTheme.current.colors.background
        tableView.backgroundColor = PresentationTheme.current.colors.background
    }

    @objc private func didTapSearch() {
        // TODO
    }

    @objc private func didTapAdd() {
        // TODO
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
        return visibleSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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

            let episode = store.latestEpisodes[indexPath.row]
            let show = store.show(withId: episode.showId)
            let color = store.swatchColor(forHue: show?.hue ?? 0)
            cell.configure(episode: episode,
                           leading: .artwork(initials: show?.initials ?? "", color: color),
                           showName: show?.name,
                           onToggleDownload: { [weak self] in
                               self?.store.toggleDownload(episodeId: episode.id)
                               tableView.reloadRows(at: [indexPath], with: .none)
                           },
                           onTapLeading: { [weak self] in
                               self?.openShow(forEpisode: episode)
                           })
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if visibleSections[indexPath.section] == .latestEpisodes {
            openShow(forEpisode: store.latestEpisodes[indexPath.row])
        }
    }
}
