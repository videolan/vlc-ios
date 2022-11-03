/*****************************************************************************
 * CarPlayMediaLibraryObserver.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

@objc protocol CPMediaLibraryObserverDelegate: AnyObject {
    @objc func templatesNeedUpdate()
}

class CarPlayMediaLibraryObserver: NSObject {
    @objc weak var observerDelegate: CPMediaLibraryObserverDelegate?
}

extension CarPlayMediaLibraryObserver: MediaLibraryObserver {
    @objc func observeLibrary() {
        VLCAppCoordinator.sharedInstance().mediaLibraryService.observable.addObserver(self)
    }

    @objc func unobserveLibrary() {
        VLCAppCoordinator.sharedInstance().mediaLibraryService.observable.removeObserver(self)
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didAddArtists artists: [VLCMLArtist]) {
        observerDelegate?.templatesNeedUpdate()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteArtistsWithIds artistsIds: [NSNumber]) {
        observerDelegate?.templatesNeedUpdate()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didAddAlbums albums: [VLCMLAlbum]) {
        observerDelegate?.templatesNeedUpdate()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteAlbumsWithIds albumsIds: [NSNumber]) {
        observerDelegate?.templatesNeedUpdate()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didAddGenres genres: [VLCMLGenre]) {
        observerDelegate?.templatesNeedUpdate()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteGenresWithIds genresIds: [NSNumber]) {
        observerDelegate?.templatesNeedUpdate()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didAddPlaylists playlists: [VLCMLPlaylist]) {
        observerDelegate?.templatesNeedUpdate()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeletePlaylistsWithIds playlistsIds: [NSNumber]) {
        observerDelegate?.templatesNeedUpdate()
    }
}
