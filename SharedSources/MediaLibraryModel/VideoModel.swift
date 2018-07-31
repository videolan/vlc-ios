/*****************************************************************************
 * VideoModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class VideoModel: MLBaseModel {
    typealias MLType = VLCMLMedia

    var updateView: (() -> Void)?

    var files = [VLCMLMedia]()

    var indicatorName: String = NSLocalizedString("MOVIES", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        medialibrary.addObserver(self)
        files = medialibrary.media(ofType: .video)
    }

    func isIncluded(_ item: VLCMLMedia) {
    }

    func append(_ item: VLCMLMedia) {
        files.append(item)
    }
}

extension VideoModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddVideo video: [VLCMLMedia]) {
        video.forEach({ append($0) })
        updateView?()
    }
}

extension VLCMLMedia {
    @objc func formatDuration(ofMedia media: VLCMLMedia) -> String {
        return String(format: "%@ - %@",
                      VLCTime(int: Int32(media.duration())),
                      ByteCountFormatter.string(fromByteCount: Int64(media.mainFile().size()),
                                                countStyle: .file))
    }
}
