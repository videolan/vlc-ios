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
    let episodeCount: Int
    let artworkURL: URL?
}

// MARK: - PodcastEpisode

struct PodcastEpisode {
    let id: String
    let showId: String
    let title: String
    let date: String
    let duration: String
    let progress: Double? // 0 means not started, 1 means finished. `nil` means never played.
    let downloaded: Bool
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

// MARK: - PodcastAddSubscriptionError

enum PodcastAddSubscriptionError: Error {
    case emptyInput
    case invalidURL
    case unsupportedScheme
    case networkUnreachable
    case httpError(statusCode: Int)
    case notAFeed
    case unknown

    var localizedMessage: String {
        switch self {
        case .emptyInput:
            return NSLocalizedString("PODCAST_ADD_RSS_ERROR_EMPTY", comment: "")
        case .invalidURL:
            return NSLocalizedString("PODCAST_ADD_RSS_ERROR_INVALID_URL", comment: "")
        case .unsupportedScheme:
            return NSLocalizedString("PODCAST_ADD_RSS_ERROR_SCHEME", comment: "")
        case .networkUnreachable:
            return NSLocalizedString("PODCAST_ADD_RSS_ERROR_NETWORK", comment: "")
        case .httpError(let statusCode):
            return String(format: NSLocalizedString("PODCAST_ADD_RSS_ERROR_HTTP", comment: ""), statusCode)
        case .notAFeed:
            return NSLocalizedString("PODCAST_ADD_RSS_ERROR_NOT_A_FEED", comment: "")
        case .unknown:
            return NSLocalizedString("PODCAST_ADD_RSS_ERROR", comment: "")
        }
    }
}
