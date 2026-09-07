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
    let websiteURL: URL?
    let author: String?
}

// MARK: - PodcastEpisode

struct PodcastEpisode {
    private static let playedThreshold = 0.95

    // Show notes run to several kilobytes; the snippet only ever needs the first couple of lines,
    // so cap the input before flattening it for every episode of every subscription.
    private static let snippetSourceLength = 500

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }()

    private static let htmlTagExpression = try? NSRegularExpression(pattern: "<[^>]*>|<[^>]*$")
    private static let whitespaceExpression = try? NSRegularExpression(pattern: "\\s+")

    private static let htmlEntities = ["&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">",
                                       "&quot;": "\"", "&apos;": "'", "&#39;": "'",
                                       "&hellip;": "…", "&mdash;": "—", "&ndash;": "–",
                                       "&lsquo;": "‘", "&rsquo;": "’", "&ldquo;": "“", "&rdquo;": "”"]

    let id: String
    let showId: String
    let title: String
    let artworkURL: URL?
    let date: String
    let releaseDate: Date
    let duration: String
    let durationValue: Int64
    let progress: Double? // 0 means not started, 1 means finished. `nil` means never played.
    let downloaded: Bool
    let playCount: UInt32
    let seasonNumber: UInt32
    let episodeNumber: UInt32
    let author: String?
    let notes: String?
    let notesHTML: String?
    let durationText: String?
    let remainingText: String?

    init(id: String,
         showId: String,
         title: String,
         artworkURL: URL?,
         date: String,
         releaseDate: Date,
         duration: String,
         durationValue: Int64,
         progress: Double?,
         downloaded: Bool,
         playCount: UInt32,
         seasonNumber: UInt32,
         episodeNumber: UInt32,
         author: String?,
         notesHTML: String?) {
        self.id = id
        self.showId = showId
        self.title = title
        self.artworkURL = artworkURL
        self.date = date
        self.releaseDate = releaseDate
        self.duration = duration
        self.durationValue = durationValue
        self.progress = progress
        self.downloaded = downloaded
        self.playCount = playCount
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.author = author
        self.notesHTML = notesHTML
        self.notes = PodcastEpisode.snippet(fromNotes: notesHTML)
        self.durationText = PodcastEpisode.durationText(forMilliseconds: durationValue)

        if let progress = progress, progress > 0, progress < 1 {
            let remaining = Double(durationValue) * (1 - progress)
            self.remainingText = PodcastEpisode.durationText(forMilliseconds: Int64(remaining))
        } else {
            self.remainingText = nil
        }
    }

    var numberText: String? {
        guard episodeNumber > 0 else {
            return nil
        }
        if seasonNumber > 0 {
            return String(format: "S%02uE%02u", seasonNumber, episodeNumber)
        }
        return "#\(episodeNumber)"
    }

    var continueListening: Bool {
        return hasProgress
    }

    var hasProgress: Bool {
        guard let progress = progress else {
            return false
        }
        return progress > 0 && progress < 1
    }

    var progressFraction: CGFloat {
        return CGFloat(progress ?? 0)
    }

    var isUnplayed: Bool {
        return playCount == 0 && progress == nil
    }

    var isPlayed: Bool {
        if let progress = progress, progress >= PodcastEpisode.playedThreshold {
            return true
        }
        return playCount > 0 && !continueListening
    }

    private static func durationText(forMilliseconds milliseconds: Int64) -> String? {
        guard milliseconds > 0 else {
            return nil
        }
        return durationFormatter.string(from: TimeInterval(milliseconds) / 1000)
    }

    private static func snippet(fromNotes notes: String?) -> String? {
        guard let notes = notes else {
            return nil
        }

        var text = String(notes.prefix(snippetSourceLength))
        if let htmlTagExpression = htmlTagExpression {
            text = htmlTagExpression.stringByReplacingMatches(in: text,
                                                              range: NSRange(text.startIndex..., in: text),
                                                              withTemplate: " ")
        }
        for (entity, replacement) in htmlEntities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }
        if let whitespaceExpression = whitespaceExpression {
            text = whitespaceExpression.stringByReplacingMatches(in: text,
                                                                 range: NSRange(text.startIndex..., in: text),
                                                                 withTemplate: " ")
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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
