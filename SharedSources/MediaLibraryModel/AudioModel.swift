/*****************************************************************************
 * AudioModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class AudioModel: MediaModel {
    typealias MLType = VLCMLMedia

    var sortModel = SortModel(alpha: true,
                              duration: true,
                              fileSize: true)

    var updateView: (() -> Void)?

    var files = [VLCMLMedia]()

    var cellType: BaseCollectionViewCell.Type { return AudioCollectionViewCell.self }

    var medialibrary: MediaLibraryService

    var indicatorName: String = NSLocalizedString("SONGS", comment: "")

    required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.media(ofType: .audio)
    }
}

// MARK: - Sort

extension AudioModel {
    func sort(by criteria: VLCMLSortingCriteria) {
        // FIXME: Currently if sorted by name, the files are sorted by filename but displaying title
        files = medialibrary.media(ofType: .audio, sortingCriteria: criteria)
        sortModel.currentSort = criteria
        updateView?()
    }
}

// MARK: - Edit
extension AudioModel: EditableMLModel {
    func editCellType() -> BaseCollectionViewCell.Type {
        return MediaEditCell.self
    }
}
// MARK: - MediaLibraryObserver

extension AudioModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddAudios audios: [VLCMLMedia]) {
        audios.forEach({ append($0) })
        updateView?()
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
