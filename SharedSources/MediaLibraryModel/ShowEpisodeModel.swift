/*****************************************************************************
 * ShowEpisodeModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class ShowEpisodeModel: MLBaseModel {
    typealias MLType = VLCMLMedia

    var updateView: (() -> Void)?

    var files = [VLCMLMedia]()


    var indicatorName: String = NSLocalizedString("EPISODES", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        medialibrary.addObserver(self)
    }

    func isIncluded(_ item: VLCMLMedia) {
    }

    func append(_ item: VLCMLMedia) {
        files.append(item)
    }
}

extension ShowEpisodeModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddShowEpisode showEpisode: [VLCMLMedia]) {
        showEpisode.forEach({ append($0) })
        updateView?()
    }
}
