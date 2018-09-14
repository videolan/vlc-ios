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

    var cellType: BaseCollectionViewCell.Type { return MovieCollectionViewCell.self }

    var medialibrary: VLCMediaLibraryManager

    var indicatorName: String = NSLocalizedString("MOVIES", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.media(ofType: .video)
        medialibrary.requestThumbnail(for: files)
    }

    func append(_ item: VLCMLMedia) {
        if !files.contains { $0 == item } {
            files.append(item)
        }
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

extension VideoModel {
    func sort(by criteria: VLCMLSortingCriteria) {
        files = medialibrary.media(ofType: .video, sortingCriteria: criteria, desc: false)
        updateView?()
    }
}

// MARK: - MediaLibraryObserver

extension VideoModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddVideos videos: [VLCMLMedia]) {
        videos.forEach({ append($0) })
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

// MARK: MediaLibraryObserver - Thumbnail

extension VideoModel {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, thumbnailReady media: VLCMLMedia) {
        for (index, file) in files.enumerated() {
            if file == media {
                files[index] = media
                break
            }
        }
        updateView?()
    }
}

extension VLCMLMedia {
    static func == (lhs: VLCMLMedia, rhs: VLCMLMedia) -> Bool {
        return lhs.identifier() == rhs.identifier()
    }
}

extension VLCMLMedia {
    @objc func mediaDuration() -> String {
        return String(format: "%@", VLCTime(int: Int32(duration())))
    }

    @objc func formatSize() -> String {
        return ByteCountFormatter.string(fromByteCount: Int64(mainFile().size()),
                                         countStyle: .file)
    }

    func mediaProgress() -> Float {
        guard let string = metadata(of: .progress).str as NSString? else {
            return 0.0
        }
        return string.floatValue
    }

    func isNew() -> Bool {
        let integer = metadata(of: .seen).integer()
        return integer == 0
    }

}
