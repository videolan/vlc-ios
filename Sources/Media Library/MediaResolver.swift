/*****************************************************************************
 * MediaResolver.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import VLCMediaLibraryKit

enum MediaKind {
    case any
    case song
    case album
    case artist
    case genre
    case playlist
    case video
}

class MediaResolver {
    private let mediaLibraryService: MediaLibraryService

    init(mediaLibraryService: MediaLibraryService) {
        self.mediaLibraryService = mediaLibraryService
    }

    private var medialib: VLCMediaLibrary {
        return mediaLibraryService.medialib
    }

    var isLibraryExposable: Bool {
        return !KeychainCoordinator.passcodeService.hasSecret
    }

    // MARK: - Typed lookups

    func songs(matching query: String) -> [VLCMLMedia]? {
        return medialib.searchAudio(query)
    }

    func videos(matching query: String) -> [VLCMLMedia]? {
        return medialib.searchVideo(query)
    }

    func videoGroups(matching query: String) -> [VLCMLMediaGroup]? {
        return medialib.searchMediaGroups(withPattern: query)
    }

    func albums(matching query: String) -> [VLCMLAlbum]? {
        return medialib.searchAlbums(byPattern: query)
    }

    func artists(matching query: String) -> [VLCMLArtist]? {
        return medialib.searchArtists(byName: query, all: true)
    }

    func genres(matching query: String) -> [VLCMLGenre]? {
        return medialib.searchGenre(byName: query)
    }

    func playlists(matching query: String) -> [VLCMLPlaylist]? {
        return medialib.searchPlaylists(byName: query, of: .all)
    }

    // MARK: - Identifier lookups

    func song(for identifier: VLCMLIdentifier) -> VLCMLMedia? {
        return medialib.media(withIdentifier: identifier)
    }

    func video(for identifier: VLCMLIdentifier) -> VLCMLMedia? {
        guard let media = medialib.media(withIdentifier: identifier), media.type() == .video else {
            return nil
        }
        return media
    }

    func album(for identifier: VLCMLIdentifier) -> VLCMLAlbum? {
        return medialib.album(withIdentifier: identifier)
    }

    func artist(for identifier: VLCMLIdentifier) -> VLCMLArtist? {
        return medialib.artist(withIdentifier: identifier)
    }

    func genre(for identifier: VLCMLIdentifier) -> VLCMLGenre? {
        return medialib.genre(withIdentifier: identifier)
    }

    func playlist(for identifier: VLCMLIdentifier) -> VLCMLPlaylist? {
        return medialib.playlist(withIdentifier: identifier)
    }

    // MARK: - Playable media

    func playableMedia(matching query: String, kind: MediaKind) -> [VLCMLMedia]? {
        switch kind {
        case .song:
            return songs(matching: query)?.first.map { tracks(from: $0) }
        case .album:
            return albums(matching: query)?.first?.files(with: .trackNumber)
        case .artist:
            return artists(matching: query)?.first?.files(with: .album)
        case .genre:
            return genres(matching: query)?.first?.files(with: .album)
        case .playlist:
            return playlists(matching: query)?.first?.files()
        case .video:
            return videoGroups(matching: query)?.first?.files(with: .default, desc: true)
        case .any:
            return playableMediaFromAggregate(matching: query)
        }
    }

    func playableMedia(for identifier: VLCMLIdentifier, kind: MediaKind) -> [VLCMLMedia]? {
        switch kind {
        case .song, .any:
            return song(for: identifier).map { tracks(from: $0) }
        case .album:
            return album(for: identifier)?.files(with: .trackNumber)
        case .artist:
            return artist(for: identifier)?.files(with: .album)
        case .genre:
            return genre(for: identifier)?.files(with: .album)
        case .playlist:
            return playlist(for: identifier)?.files()
        case .video:
            return medialib.mediaGroup(withIdentifier: identifier)?.files(with: .default, desc: true)
        }
    }

    func playableMedia(for url: URL) -> [VLCMLMedia]? {
        guard let media = mediaLibraryService.fetchMedia(with: url) else { return nil }
        return [media]
    }

    @discardableResult
    func setFavorite(_ favorite: Bool, for identifier: VLCMLIdentifier, kind: MediaKind) -> Bool {
        switch kind {
        case .album:
            guard let album = album(for: identifier) else { return false }
            album.favorite = favorite
            return true
        case .artist:
            guard let artist = artist(for: identifier) else { return false }
            artist.favorite = favorite
            return true
        case .genre:
            guard let genre = genre(for: identifier) else { return false }
            genre.favorite = favorite
            return true
        case .playlist:
            guard let playlist = playlist(for: identifier) else { return false }
            playlist.favorite = favorite
            return true
        case .song, .video, .any:
            guard let media = song(for: identifier) else { return false }
            return media.setFavorite(favorite)
        }
    }

    func recommendedAudio() -> [VLCMLMedia]? {
        if let favorites = medialib.audioFiles(with: .default, desc: false, favoriteOnly: true),
           !favorites.isEmpty {
            return favorites
        }
        if let history = medialib.audioHistory(), !history.isEmpty {
            return history
        }
        return medialib.audioFiles()
    }

    func recommendedVideos() -> [VLCMLMedia]? {
        if let favorites = medialib.videoFiles(with: .default, desc: false, favoriteOnly: true),
           !favorites.isEmpty {
            return favorites
        }
        if let history = medialib.videoHistory(), !history.isEmpty {
            return history
        }
        return medialib.videoFiles()
    }

    // MARK: - Private

    private func playableMediaFromAggregate(matching query: String) -> [VLCMLMedia]? {
        let aggregate = medialib.search(query)

        if let playlist = aggregate.playlists?.first {
            return playlist.files()
        }
        if let album = aggregate.albums?.first {
            return album.files(with: .trackNumber)
        }
        if let artist = aggregate.artists?.first {
            return artist.files(with: .album)
        }
        if let genre = aggregate.genres?.first {
            return genre.files(with: .album)
        }
        if let media = aggregate.media?.first {
            if let group = media.group() {
                return group.files(with: .default, desc: true)
            }
            return tracks(from: media)
        }
        return nil
    }

    private func tracks(from media: VLCMLMedia) -> [VLCMLMedia] {
        guard let album = media.album?.files(with: .trackNumber),
              let index = album.firstIndex(where: { $0.trackNumber == media.trackNumber }) else {
            return [media]
        }
        return Array(album[index...])
    }
}
