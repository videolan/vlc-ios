/*****************************************************************************
 * MediaLibraryBaseModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol MediaLibraryModelView {
    func dataChanged()
}

protocol MediaLibraryBaseModel: class {
    associatedtype MLType where MLType: VLCMLObject

    init(medialibrary: VLCMediaLibraryManager)

    var files: [MLType] { get set }
    var view: MediaLibraryModelView? { get set }

    var indicatorName: String { get }

    func append(_ item: MLType)
    func isIncluded(_ item: MLType)
}
