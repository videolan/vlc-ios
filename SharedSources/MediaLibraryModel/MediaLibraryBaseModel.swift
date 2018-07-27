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

protocol MediaLibraryModelView {
    func dataChanged()
}

protocol MediaLibraryBaseModel: class {
    associatedtype MLType where MLType: VLCMLObject

    init(medialibrary: VLCMediaLibraryManager)

    var files: [MLType] { get set }
    var view: MediaLibraryModelView? { get set }

    var indicatorName: String { get }
    var notificaitonName: Notification.Name { get }

    func append(_ item: MLType)
    func isIncluded(_ item: MLType)
}
