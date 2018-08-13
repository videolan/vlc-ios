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

class AudioModel: MLBaseModel {
    typealias MLType = VLCMLMedia

    var updateView: (() -> Void)?

    var files = [VLCMLMedia]()

    var medialibrary: VLCMediaLibraryManager

    var indicatorName: String = NSLocalizedString("SONGS", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.media(ofType: .audio)
    }

    func append(_ item: VLCMLMedia) {
        for file in files {
            if file.identifier() == item.identifier() {
                return
            }
        }
        files.append(item)
    }

    func delete(_ items: [VLCMLObject]) {
        do {
            for case let media as VLCMLMedia in items {
                try FileManager.default.removeItem(atPath: media.mainFile().mrl.path)
            }
            medialibrary.reload()
        }
        catch let error as NSError {
            assertionFailure("VideoModel: Delete failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Sort

extension AudioModel {
    func sort(by criteria: VLCMLSortingCriteria) {
        // FIXME: Currently if sorted by name, the files are sorted by filename but displaying title
        files = medialibrary.media(ofType: .audio, sortingCriteria: criteria, desc: false)
        updateView?()
    }
}

// MARK: - MediaLibraryObserver

extension AudioModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddAudios audios: [VLCMLMedia]) {
        audios.forEach({ append($0) })
        updateView?()
    }

    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didDeleteMediaWithIds ids: [NSNumber]) {
        files = files.filter() {
            for id in ids where $0.identifier() == id.int64Value {
                return false
            }
            return true
        }
        updateView?()
    }
}
