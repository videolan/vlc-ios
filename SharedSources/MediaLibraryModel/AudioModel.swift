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

class AudioModel: MediaLibraryBaseModel {
    typealias MLType = VLCMLMedia

    var updateView: (() -> Void)?

    var files = [VLCMLMedia]()

    var indicatorName: String = NSLocalizedString("SONGS", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
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

extension AudioModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddAudio audio: [VLCMLMedia]) {
        audio.forEach({ append($0) })
        updateView?()
    }
}
