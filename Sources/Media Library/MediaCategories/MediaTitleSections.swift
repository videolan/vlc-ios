/*****************************************************************************
 * MediaTitleSections.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class MediaTitleSections {
    private(set) var sections: [(key: String, items: [VLCMLMedia])] = []

    var titles: [String] {
        return sections.map { $0.key }
    }

    func update(with objects: [VLCMLObject], descending: Bool) {
        let items: [VLCMLMedia] = objects as? [VLCMLMedia] ?? []
        let groupedItems: [String: [VLCMLMedia]] = Dictionary(grouping: items) { getSectionInfo(for: $0.title).key }
        sections = groupedItems
            .map { ($0.key, $0.value.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }) }
            .sorted { lhs, rhs in
                return descending
                    ? lhs.key > rhs.key
                    : lhs.key < rhs.key
            }
    }

    func media(at indexPath: IndexPath) -> VLCMLMedia? {
        return sections.objectAtIndex(index: indexPath.section)?.items.objectAtIndex(index: indexPath.row)
    }

    private func getSectionInfo(for title: String) -> (key: String, type: SectionType) {

        guard let first: Character = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: .current)
            .uppercased()
            .first
        else {
            return ("#", .special)
        }

        guard first.isLetter && !first.isEmoji else {
            return ("#", .special)
        }

        guard first.isLatin else {
            return ("\(first)", .nonlatin)

        }

        return ("\(first)", .latin)
    }
}
