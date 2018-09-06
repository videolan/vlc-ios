/*****************************************************************************
 * MediaModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol MediaModel: MLBaseModel where MLType == VLCMLMedia { }

extension MediaModel {
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
            assertionFailure("MediaModel: Delete failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - VLCMLMedia

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
