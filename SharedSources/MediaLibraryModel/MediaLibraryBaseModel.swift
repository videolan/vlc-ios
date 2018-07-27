/*****************************************************************************
 * MediaLibraryBaseModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

extension Notification.Name {
    static let VLCMoviesDidChangeNotification = Notification.Name("MoviesDidChangeNotfication")
    static let VLCEpisodesDidChangeNotification = Notification.Name("EpisodesDidChangeNotfication")
    static let VLCArtistsDidChangeNotification = Notification.Name("ArtistsDidChangeNotfication")
    static let VLCAlbumsDidChangeNotification = Notification.Name("AlbumsDidChangeNotfication")
    static let VLCTracksDidChangeNotification = Notification.Name("TracksDidChangeNotfication")
    static let VLCGenresDidChangeNotification = Notification.Name("GenresDidChangeNotfication")
    static let VLCAudioPlaylistsDidChangeNotification = Notification.Name("AudioPlaylistsDidChangeNotfication")
    static let VLCVideoPlaylistsDidChangeNotification = Notification.Name("VideoPlaylistsDidChangeNotfication")
    static let VLCVideosDidChangeNotification = Notification.Name("VideosDidChangeNotfication")
    static let VLCAudioDidChangeNotification = Notification.Name("AudioDidChangeNotfication")
}

protocol MediaLibraryBaseModel {
    associatedtype MLType where MLType: VLCMLObject

    var files: [MLType] { get set }

    var indicatorName: String { get }
    var notificaitonName: Notification.Name { get }

    // mutating will depend if we need to handle struc/enum
    func append(_ item: MLType)
    func isIncluded(_ item: MLType)
}

// protocol can be extended to have the "generic methods" that
// childs will share. No need an in-between class
