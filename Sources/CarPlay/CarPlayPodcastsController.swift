/*****************************************************************************
 * CarPlayPodcastsController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import CarPlay

class CarPlayPodcastsController: VLCCarPlayBrowserController {
    private static let episodePageSize = 20
    private static let loadMoreKey = "loadMore"

    private let store = VLCAppCoordinator.sharedInstance().podcastStore
    private let placeholder = VLCCarPlayBrowserController.placeholder(forSymbol: "mic")

    private var podcastListTemplate: CPListTemplate?
    private var podcastListItems: [String: CPListItem] = [:]
    private var podcastListKeys: [[String]] = []

    private var showListTemplate: CPListTemplate?
    private var showListItems: [String: CPListItem] = [:]
    private var showListKeys: [String] = []
    private var showId: String?
    private var loadedEpisodeCount = 0

    private var updateScheduled = false

    private lazy var loadMoreItem: CPListItem = {
        let item = CPListItem(text: NSLocalizedString("LOAD_MORE", comment: ""), detailText: nil)
        item.handler = { [weak self] _, completion in
            self?.loadMoreEpisodes()
            completion()
        }
        return item
    }()

    @objc func podcastList() -> CPListTemplate {
        podcastListItems = [:]
        let content = podcastSections()
        let template = CPListTemplate(title: NSLocalizedString("ONAIR_PODCASTS", comment: ""),
                                      sections: content.sections)
        podcastListTemplate = template
        podcastListKeys = content.keys
        return template
    }

    @objc func podcastsNeedUpdate() {
        guard !updateScheduled else {
            return
        }
        updateScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateDisplayedLists()
        }
    }

    private func updateDisplayedLists() {
        updateScheduled = false
        let templates = interfaceController.templates
        if let template = podcastListTemplate {
            if templates.contains(template) {
                let content = podcastSections()
                if content.keys != podcastListKeys {
                    template.updateSections(content.sections)
                    podcastListKeys = content.keys
                }
            } else {
                podcastListTemplate = nil
            }
        }
        if let template = showListTemplate, !templates.contains(template) {
            showListTemplate = nil
        }
        updateShowList()
    }

    private func podcastSections() -> (sections: [CPListSection], keys: [[String]]) {
        var sections: [CPListSection] = []
        var keys: [[String]] = []
        var items: [String: CPListItem] = [:]
        var remainingItemCount = Int(VLCCarPlayBrowserController.maximumItemCount())

        func append(_ rows: [(key: String, item: CPListItem)], header: String) {
            guard !rows.isEmpty else {
                return
            }
            sections.append(CPListSection(items: rows.map { $0.item }, header: header, sectionIndexTitle: nil))
            keys.append([header] + rows.map { $0.key })
            rows.forEach { items[$0.key] = $0.item }
            remainingItemCount -= rows.count
        }

        append(store.continueListeningEpisodes.prefix(remainingItemCount).map(overviewRow),
               header: NSLocalizedString("PODCAST_CONTINUE_LISTENING", comment: ""))
        append(store.latestEpisodes.prefix(remainingItemCount).map(overviewRow),
               header: NSLocalizedString("PODCAST_LATEST_EPISODES", comment: ""))
        append(store.shows.prefix(remainingItemCount).map(showRow),
               header: NSLocalizedString("PODCAST_SHOWS", comment: ""))

        podcastListItems = items
        return (sections, keys)
    }

    private func overviewRow(for episode: PodcastEpisode) -> (key: String, item: CPListItem) {
        let show = store.show(withId: episode.showId)
        return episodeRow(for: episode,
                          show: show,
                          detailComponents: [show?.name, timeLeft(for: episode) ?? episode.date],
                          reusing: podcastListItems)
    }

    private func showRow(for show: PodcastShow) -> (key: String, item: CPListItem) {
        let key = "show" + show.id
        let item = podcastListItems[key] ?? makeShowItem(showId: show.id)
        update(item,
               text: show.name,
               detailText: String(format: NSLocalizedString("PODCAST_EPISODE_COUNT", comment: ""), show.episodeCount))

        store.requestArtwork(for: show)
        setArtwork(show.artworkURL, on: item)
        return (key, item)
    }

    private func episodeRow(for episode: PodcastEpisode,
                            show: PodcastShow?,
                            detailComponents: [String?],
                            reusing items: [String: CPListItem]) -> (key: String, item: CPListItem) {
        let key = "episode" + episode.id
        let item = items[key] ?? makeEpisodeItem(episodeId: episode.id, showId: episode.showId)
        update(item, text: episode.title, detailText: detailComponents.compactMap { $0 }.joined(separator: " · "))

        let progress = episode.hasProgress ? episode.progressFraction : 0
        if item.playbackProgress != progress {
            item.playbackProgress = progress
        }

        store.requestArtwork(for: episode)
        if let show = show {
            store.requestArtwork(for: show)
        }
        setArtwork(episode.artworkURL ?? show?.artworkURL, on: item)
        return (key, item)
    }

    private func makeEpisodeItem(episodeId: String, showId: String) -> CPListItem {
        let item = CPListItem(text: nil, detailText: nil, image: placeholder)
        item.handler = { [store] _, completion in
            if store.nowPlayingEpisodeId != episodeId {
                store.playEpisode(episodeId: episodeId, showId: showId)
            } else if !store.isPlaying {
                store.togglePlayPause()
            }
            completion()
        }
        return item
    }

    private func makeShowItem(showId: String) -> CPListItem {
        let item = CPListItem(text: nil, detailText: nil, image: placeholder)
        item.accessoryType = .disclosureIndicator
        item.handler = { [weak self] _, completion in
            self?.openShow(showId: showId)
            completion()
        }
        return item
    }

    private func update(_ item: CPListItem, text: String, detailText: String) {
        if item.text != text {
            item.setText(text)
        }
        if item.detailText != detailText {
            item.setDetailText(detailText)
        }
    }

    private func setArtwork(_ artworkURL: URL?, on item: CPListItem) {
        guard let artworkURL = artworkURL, item.userInfo as? URL != artworkURL else {
            return
        }
        item.userInfo = artworkURL
        VLCCarPlayBrowserController.setArtworkFrom(artworkURL, on: item)
    }

    private func openShow(showId: String) {
        guard let show = store.show(withId: showId) else {
            return
        }

        self.showId = showId
        loadedEpisodeCount = CarPlayPodcastsController.episodePageSize
        showListItems = [:]
        let content = showSection(showId: showId)
        let template = CPListTemplate(title: show.name, sections: [content.section])
        showListTemplate = template
        showListKeys = content.keys
        interfaceController.pushTemplate(withinDepthLimit: template, animated: true)
    }

    private func loadMoreEpisodes() {
        loadedEpisodeCount += CarPlayPodcastsController.episodePageSize
        updateShowList()
    }

    private func updateShowList() {
        guard let template = showListTemplate, let showId = showId else {
            return
        }
        let content = showSection(showId: showId)
        guard content.keys != showListKeys else {
            return
        }
        template.updateSections([content.section])
        showListKeys = content.keys
    }

    private func showSection(showId: String) -> (section: CPListSection, keys: [String]) {
        let show = store.show(withId: showId)
        let maximumItemCount = Int(VLCCarPlayBrowserController.maximumItemCount())
        let count = min(loadedEpisodeCount, maximumItemCount - 1)
        let episodes = store.episodes(forShowId: showId,
                                      sortedBy: store.episodeSortCriteria,
                                      descending: store.episodeSortDescending,
                                      matching: "",
                                      offset: 0,
                                      count: count)

        var rows = episodes.map {
            episodeRow(for: $0,
                       show: show,
                       detailComponents: [$0.date, timeLeft(for: $0) ?? $0.durationText],
                       reusing: showListItems)
        }
        showListItems = Dictionary(rows.map { ($0.key, $0.item) }, uniquingKeysWith: { first, _ in first })

        if count < min(store.episodeCount(forShowId: showId), maximumItemCount - 1) {
            rows.append((key: CarPlayPodcastsController.loadMoreKey, item: loadMoreItem))
        }
        return (CPListSection(items: rows.map { $0.item }), rows.map { $0.key })
    }

    private func timeLeft(for episode: PodcastEpisode) -> String? {
        return episode.remainingText.map { String(format: NSLocalizedString("PODCAST_TIME_LEFT", comment: ""), $0) }
    }
}
