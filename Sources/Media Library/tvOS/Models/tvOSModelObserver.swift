//
//  tvOSModelObserver.swift
//  VLC-tvOS
//
//  Created by Eshan Singh on 22/07/23.
//  Copyright © 2023 VideoLAN. All rights reserved.
//

import Foundation

@objc protocol MediaLibraryDelegate: AnyObject {
    @objc func refreshCollection()
}

class tvOSModelObserver: NSObject {
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

extension tvOSModelObserver: MediaLibraryBaseModelObserver {
    func mediaLibraryBaseModelReloadView() {
        observerDelegate?.refreshCollection()
    }

    @objc func observeLibrary() {

        if let video = videoModel {
            video.observable.addObserver(self)
        }
        if let audio = audioModel {
            audio.observable.addObserver(self)
        }
        if let playlist = playlistModel {
            playlist.observable.addObserver(self)
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
