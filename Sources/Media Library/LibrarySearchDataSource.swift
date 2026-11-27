/*****************************************************************************
 * LibrarySearchDataSource.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class LibrarySearchDataSource: NSObject {

    var searchData = [VLCMLObject]()
    var isSearching: Bool = false
    var model: MediaLibraryBaseModel
    private(set) var searchString: String = ""

    init(model: MediaLibraryBaseModel) {
        self.model = model
        super.init()
        shouldReloadFor(searchString: "")
    }

    private var searchableFiles: [VLCMLObject] {
        guard let folderModel = model as? FolderModel else {
            return model.anyfiles
        }

        folderModel.fileArrayLock.lock()
        defer { folderModel.fileArrayLock.unlock() }
        return folderModel.files + folderModel.folderMediaFiles
    }

    func shouldReloadFor(searchString: String) {
        self.searchString = searchString

        let files = searchableFiles
        guard searchString != "" else {
            searchData = files
            return
        }
        searchData.removeAll()
        files.forEach {
            guard let searchableFile = $0 as? SearchableMLModel else {
                assertionFailure("LibrarySearchDataSource: Unhandled type")
                return
            }
            if searchableFile.contains(searchString) {
                searchData.append($0)
            }
        }
    }
    
    func deleteInSearch(_ objects: [VLCMLObject]) {
        if isSearching {
            searchData.removeAll { item in
                objects.contains { $0 === item }
            }
        }
    }
}
