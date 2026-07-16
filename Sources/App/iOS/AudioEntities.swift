/*****************************************************************************
 * AudioEntities.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

// iOS 27 SDK
#if canImport(MediaIntents)

import AppIntents
import MediaIntents
import VLCMediaLibraryKit

@available(iOS 27, *)
@UnionValue
enum AudioItem {
    case song(SongEntity)
    case album(AlbumEntity)
    case artist(ArtistEntity)
    case playlist(PlaylistEntity)
    case songCollection(SongCollectionEntity)
}

@available(iOS 27, *)
extension AudioItem {
    var playableMedia: [VLCMLMedia]? {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return nil }
        return resolver.playableMedia(for: identifier, kind: kind)
    }

    var entityID: Int {
        switch self {
        case .song(let entity):
            return entity.id
        case .album(let entity):
            return entity.id
        case .artist(let entity):
            return entity.id
        case .playlist(let entity):
            return entity.id
        case .songCollection(let entity):
            return entity.id
        }
    }

    var identifier: VLCMLIdentifier {
        return VLCMLIdentifier(entityID)
    }

    var kind: MediaKind {
        switch self {
        case .song:
            return .song
        case .album:
            return .album
        case .artist:
            return .artist
        case .playlist:
            return .playlist
        case .songCollection:
            return .genre
        }
    }
}

// MARK: - Song

@available(iOS 27, *)
@AppEntity(schema: .audio.song)
struct SongEntity: IndexedEntity {
    static let defaultQuery = SongEntityQuery()

    let id: Int

    @Property(indexingKey: \.title)
    var title: String

    @Property(indexingKey: \.artist)
    var artistName: String

    var composerName: String?

    @Property(indexingKey: \.album)
    var albumTitle: String?

    var artists: [ArtistEntity]
    var album: AlbumEntity?
    var composers: [ArtistEntity]
    var internationalStandardRecordingCode: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(artistName)")
    }

    init(media: VLCMLMedia) {
        id = Int(media.identifier())
        title = media.title
        artistName = media.artist?.artistName() ?? ""
        albumTitle = media.album?.title
        artists = media.artist.map { [ArtistEntity(artist: $0)] } ?? []
        album = media.album.map { AlbumEntity(album: $0) }
        composers = []
    }
}

@available(iOS 27, *)
struct SongEntityQuery: EntityQuery {
    func entities(for identifiers: [Int]) async throws -> [SongEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }
        return identifiers.compactMap { resolver.song(for: VLCMLIdentifier($0)).map(SongEntity.init) }
    }
}

@available(iOS 27, *)
extension SongEntityQuery: IntentValueQuery {
    func values(for audioSearch: AudioSearch) async throws -> [SongEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }

        switch audioSearch.criteria {
        case .searchQuery(let query):
            return (resolver.songs(matching: query) ?? []).map(SongEntity.init)
        case .unspecified:
            return (resolver.recommendedAudio() ?? []).map(SongEntity.init)
        case .url(let urls):
            return urls.compactMap { resolver.playableMedia(for: $0)?.first }.map(SongEntity.init)
        @unknown default:
            return []
        }
    }
}

// MARK: - Album

@available(iOS 27, *)
@AppEntity(schema: .audio.album)
struct AlbumEntity {
    static let defaultQuery = AlbumEntityQuery()

    let id: Int

    var title: String
    var artistName: String
    var artists: [ArtistEntity]
    var universalProductCode: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(artistName)")
    }

    init(album: VLCMLAlbum) {
        id = Int(album.identifier())
        title = album.title
        artistName = album.artists()?.first?.artistName() ?? ""
        artists = (album.artists() ?? []).map(ArtistEntity.init)
    }
}

@available(iOS 27, *)
struct AlbumEntityQuery: EntityQuery {
    func entities(for identifiers: [Int]) async throws -> [AlbumEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }
        return identifiers.compactMap { resolver.album(for: VLCMLIdentifier($0)).map(AlbumEntity.init) }
    }
}

@available(iOS 27, *)
extension AlbumEntityQuery: IntentValueQuery {
    func values(for audioSearch: AudioSearch) async throws -> [AlbumEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }

        switch audioSearch.criteria {
        case .searchQuery(let query):
            return (resolver.albums(matching: query) ?? []).map(AlbumEntity.init)
        default:
            return []
        }
    }
}

// MARK: - Artist

@available(iOS 27, *)
@AppEntity(schema: .audio.artist)
struct ArtistEntity {
    static let defaultQuery = ArtistEntityQuery()

    let id: Int

    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(artist: VLCMLArtist) {
        id = Int(artist.identifier())
        name = artist.name
    }
}

@available(iOS 27, *)
struct ArtistEntityQuery: EntityQuery {
    func entities(for identifiers: [Int]) async throws -> [ArtistEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }
        return identifiers.compactMap { resolver.artist(for: VLCMLIdentifier($0)).map(ArtistEntity.init) }
    }
}

@available(iOS 27, *)
extension ArtistEntityQuery: IntentValueQuery {
    func values(for audioSearch: AudioSearch) async throws -> [ArtistEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }

        switch audioSearch.criteria {
        case .searchQuery(let query):
            return (resolver.artists(matching: query) ?? []).map(ArtistEntity.init)
        default:
            return []
        }
    }
}

// MARK: - Playlist

@available(iOS 27, *)
@UnionValue
enum PlaylistOwner {
    case person(IntentPerson)
    case name(String)
}

@available(iOS 27, *)
@AppEntity(schema: .audio.playlist)
struct PlaylistEntity {
    static let defaultQuery = PlaylistEntityQuery()

    let id: Int

    var title: String
    var owner: PlaylistOwner?
    var createdByMe: Bool?
    var curatedForMe: Bool?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    init(playlist: VLCMLPlaylist) {
        id = Int(playlist.identifier())
        title = playlist.title()
        createdByMe = true
        curatedForMe = false
    }
}

@available(iOS 27, *)
struct PlaylistEntityQuery: EntityQuery {
    func entities(for identifiers: [Int]) async throws -> [PlaylistEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }
        return identifiers.compactMap { resolver.playlist(for: VLCMLIdentifier($0)).map(PlaylistEntity.init) }
    }
}

@available(iOS 27, *)
extension PlaylistEntityQuery: IntentValueQuery {
    func values(for audioSearch: AudioSearch) async throws -> [PlaylistEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }

        switch audioSearch.criteria {
        case .searchQuery(let query):
            return (resolver.playlists(matching: query) ?? []).map(PlaylistEntity.init)
        default:
            return []
        }
    }
}

// MARK: - Genre

@available(iOS 27, *)
@AppEntity(schema: .audio.songCollection)
struct SongCollectionEntity {
    static let defaultQuery = SongCollectionEntityQuery()

    let id: Int

    var title: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title ?? "")")
    }

    init(genre: VLCMLGenre) {
        id = Int(genre.identifier())
        title = genre.name
    }
}

@available(iOS 27, *)
struct SongCollectionEntityQuery: EntityQuery {
    func entities(for identifiers: [Int]) async throws -> [SongCollectionEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }
        return identifiers.compactMap { resolver.genre(for: VLCMLIdentifier($0)).map(SongCollectionEntity.init) }
    }
}

@available(iOS 27, *)
extension SongCollectionEntityQuery: IntentValueQuery {
    func values(for audioSearch: AudioSearch) async throws -> [SongCollectionEntity] {
        let resolver = IntentContext.resolver
        guard resolver.isLibraryExposable else { return [] }

        switch audioSearch.criteria {
        case .searchQuery(let query):
            return (resolver.genres(matching: query) ?? []).map(SongCollectionEntity.init)
        default:
            return []
        }
    }
}

// MARK: - Warmup result

@available(iOS 27, *)
@AppEntity(schema: .audio.warmupAudioQueueResult)
struct WarmupAudioQueueResult: TransientAppEntity {
    var id: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }

    init() {
        id = 0
    }

    init(id: Int) {
        self.id = id
    }
}

#endif
