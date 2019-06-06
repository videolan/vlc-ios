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
    init(medialibrary: MediaLibraryService)

    var anyfiles: [VLCMLObject] { get }

    var sortModel: SortModel { get }

    var updateView: (() -> Void)? { get set }

    var indicatorName: String { get }
    var cellType: BaseCollectionViewCell.Type { get }

    func append(_ item: VLCMLObject)
    func delete(_ items: [VLCMLObject])
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool)
}

protocol MLBaseModel: AnyObject, MediaLibraryBaseModel {
    associatedtype MLType where MLType: VLCMLObject

    init(medialibrary: MediaLibraryService)

    var files: [MLType] { get set }

    var medialibrary: MediaLibraryService { get }

    var updateView: (() -> Void)? { get set }

    var indicatorName: String { get }

    func append(_ item: MLType)
    // FIXME: Ideally items should be MLType but Swift isn't happy so it will always fail
    func delete(_ items: [VLCMLObject])
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool)
}

extension MLBaseModel {
    var anyfiles: [VLCMLObject] {
        return files
    }

    func append(_ item: VLCMLObject) {
        fatalError()
    }

    func delete(_ items: [VLCMLObject]) {
        fatalError()
    }

    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        fatalError()
    }
}

protocol EditableMLModel {
    func editCellType() -> BaseCollectionViewCell.Type
}

protocol SearchableMLModel {
    func contains(_ searchString: String) -> Bool
}

protocol MediaCollectionModel {
    func files() -> [VLCMLMedia]?
    func sortModel() -> SortModel?
    func title() -> String?
}
