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

// Expose a "shadow" version without associatedType in order to use it as a type
protocol MediaLibraryBaseModel {
    init(medialibrary: VLCMediaLibraryManager)

    var anyfiles: [VLCMLObject] { get }

    var updateView: (() -> Void)? { get set }

    var indicatorName: String { get }

    func append(_ item: VLCMLObject)
    func sort(by criteria: VLCMLSortingCriteria)
}

protocol MLBaseModel: MediaLibraryBaseModel {
    associatedtype MLType where MLType: VLCMLObject

    init(medialibrary: VLCMediaLibraryManager)

    var files: [MLType] { get set }

    var medialibrary: VLCMediaLibraryManager { get }

    var updateView: (() -> Void)? { get set }

    var indicatorName: String { get }

    func append(_ item: MLType)
    func sort(by criteria: VLCMLSortingCriteria)
}

extension MLBaseModel {
    var anyfiles: [VLCMLObject] {
        return files
    }

    func append(_ item: VLCMLObject) {
        fatalError()
    }

    func sort(by criteria: VLCMLSortingCriteria) {
        fatalError()
    }
}
