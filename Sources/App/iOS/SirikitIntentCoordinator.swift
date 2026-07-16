//
//  SirikitIntentCoordinator.swift
//  VLC-iOS
//
//  Created by Avi Wadhwa on 19/07/23.
//  Copyright © 2023 VideoLAN. All rights reserved.
//

import Foundation
@preconcurrency import Intents
@preconcurrency import VLCMediaLibraryKit

@available(iOS 14.0, *)
class SirikitIntentCoordinator: NSObject {
    private let mediaLibraryService: MediaLibraryService
    private let resolver: MediaResolver
    private let playbackService = PlaybackService.sharedInstance()

    @objc init(mediaLibraryService: MediaLibraryService) {
        self.mediaLibraryService = mediaLibraryService
        self.resolver = MediaResolver(mediaLibraryService: mediaLibraryService)
        super.init()
    }
}

@available(iOS 14.0, *)
extension SirikitIntentCoordinator: INPlayMediaIntentHandling {
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] {
        if let searchItems = intent.mediaSearch, let mediaItem = getIntentMedia(searchItem: searchItems) {
            return [INPlayMediaMediaItemResolutionResult(mediaItemResolutionResult: .success(with: mediaItem))]
        }
        return [INPlayMediaMediaItemResolutionResult(mediaItemResolutionResult: .unsupported())]
    }

    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        guard let item = intent.mediaItems?.first,
              let identifier = item.identifier,
              let vlcIdentifier = VLCMLIdentifier(identifier),
              let kind = mediaKind(for: item.type),
              let media = resolver.playableMedia(for: vlcIdentifier, kind: kind),
              !media.isEmpty else {
            return INPlayMediaIntentResponse(code: .failure, userActivity: nil)
        }

        playbackService.fullscreenSessionRequested = true
        // playbackService runs UI code, hence run on main thread
        DispatchQueue.main.async {
            if let isShuffle = intent.playShuffled {
                PlaybackService.sharedInstance().isShuffleMode = isShuffle
            }
            switch intent.playbackQueueLocation {
            case .unknown, .now:
                PlaybackService.sharedInstance().playCollection(media)
            case .next:
                PlaybackService.sharedInstance().playCollectionNextInQueue(media)
            case .later:
                PlaybackService.sharedInstance().appendCollectionToQueue(media)
            @unknown default:
                PlaybackService.sharedInstance().playCollection(media)
            }
            if let playbackRate = intent.playbackSpeed {
                PlaybackService.sharedInstance().playbackRate = Float(playbackRate)
            }
            PlaybackService.sharedInstance().repeatMode = {
                switch intent.playbackRepeatMode {
                case .unknown, .none:
                    return .doNotRepeat
                case .all:
                    return .repeatAllItems
                case .one:
                    return .repeatCurrentItem
                @unknown default:
                    return .doNotRepeat
                }
            }()
        }

        if media.first?.type() == VLCMLMediaType.video {
            // Opens application for video content
            return INPlayMediaIntentResponse(code: .continueInApp, userActivity: nil)
        }
        // Successful background playback for audio content
        return INPlayMediaIntentResponse(code: .success, userActivity: nil)
    }
}

@available(iOS 14.0, *)
extension SirikitIntentCoordinator: INAddMediaIntentHandling {
    func resolveMediaItems(for intent: INAddMediaIntent) async -> [INAddMediaMediaItemResolutionResult] {
        if intent.mediaSearch?.reference == .currentlyPlaying, let identifier = playbackService.metadata.identifier?.stringValue {
            let media = INMediaItem(identifier: identifier, title: intent.mediaSearch?.mediaName, type: .song, artwork: nil)
            return [INAddMediaMediaItemResolutionResult(mediaItemResolutionResult: .success(with: media))]
        }
        return [INAddMediaMediaItemResolutionResult(mediaItemResolutionResult: .unsupported())]
    }

    func handle(intent: INAddMediaIntent) async -> INAddMediaIntentResponse {
        if let playlistName = intent.mediaDestination?.playlistName,
           let playlist = resolver.playlists(matching: playlistName)?.first,
           let identifier = intent.mediaItems?.first?.identifier,
           let vlcIdentifier = VLCMLIdentifier(identifier) {
            let appendMediaBool = playlist.appendMedia(withIdentifier: vlcIdentifier)
            let responsesCode: INAddMediaIntentResponseCode = appendMediaBool ? .success : .failure
            return .init(code: responsesCode, userActivity: nil)
        }
        return .init(code: .failure, userActivity: nil)
    }
}

@available(iOS 14.0, *)
extension SirikitIntentCoordinator: INSearchForMediaIntentHandling {
    func handle(intent: INSearchForMediaIntent) async -> INSearchForMediaIntentResponse {
        guard let searchItem = intent.mediaSearch, let mediaItem = getIntentMedia(searchItem: searchItem) else {
            return .init(code: .failure, userActivity: nil)
        }
        let response = INSearchForMediaIntentResponse(code: .success, userActivity: nil)
        response.mediaItems = [mediaItem]
        return response
    }
}

@available(iOS 14.0, *)
private extension SirikitIntentCoordinator {
    private func mediaKind(for type: INMediaItemType) -> MediaKind? {
        switch type {
        case .song, .music:
            return .song
        case .album:
            return .album
        case .artist:
            return .artist
        case .genre:
            return .genre
        case .playlist, .podcastPlaylist:
            return .playlist
        case .movie, .tvShow, .tvShowEpisode, .musicVideo:
            return .video
        case .unknown:
            return .any
        default:
            return nil
        }
    }

    private func getIntentMedia(searchItem: INMediaSearch) -> INMediaItem? {
        guard let searchText = searchItem.mediaName else {
            guard let recommended = resolver.recommendedAudio()?.randomElement() else {
                return nil
            }
            return mediaItem(for: recommended)
        }

        switch searchItem.mediaType {
        case .album:
            return resolver.albums(matching: searchText)?.first.map { mediaItem(for: $0) }
        case .artist:
            return resolver.artists(matching: searchText)?.first.map { mediaItem(for: $0) }
        case .music, .song:
            return resolver.songs(matching: searchText)?.first.map { mediaItem(for: $0) }
        case .genre:
            return resolver.genres(matching: searchText)?.first.map { mediaItem(for: $0) }
        case .playlist, .podcastPlaylist:
            return resolver.playlists(matching: searchText)?.first.map { mediaItem(for: $0) }
        case .movie, .tvShow, .tvShowEpisode, .musicVideo:
            return resolver.videoGroups(matching: searchText)?.first.map { mediaItem(for: $0) }
        case .unknown:
            return aggregateMediaItem(matching: searchText)
        default:
            return nil
        }
    }

    private func aggregateMediaItem(matching searchText: String) -> INMediaItem? {
        let searchGeneral = mediaLibraryService.medialib.search(searchText)

        if let playlist = searchGeneral.playlists?.first {
            return mediaItem(for: playlist)
        }
        if let album = searchGeneral.albums?.first {
            return mediaItem(for: album)
        }
        if let artist = searchGeneral.artists?.first {
            return mediaItem(for: artist)
        }
        if let genre = searchGeneral.genres?.first {
            return mediaItem(for: genre)
        }
        if let song = searchGeneral.media?.first {
            if let group = song.group() {
                return mediaItem(for: group)
            }
            return mediaItem(for: song)
        }
        return nil
    }

    private func mediaItem(for media: VLCMLMedia) -> INMediaItem {
        return .init(identifier: String(media.identifier()),
                     title: media.title,
                     type: .song,
                     artwork: nil,
                     artist: media.artist?.artistName())
    }

    private func mediaItem(for album: VLCMLAlbum) -> INMediaItem {
        return .init(identifier: String(album.identifier()),
                     title: album.title,
                     type: .album,
                     artwork: nil,
                     artist: album.artists()?.first?.artistName())
    }

    private func mediaItem(for artist: VLCMLArtist) -> INMediaItem {
        return .init(identifier: String(artist.identifier()),
                     title: artist.name,
                     type: .artist,
                     artwork: nil)
    }

    private func mediaItem(for genre: VLCMLGenre) -> INMediaItem {
        return .init(identifier: String(genre.identifier()),
                     title: genre.name,
                     type: .genre,
                     artwork: nil)
    }

    private func mediaItem(for playlist: VLCMLPlaylist) -> INMediaItem {
        return .init(identifier: String(playlist.identifier()),
                     title: playlist.title(),
                     type: .playlist,
                     artwork: nil)
    }

    private func mediaItem(for group: VLCMLMediaGroup) -> INMediaItem {
        return .init(identifier: String(group.identifier()),
                     title: group.title(),
                     type: .movie,
                     artwork: nil)
    }
}
