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
            return episodes.count
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

            let episode = episodes[indexPath.row]
            cell.configure(episode: episode,
                           leading: .playButton,
                           showName: nil,
                           onTapLeading: { [weak self] in
                               guard let self = self else { return }
                               self.store.play(episodeId: episode.id, showId: self.show.id)
                           })
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
