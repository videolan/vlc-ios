/*****************************************************************************
 * TrackModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class TrackModel: MediaModel {
    typealias MLType = VLCMLMedia

    var sortModel = SortModel([.alpha, .album, .duration, .fileSize])

    var updateView: (() -> Void)?

    var files = [VLCMLMedia]()

    var cellType: BaseCollectionViewCell.Type { return MediaCollectionViewCell.self }

    var medialibrary: MediaLibraryService

    var indicatorName: String = NSLocalizedString("SONGS", comment: "")

    required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.media(ofType: .audio)
    }
}

// MARK: - Sort

extension TrackModel {
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        // FIXME: Currently if sorted by name, the files are sorted by filename but displaying title
        files = medialibrary.media(ofType: .audio,
                                   sortingCriteria: criteria,
                                   desc: desc)
        sortModel.currentSort = criteria
        sortModel.desc = desc
        updateView?()
    }
}

// MARK: - MediaLibraryObserver

extension TrackModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddTracks tracks: [VLCMLMedia]) {
        tracks.forEach({ append($0) })
        updateView?()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didModifyTracks tracks: [VLCMLMedia]) {
        if !tracks.isEmpty {
            files = swapModels(with: tracks)
            updateView?()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteMediaWithIds ids: [NSNumber]) {
        files = files.filter() {
            for id in ids where $0.identifier() == id.int64Value {
                return false
            }
            return true
        }
        updateView?()
    }
}
