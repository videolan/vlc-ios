/*****************************************************************************
 * CurrentlyPlayingCollectionModel.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Mohamed Sliem <mohamedhu99@gmail.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

enum MediaCollectionType: Equatable {
    case album
    case artist
    case mediaGroup(CurrentlyPlayingCollectionInfo)
    case playlist(CurrentlyPlayingCollectionInfo)
    case allSongs

    static func == (lhs: MediaCollectionType, rhs: MediaCollectionType) -> Bool {
        switch (lhs, rhs) {
        case (.album, .album):
            return true
        case (.artist, .artist):
            return true
        case (.allSongs, .allSongs):
            return true
        case let (.mediaGroup(lhsGroup), .mediaGroup(rhsGroup)):
            return lhsGroup.id == rhsGroup.id && lhsGroup.name == rhsGroup.name
        case let (.playlist(lhsPlaylist), .playlist(rhsPlaylist)):
            return lhsPlaylist == rhsPlaylist
        default:
            return false
        }
    }
}

struct CurrentlyPlayingCollectionModel {
    var collectionType: MediaCollectionType
}

struct CurrentlyPlayingCollectionInfo: Equatable {
    var id: Int64
    var name: String
}
