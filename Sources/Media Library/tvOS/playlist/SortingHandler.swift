/*****************************************************************************
 * SortingHandler.swift
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

class SortingHandler: NSObject {

    enum MediaType {
        case video
        case audio
        case playlist
    }

    private var mediaModel: Any?
    private var mediaType: MediaType = .video

    @objc init(videoModel: VideoModel) {
        mediaModel = videoModel
        mediaType = .video
        super.init()
    }

    @objc init(audioModel: TrackModel) {
        mediaModel = audioModel
        mediaType = .audio
        super.init()
    }

    init(playlistModel: PlaylistModel) {
        mediaModel = playlistModel
        mediaType = .playlist
        super.init()
    }

    @objc func sortMedia(by criterion: VLCMLSortingCriteria, desc: Bool) {
        switch mediaType {
        case .video:
            (mediaModel as? VideoModel)?.sort(by: criterion, desc: desc)
        case .audio:
            (mediaModel as? TrackModel)?.sort(by: criterion, desc: desc)
        case .playlist:
            (mediaModel as? PlaylistModel)?.sort(by: criterion, desc: desc)
        }
    }

    @objc func constructSortAlert(remotePlaybackView: VLCRemotePlaybackViewController? = nil, playlistView: PlaylistViewController? = nil) {
        guard let mediaModel = mediaModel else {
            return
        }

        let sortModel: SortModel
        switch mediaType {
        case .video:
            sortModel = (mediaModel as? VideoModel)!.sortModel
        case .audio:
            sortModel = (mediaModel as? TrackModel)!.sortModel
        case .playlist:
            sortModel = (mediaModel as? PlaylistModel)!.sortModel
        }

        let sortAlert = UIAlertController(title: NSLocalizedString("SORT_BY", comment: ""), message: NSLocalizedString("SORT_NOTIFICATION", comment: ""), preferredStyle: .actionSheet)

        for criterion in sortModel.sortingCriteria {
            let action = UIAlertAction(title: String(describing: criterion), style: .default) { _ in
                let previousOrder = sortModel.desc
                self.sortMedia(by: criterion, desc: !previousOrder)
                switch self.mediaType {
                case .video, .audio:
                    remotePlaybackView?.cachedMediaCollectionView.reloadData()
                case .playlist:
                    playlistView?.playlistCollectionView.reloadData()
                }
            }
            sortAlert.addAction(action)
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .destructive)
        sortAlert.addAction(cancelAction)

        if mediaType == .video || mediaType == .audio {
            remotePlaybackView?.present(sortAlert, animated: true)
        } else if mediaType == .playlist {
            playlistView?.present(sortAlert, animated: true)
        }
    }
}
