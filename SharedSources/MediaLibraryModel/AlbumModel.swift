/*****************************************************************************
 * AlbumModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class AlbumModel: MediaLibraryBaseModel {
    typealias MLType = VLCMLAlbum

    var files = [VLCMLAlbum]()

    var indicatorName: String = NSLocalizedString("ALBUMS", comment: "")

    var notificaitonName: Notification.Name = .VLCAlbumsDidChangeNotification

    required init(medialibrary: VLCMediaLibraryManager) {
        medialibrary.addObserver(self)
        // created too late so missed the callback asking if he has anything
        files = medialibrary.getAlbums()
    }

    func isIncluded(_ item: VLCMLAlbum) {
    }

    func append(_ item: VLCMLAlbum) {
        // need to check more for duplicate and stuff
        files.append(item)
    }
}

extension AlbumModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddAlbum album: [VLCMLAlbum]) {
        album.forEach({ append($0) })
        NotificationCenter.default.post(name: notificaitonName, object: nil)
    }
}
