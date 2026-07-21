/*****************************************************************************
 * PodcastModels.swift
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

// MARK: - PodcastShow

struct PodcastShow {
    let id: String
    let name: String
    let publisher: String
    let category: String
    let episodeCount: Int
    let hue: CGFloat
    let initials: String
    let showDescription: String
}

// MARK: - PodcastEpisode

struct PodcastEpisode {
    let id: String
    let showId: String
    let title: String
    let date: String
    let duration: String
    let progress: Double? // 0 means not started, 1 means finished. `nil` means never played.
    var downloaded: Bool
    let continueListening: Bool

    var hasProgress: Bool {
        guard let progress = progress else {
            return false
        }
        return progress > 0 && progress < 1
    }

    var progressFraction: CGFloat {
        return CGFloat(progress ?? 0)
    }
}
