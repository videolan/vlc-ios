/*****************************************************************************
 * TracksViewModel.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Timmy Nguyen <timmypass21 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class TracksViewModel: TrackModel, ObservableObject {
    @Published var snapshotMedias: [VLCWatchMLMedia] = [] // display metadata from iphone's media library
    @Published var isFirstLoad = true

    lazy var playbackService = PlaybackService.sharedInstance()

    required init(medialibrary: MediaLibraryService) {
        super.init(medialibrary: medialibrary)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDidUpdateSnapshotLibraryDBFile),
                                               name: .VLCDidUpdateSnapshotLibraryDBFileNotification,
                                               object: nil)
    }

    func play(mediaID: VLCMLIdentifier) {
        guard let media: VLCMLMedia = files.first(where: { $0.identifier() == mediaID })
        else {
            print("Media with id not found: \(mediaID)")
            return
        }

        playbackService.play(media)
        print("Playing media: \(media.title)")
    }

    func loadData() {
        loadSnapshotMediaLibrary()
        loadTracks()
        isFirstLoad = false
    }

    override func medialibrary(_ medialibrary: MediaLibraryService, didAddTracks tracks: [VLCMLMedia]) {
        print("TracksViewModel: didAddTracks \(tracks)")
        super.medialibrary(medialibrary, didAddTracks: tracks)
        NotificationCenter.default.post(name: .VLCWatchDidAddTracksNotification, object: nil, userInfo: ["tracks": tracks])
    }

    @objc private func handleDidUpdateSnapshotLibraryDBFile() {
        loadSnapshotMediaLibrary()
    }

    // Fetches the audio files from medialibrary.db
    private func loadTracks() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.sort(by: .default, desc: true)
            self.files = self.anyfiles as? [VLCMLMedia] ?? []
        }
    }

    // Fetches the audio files metadata from medialibrary-snapshot.db
    private func loadSnapshotMediaLibrary() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let audioFiles = VLCAppCoordinator.sharedInstance().snapshotMediaLibraryService.medialib.audioFiles() {
                let snapshotMedias = audioFiles.map { VLCWatchMLMedia($0) }.sorted { $0.id < $1.id}
                DispatchQueue.main.async {
                    self.snapshotMedias = snapshotMedias
                }
            }
        }
    }
}
