/*****************************************************************************
 * RadioStationEntity.swift
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
import Foundation

@available(iOS 16.0, visionOS 1.0, *)
struct RadioStationEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("RADIO"))
    static var defaultQuery = RadioStationQuery()

    /// The stream URL, which is how a favorite is identified everywhere else too.
    var id: String

    @Property(title: LocalizedStringResource("TITLE"))
    var name: String

    var artworkURL: String?

    var displayRepresentation: DisplayRepresentation {
        // stations advertising a favicon are common, but ImageIO decodes neither .ico nor .svg
        let undecodable = ["ico", "svg"]
        if let artworkURL, let url = URL(string: artworkURL),
           !undecodable.contains(url.pathExtension.lowercased()) {
            return DisplayRepresentation(title: "\(name)", image: .init(url: url))
        }

        let placeholder = VLCPlaceholderArtwork.placeholderImage(forName: name,
                                                                 size: CGSize(width: 120.0, height: 120.0),
                                                                 cornerRadius: 0.0,
                                                                 fontSize: 48.0)
        guard let data = placeholder.pngData() else {
            return DisplayRepresentation(title: "\(name)",
                                         image: .init(systemName: "antenna.radiowaves.left.and.right"))
        }
        return DisplayRepresentation(title: "\(name)", image: .init(data: data))
    }

    init(id: String, name: String, artworkURL: String?) {
        self.id = id
        self.name = name
        self.artworkURL = artworkURL
    }

    /// Ordered with the most recently played station first.
    @MainActor
    static var radioFavorites: [VLCFavorite] {
        return VLCAppCoordinator.sharedInstance().favoriteService.favoritesInGroup(withIdentifier: VLCFavoriteGroupRadio)
    }

    init(favorite: VLCFavorite) {
        self.init(id: favorite.url.absoluteString,
                  name: favorite.userVisibleName,
                  artworkURL: favorite.artworkURL?.absoluteString)
    }

    @MainActor
    func play() async throws {
        guard let url = URL(string: id),
              let media = VLCMedia(url: url) else {
            throw IntentError.noMatchingMedia
        }

        media.metaData.title = name
        if let artworkURL, let parsedArtworkURL = URL(string: artworkURL) {
            media.metaData.artworkURL = parsedArtworkURL
        }

        let mediaList = VLCMediaList()
        mediaList.add(media)
        _ = await PlaybackService.sharedInstance().playMediaList(mediaList, firstIndex: 0, subtitlesFilePath: nil)
    }
}

@available(iOS 16.0, visionOS 1.0, *)
struct RadioStationQuery: EntityStringQuery {
    /// Lets the Shortcuts station picker filter as the user types.
    @MainActor
    func entities(matching string: String) async throws -> [RadioStationEntity] {
        return RadioStationEntity.radioFavorites
            .filter { $0.userVisibleName.localizedCaseInsensitiveContains(string) }
            .map { RadioStationEntity(favorite: $0) }
    }

    @MainActor
    func entities(for identifiers: [String]) async throws -> [RadioStationEntity] {
        let favorites = RadioStationEntity.radioFavorites
        return identifiers.map { identifier in
            if let favorite = favorites.first(where: { $0.url.absoluteString == identifier }) {
                return RadioStationEntity(favorite: favorite)
            }
            // the station is no longer a favorite, but an alarm scheduled for it must still play
            return RadioStationEntity(id: identifier,
                                      name: URL(string: identifier)?.host ?? identifier,
                                      artworkURL: nil)
        }
    }

    @MainActor
    func suggestedEntities() async throws -> [RadioStationEntity] {
        return RadioStationEntity.radioFavorites.map { RadioStationEntity(favorite: $0) }
    }
}
