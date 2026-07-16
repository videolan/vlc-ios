/*****************************************************************************
 * VideoEntities.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import AppIntents
import CoreSpotlight
import VLCMediaLibraryKit

@available(iOS 18.4, visionOS 2.4, *)
struct VideoEntity: AppEntity, IndexedEntity {
    static let defaultQuery = VideoEntityQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("VIDEO"))
    }

    let id: Int

    @Property(indexingKey: \.title)
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    init(media: VLCMLMedia) {
        id = Int(media.identifier())
        title = media.title
    }
}

@available(iOS 18.4, visionOS 2.4, *)
struct VideoEntityQuery: EntityStringQuery {
    func entities(for identifiers: [Int]) async throws -> [VideoEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }
        return identifiers.compactMap { resolver.video(for: VLCMLIdentifier($0)).map(VideoEntity.init) }
    }

    func entities(matching string: String) async throws -> [VideoEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }
        return (resolver.videos(matching: string) ?? []).map(VideoEntity.init)
    }

    func suggestedEntities() async throws -> [VideoEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }
        return (resolver.recommendedVideos() ?? []).map(VideoEntity.init)
    }
}
