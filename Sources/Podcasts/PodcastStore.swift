/*****************************************************************************
 * PodcastStore.swift
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

final class PodcastStore {
    static let shared = PodcastStore()

    private(set) var shows: [PodcastShow] = [
        PodcastShow(id: "s1", name: "Lorem Ipsum", publisher: "Dolor Sit", category: "Amet",
                    episodeCount: 142,
                    showDescription: "Consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
        PodcastShow(id: "s2", name: "Consectetur Adipiscing", publisher: "Elit Sed", category: "Eiusmod",
                    episodeCount: 88,
                    showDescription: "Ut enim ad minim veniam quis nostrud exercitation ullamco laboris nisi ut aliquip."),
        PodcastShow(id: "s3", name: "Tempor Incididunt", publisher: "Labore Dolore", category: "Magna",
                    episodeCount: 210,
                    showDescription: "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat."),
        PodcastShow(id: "s4", name: "Aliqua Enim", publisher: "Minim Veniam", category: "Quis",
                    episodeCount: 64,
                    showDescription: "Excepteur sint occaecat cupidatat non proident sunt in culpa qui officia deserunt."),
        PodcastShow(id: "s5", name: "Nostrud Exercitation", publisher: "Ullamco Laboris", category: "Nisi",
                    episodeCount: 305,
                    showDescription: "Mollit anim id est laborum sed ut perspiciatis unde omnis iste natus error.")
    ]

    private(set) var episodes: [PodcastEpisode] = [
        PodcastEpisode(id: "e1", showId: "s1", title: "Sed Do Eiusmod Tempor", date: "Jul 18",
                        duration: "54 min", progress: 0.42, downloaded: true, continueListening: true),
        PodcastEpisode(id: "e2", showId: "s3", title: "Ut Labore Et Dolore", date: "Jul 17",
                        duration: "71 min", progress: 0.18, downloaded: false, continueListening: true),
        PodcastEpisode(id: "e3", showId: "s5", title: "Magna Aliqua Enim Ad", date: "Jul 19",
                        duration: "38 min", progress: 0.65, downloaded: true, continueListening: true),
        PodcastEpisode(id: "e4", showId: "s1", title: "Minim Veniam Quis Nostrud", date: "Jul 15",
                        duration: "49 min", progress: nil, downloaded: false, continueListening: false),
        PodcastEpisode(id: "e5", showId: "s2", title: "Exercitation Ullamco Laboris Nisi", date: "Jul 14",
                        duration: "62 min", progress: nil, downloaded: true, continueListening: false),
        PodcastEpisode(id: "e6", showId: "s4", title: "Aliquip Ex Ea Commodo", date: "Jul 12",
                        duration: "44 min", progress: nil, downloaded: false, continueListening: false),
        PodcastEpisode(id: "e7", showId: "s3", title: "Consequat Duis Aute Irure", date: "Jul 11",
                        duration: "58 min", progress: nil, downloaded: false, continueListening: false),
        PodcastEpisode(id: "e8", showId: "s5", title: "Dolor In Reprehenderit", date: "Jul 10",
                        duration: "33 min", progress: nil, downloaded: true, continueListening: false),
        PodcastEpisode(id: "e9", showId: "s2", title: "Voluptate Velit Esse Cillum", date: "Jul 9",
                        duration: "70 min", progress: nil, downloaded: false, continueListening: false)
    ]

    private var unsubscribedShowIds = Set<String>()

    private init() {}

    // MARK: - Queries

    var continueListeningEpisodes: [PodcastEpisode] {
        return episodes.filter { $0.continueListening }
    }

    var latestEpisodes: [PodcastEpisode] {
        return episodes.filter { !$0.continueListening }
    }

    func show(withId showId: String) -> PodcastShow? {
        return shows.first { $0.id == showId }
    }

    func episodes(forShowId showId: String) -> [PodcastEpisode] {
        return episodes.filter { $0.showId == showId }
    }

    func isSubscribed(showId: String) -> Bool {
        return !unsubscribedShowIds.contains(showId)
    }

    // MARK: - Mutations

    func toggleDownload(episodeId: String) {
        guard let index = episodes.firstIndex(where: { $0.id == episodeId }) else {
            return
        }
        episodes[index].downloaded.toggle()
    }

    func toggleSubscribe(showId: String) {
        if unsubscribedShowIds.contains(showId) {
            unsubscribedShowIds.remove(showId)
        } else {
            unsubscribedShowIds.insert(showId)
        }
    }
}
