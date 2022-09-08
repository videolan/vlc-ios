/*****************************************************************************
 * LibrarySearchDataSource.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class LibrarySearchDataSource: NSObject {

    var searchData = [VLCMLObject]()
    var model: MediaLibraryBaseModel

    init(model: MediaLibraryBaseModel) {
        self.model = model
        super.init()
        shouldReloadFor(searchString: "")
    }

    func shouldReloadFor(searchString: String) {
        guard searchString != "" else {
            searchData = model.anyfiles
            return
        }
        searchData.removeAll()
        let lowercaseSearchString = searchString.lowercased()
        model.anyfiles.forEach {
            guard let searchableFile = $0 as? SearchableMLModel else {
                assertionFailure("LibrarySearchDataSource: Unhandled type")
                return
            }
            if searchableFile.contains(lowercaseSearchString) {
                searchData.append($0)
            }
        }
    }
}
