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

    var medialibrary: VLCMediaLibraryManager

    var indicatorName: String = NSLocalizedString("EPISODES", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
    }

    func append(_ item: VLCMLMedia) {
        files.append(item)
    }
}

extension ShowEpisodeModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddShowEpisodes showEpisodes: [VLCMLMedia]) {
        showEpisodes.forEach({ append($0) })
        updateView?()
    }
}
