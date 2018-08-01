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
        // created too late so missed the callback asking if he has anything
        files = medialibrary.media(ofType: .audio)
    }

    func isIncluded(_ item: VLCMLMedia) {
    }

    func append(_ item: VLCMLMedia) {
        // need to check more for duplicate and stuff
        files.append(item)
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
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddAudio audio: [VLCMLMedia]) {
        audio.forEach({ append($0) })
        updateView?()
    }
}
