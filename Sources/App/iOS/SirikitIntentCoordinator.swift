//
//  SirikitIntentCoordinator.swift
//  VLC-iOS
//
//  Created by Avi Wadhwa on 19/07/23.
//  Copyright © 2023 VideoLAN. All rights reserved.
//

import Foundation
import Intents

@available(iOS 14.0, *)
class SirikitIntentCoordinator: NSObject {
    private let mediaLibraryService: MediaLibraryService
    private let playbackService = PlaybackService.sharedInstance()
    
    @objc init(mediaLibraryService: MediaLibraryService) {
        self.mediaLibraryService = mediaLibraryService
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
        if let item = intent.mediaItems?.first, let identifier = item.identifier, let vlcIdentifier = Int64(identifier),
        let media = getMediaArrayFromIdentifier(identifier: vlcIdentifier, type: item.type) {
            playbackService.fullscreenSessionRequested = true
            // playbackService runs UI code, hence run on main thread
            DispatchQueue.main.async {
                if let isShuffle = intent.playShuffled {
                    self.playbackService.isShuffleMode = isShuffle
                }
                switch intent.playbackQueueLocation {
                case .unknown, .now:
                    self.playbackService.playCollection(media)
                case .next:
                    self.playbackService.playCollectionNextInQueue(media)
                case .later:
                    self.playbackService.appendCollectionToQueue(media)
                @unknown default:
                    fatalError()
                }
                if let playbackRate = intent.playbackSpeed {
                    self.playbackService.playbackRate = Float(playbackRate)
                }
                self.playbackService.repeatMode = {
                    switch intent.playbackRepeatMode {
                        case .unknown, .none:
                            return .doNotRepeat
                        case .all:
                            return .repeatAllItems
                        case .one:
                            return .repeatCurrentItem
                        @unknown default:
                            fatalError()
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
        return INPlayMediaIntentResponse(code: .failure, userActivity: nil)
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
        if let playlistName = intent.mediaDestination?.playlistName, let playlist = mediaLibraryService.medialib.searchPlaylists(byName: playlistName)?.first, let identifier = intent.mediaItems?.first?.identifier, let vlcIdentifier = Int64(identifier) {
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
        // programmatically search for a particular media using intent.mediaSearch?.mediaName and intent.mediaSearch?.mediaType
        return .init(code: .failure, userActivity: nil)
    }
    
    
}


@available(iOS 14.0, *)
private extension SirikitIntentCoordinator {
    private func getIntentMedia(searchItem: INMediaSearch) -> INMediaItem? {
        guard let searchText = searchItem.mediaName else {
            if let randomSong = mediaLibraryService.medialib.audioFiles()?.randomElement() {
                return .init(identifier: String(randomSong.identifier()), title: randomSong.title, type: .song, artwork: nil, artist: randomSong.artist?.artistName())
            }
            return nil
        }
        switch searchItem.mediaType {
        case .album:
            if let album = mediaLibraryService.medialib.searchAlbums(byPattern: searchText)?.first {
                return .init(identifier: String(album.identifier()), title: album.title, type: .album, artwork: nil, artist: album.artists()?.first?.artistName())
            }
        case .artist:
            if let artist = mediaLibraryService.medialib.searchArtists(byName: searchText, all: true)?.first {
                return .init(identifier: String(artist.identifier()), title: artist.name, type: .artist, artwork: nil)
            }
        case .music, .song:
            if let song = mediaLibraryService.medialib.searchMedia(searchText)?.first {
                return .init(identifier: String(song.identifier()), title: song.title, type: .song, artwork: nil, artist: song.artist?.artistName())
            }
        case .genre:
            if let genre = mediaLibraryService.medialib.searchGenre(byName: searchText)?.first {
                return .init(identifier: String(genre.identifier()), title: genre.name, type: .genre, artwork: nil)
            }
        case .playlist, .podcastPlaylist:
            if let playlist = mediaLibraryService.medialib.searchPlaylists(byName: searchText)?.first {
                return .init(identifier: String(playlist.identifier()), title: playlist.title(), type: .playlist, artwork: nil)
            }
        case .unknown:
            let searchGeneral = mediaLibraryService.medialib.search(searchText)
            if let playlist = searchGeneral.playlists?.first {
                return .init(identifier: String(playlist.identifier()), title: playlist.title(), type: .playlist, artwork: nil)
            } else if let album = searchGeneral.albums?.first {
                return .init(identifier: String(album.identifier()), title: album.title, type: .album, artwork: nil, artist: album.artists()?.first?.artistName())
            } else if let artist = searchGeneral.artists?.first {
                return .init(identifier: String(artist.identifier()), title: artist.name, type: .artist, artwork: nil)
            } else if let genre = searchGeneral.genres?.first {
                return .init(identifier: String(genre.identifier()), title: genre.name, type: .genre, artwork: nil)
            } else if let song = searchGeneral.media?.first {
                if let group = song.group() {
                    return .init(identifier: String(group.identifier()), title: group.title(), type: .movie, artwork: nil)
                }
                return .init(identifier: String(song.identifier()), title: song.title, type: .song, artwork: nil, artist: song.artist?.artistName())
            }
        case .podcastShow, .podcastEpisode, .audioBook:
            // unsure if supported
            return nil
        case .movie, .tvShow, .tvShowEpisode, .musicVideo:
            if let searchText = searchItem.mediaName, let video = mediaLibraryService.medialib.searchMediaGroups(withPattern: searchText)?.first {
                return .init(identifier: String(video.identifier()), title: video.title(), type: .movie, artwork: nil)
            }
        case .station, .musicStation, .radioStation, .podcastStation, .algorithmicRadioStation, .news:
            // never supported
            return nil
        @unknown default:
            return nil
        }
        return nil
    }
    
    private func getMediaArrayFromIdentifier(identifier: VLCMLIdentifier, type: INMediaItemType) -> [VLCMLMedia]? {
        switch type {
        case .unknown:
        fatalError()
                
        case .song, .music:
            if let song = mediaLibraryService.medialib.media(withIdentifier: identifier) {
                if let album = song.album?.files(with: .trackNumber, desc: false), let songIndex = album.firstIndex(where: { $0.trackNumber == song.trackNumber }) {
                    return Array(album[songIndex...])
                    
                }
            return [song]
        }
                
        case .album:
        if let album = mediaLibraryService.medialib.album(withIdentifier: identifier), let files = album.files() {
            return files
        }
                
        case .artist:
        if let artist = mediaLibraryService.medialib.artist(withIdentifier: identifier), let files = artist.files() {
            return files
        }
                
        case .genre:
        if let genre = mediaLibraryService.medialib.genre(withIdentifier: identifier), let files = genre.files() {
            return files
        }
                
        case .playlist, .podcastPlaylist:
        if let playlist = mediaLibraryService.medialib.playlist(withIdentifier: identifier), let files = playlist.files() {
            return files
        }
                
        case .podcastShow, .podcastEpisode, .musicStation, .audioBook, .podcastStation, .radioStation, .station, .algorithmicRadioStation, .news:
        fatalError()
        case .movie, .tvShow, .tvShowEpisode, .musicVideo:
        if let videos = mediaLibraryService.medialib.mediaGroup(withIdentifier: identifier), let files = videos.files(with: .default, desc: true) {
            return files
        }
                
        @unknown default:
            fatalError()
        }
        fatalError()
    }
}
