/*****************************************************************************
 * TVModelObserver.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023-2026 VideoLAN. All rights reserved.
 *
 * Authors: Eshan Singh <eshansingh.dev # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

@objc protocol MediaLibraryDelegate: AnyObject {
    @objc func refreshCollection()
}

class TVModelObserver: NSObject {
    @objc weak var observerDelegate: MediaLibraryDelegate?

    @objc var videoModel: VideoModel? = nil
    @objc var audioModel: TrackModel? = nil

    var playlistModel: PlaylistModel? = nil

    @objc init(observerDelegate: MediaLibraryDelegate? = nil, videoModel: VideoModel, audioModel: TrackModel) {
        self.observerDelegate = observerDelegate
        self.videoModel = videoModel
        self.audioModel = audioModel
    }

    init(observerDelegate: MediaLibraryDelegate , playlistModel: PlaylistModel) {
        self.playlistModel = playlistModel
        self.observerDelegate = observerDelegate
    }
}

extension TVModelObserver: MediaLibraryBaseModelObserver {
    func mediaLibraryBaseModelReloadView() {
        observerDelegate?.refreshCollection()
    }

    @objc func observeLibrary() {

        if let video = videoModel {
            video.observable.addObserver(self)
            video.getMedia()
        }
        if let audio = audioModel {
            audio.observable.addObserver(self)
            audio.getMedia()
        }
        if let playlist = playlistModel {
            playlist.observable.addObserver(self)
            playlist.getMedia()
        }

    }

    @objc func unobserveLibrary() {
        if let video = videoModel {
            video.observable.removeObserver(self)
        }
        if let audio = audioModel {
            audio.observable.removeObserver(self)
        }
        if let playlist = playlistModel {
            playlist.observable.removeObserver(self)
        }
    }
}
