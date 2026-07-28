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

class PodcastShowDetailViewController: UIViewController {
    private enum PodcastShowSection: Int, CaseIterable {
        case header
        case episodes
    }

    private let show: PodcastShow
    private let store = PodcastStore.shared

    private weak var headerView: PodcastShowHeaderView?

    private var episodes: [PodcastEpisode] {
        return store.episodes(forShowId: show.id)
    }

    // Shows can have thousands of episodes (VLCMLSubscription has no paged query, unlike the
    // audio/video tabs' VLCMediaLibrary calls), so only reveal kVLCDefaultPageSize at a time and
    // grow the window as the user scrolls near the end, mirroring MediaCategoryViewController's
    // willDisplay/kVLCPrefetchDistance pattern.
    private var revealedEpisodeCount = Int(kVLCDefaultPageSize)

    private var visibleEpisodes: [PodcastEpisode] {
        return Array(episodes.prefix(revealedEpisodeCount))
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 76
        tableView.register(PodcastShowHeaderCell.self, forCellReuseIdentifier: PodcastShowHeaderCell.reuseIdentifier)
        tableView.register(PodcastEpisodeCell.self, forCellReuseIdentifier: PodcastEpisodeCell.reuseIdentifier)
        tableView.register(PodcastSectionHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PodcastSectionHeaderView.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    init(show: PodcastShow) {
        self.show = show
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
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(applyTheme),
                                                name: .VLCThemeDidChangeNotification,
                                                object: nil)
        store.addObserver(self)
    }

    deinit {
        store.removeObserver(self)
    }

    @objc private func applyTheme() {
        view.backgroundColor = PresentationTheme.current.colors.background
        tableView.backgroundColor = PresentationTheme.current.colors.background
    }

    private func downloadEpisode(_ episode: PodcastEpisode, at indexPath: IndexPath) {
        guard !store.isDownloading(episodeId: episode.id) else {
            return
        }
        store.downloadEpisode(episodeId: episode.id, showId: show.id) { [weak self] _ in
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
            self.store.deleteDownloadedEpisode(episodeId: episode.id, showId: self.show.id)
            self.tableView.reloadData()
        })
        present(alertController, animated: true)
    }
}

// MARK: - MediaLibraryBaseModelObserver

extension PodcastShowDetailViewController: MediaLibraryBaseModelObserver {
    func mediaLibraryBaseModelReloadView() {
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
            return 1
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

        header.configure(title: NSLocalizedString("EPISODES", comment: ""))
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return PodcastShowSection(rawValue: section) == .episodes ? UITableView.automaticDimension : .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch PodcastShowSection(rawValue: indexPath.section) {
        case .header:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PodcastShowHeaderCell.reuseIdentifier,
                                                           for: indexPath) as? PodcastShowHeaderCell else {
                return UITableViewCell()
            }

            headerView = cell.configure(show: show) { [weak self] in
                guard let self = self else { return }
                self.store.toggleSubscribe(showId: self.show.id)
                self.headerView?.refreshSubscribeState()
            }
            return cell
        case .episodes, .none:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PodcastEpisodeCell.reuseIdentifier,
                                                           for: indexPath) as? PodcastEpisodeCell else {
                return UITableViewCell()
            }

            let episode = visibleEpisodes[indexPath.row]
            cell.configure(episode: episode,
                           leading: .playButton,
                           showName: nil,
                           downloading: store.isDownloading(episodeId: episode.id),
                           onTapLeading: { [weak self] in
                               guard let self = self else { return }
                               self.store.play(episodeId: episode.id, showId: self.show.id)
                           },
                           onDownload: { [weak self] in
                               self?.downloadEpisode(episode, at: indexPath)
                           },
                           onDeleteDownload: { [weak self] in
                               self?.confirmDeleteDownload(of: episode, at: indexPath)
                           })
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
