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

    // Show notes run to several kilobytes and the snippet only ever needs the first couple of lines.
    private static let snippetSourceLength = 500

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMd")
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
    let releaseDate: Date
    let durationValue: Int64
    let progress: Double? // 0 means not started, 1 means finished. `nil` means never played.
    let lastPlayedDate: Date?
    let downloaded: Bool
    let playCount: UInt32
    let seasonNumber: UInt32
    let episodeNumber: UInt32
    let author: String?
    let notesHTML: String?

    init(id: String,
         showId: String,
         title: String,
         artworkURL: URL?,
         releaseDate: Date,
         durationValue: Int64,
         progress: Double?,
         lastPlayedDate: Date?,
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
        self.releaseDate = releaseDate
        self.durationValue = durationValue
        self.progress = progress
        self.lastPlayedDate = lastPlayedDate
        self.downloaded = downloaded
        self.playCount = playCount
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.author = author
        self.notesHTML = notesHTML
    }

    var date: String {
        return PodcastEpisode.dateFormatter.string(from: releaseDate)
    }

    var duration: String {
        return VLCTime(number: NSNumber(value: durationValue)).stringValue
    }

    var notes: String? {
        return PodcastEpisode.snippet(fromNotes: notesHTML)
    }

    var durationText: String? {
        return PodcastEpisode.durationText(forMilliseconds: durationValue)
    }

    var remainingText: String? {
        guard let progress = progress, progress > 0, progress < 1 else {
            return nil
        }
        return PodcastEpisode.durationText(forMilliseconds: Int64(Double(durationValue) * (1 - progress)))
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

// MARK: - PodcastEpisodeSortCriteria

enum PodcastEpisodeSortCriteria: Int, CaseIterable {
    case releaseDate
    case title
    case duration

    var title: String {
        switch self {
        case .releaseDate:
            return NSLocalizedString("RELEASE_DATE", comment: "")
        case .title:
            return NSLocalizedString("TITLE", comment: "")
        case .duration:
            return NSLocalizedString("DURATION", comment: "")
        }
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

// MARK: - PodcastNotes

enum PodcastNotes {
    static func attributedString(from notes: String) -> NSMutableAttributedString {
        let attributedNotes = parsedNotes(from: notes)

        let string = attributedNotes.string as NSString
        let lastCharacter = string.rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines.inverted,
                                                    options: .backwards)
        if lastCharacter.location != NSNotFound {
            let end = lastCharacter.location + lastCharacter.length
            if end < attributedNotes.length {
                attributedNotes.deleteCharacters(in: NSRange(location: end, length: attributedNotes.length - end))
            }
        }

        let range = NSRange(location: 0, length: attributedNotes.length)
        let bodyFont = UIFont.preferredCustomFont(forTextStyle: .callout)

        attributedNotes.enumerateAttribute(.inlinePresentationIntent, in: range, options: []) { value, subrange, _ in
            guard let rawValue = (value as? NSNumber)?.uintValue else {
                return
            }
            let intent = InlinePresentationIntent(rawValue: rawValue)
            var traits: UIFontDescriptor.SymbolicTraits = []
            if intent.contains(.stronglyEmphasized) {
                traits.insert(.traitBold)
            }
            if intent.contains(.emphasized) {
                traits.insert(.traitItalic)
            }
            guard let descriptor = bodyFont.fontDescriptor.withSymbolicTraits(traits) else {
                return
            }
            attributedNotes.addAttribute(.font, value: UIFont(descriptor: descriptor, size: 0), range: subrange)
        }

        attributedNotes.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            let traits = (value as? UIFont)?.fontDescriptor.symbolicTraits ?? []
            guard let descriptor = bodyFont.fontDescriptor.withSymbolicTraits(traits) else {
                attributedNotes.addAttribute(.font, value: bodyFont, range: subrange)
                return
            }
            attributedNotes.addAttribute(.font, value: UIFont(descriptor: descriptor, size: 0), range: subrange)
        }

        attributedNotes.enumerateAttribute(.paragraphStyle, in: range, options: []) { value, subrange, _ in
            let style = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle
                ?? NSMutableParagraphStyle()
            style.lineHeightMultiple = 1.55
            attributedNotes.addAttribute(.paragraphStyle, value: style, range: subrange)
        }

        return attributedNotes
    }

    // Feeds put HTML in content:encoded and, within CDATA, in description and itunes:summary alike.
    // Anything without tags or entities is plain text that the publisher may have written as markdown.
    private static func parsedNotes(from notes: String) -> NSMutableAttributedString {
        if notes.range(of: "<[^>]+>|&[a-zA-Z]+;|&#[0-9]+;", options: .regularExpression) != nil,
           let data = notes.data(using: .utf8),
           let html = try? NSMutableAttributedString(data: data,
                                                     options: [.documentType: NSAttributedString.DocumentType.html,
                                                               .characterEncoding: String.Encoding.utf8.rawValue],
                                                     documentAttributes: nil) {
            return html
        }

        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        guard let markdown = try? AttributedString(markdown: notes, options: options) else {
            return NSMutableAttributedString(string: notes)
        }
        return NSMutableAttributedString(attributedString: NSAttributedString(markdown))
    }
}
