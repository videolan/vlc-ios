//
//  PlaybackCacheHelper.swift
//  VLC-iOS
//
//  Created by mohamed sliem on 30/06/2024.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

import Foundation

class PlaybackCacheHelper {
    static let shared = PlaybackCacheHelper()

    private var queuePlayerPlaylistInfo: [VLCMLIdentifier: LastPlayed] = [:]

    func appendCurrentlyPlayingMediaInfoQueue(media: VLCMLMedia, _ playlistInfo: LastPlayed) {
        queuePlayerPlaylistInfo.updateValue(playlistInfo, forKey: media.identifier())
    }

    func appendCurrentlyPlayingPlaylistInfoQueue(medias: [VLCMLMedia], _ playlistInfo: LastPlayed) {
        medias.forEach { media in
            queuePlayerPlaylistInfo.updateValue(playlistInfo, forKey: media.identifier())
        }
    }

    func getCurrentPlaylistMediasQueue() -> [VLCMLIdentifier: LastPlayed] {
        return queuePlayerPlaylistInfo
    }

    func clearQueuePlaylistInfo() {
        queuePlayerPlaylistInfo.removeAll()
    }
}
