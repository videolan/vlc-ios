/*****************************************************************************
 * Document.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

// UIDocument is an abstract class so we do have to implement our own Document
// subclass that inherits from UIDocument.
// Since we only do read files, this subclass must override at least the load
// method in order open a file.
class Document: UIDocument {
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard contents is Data else {
            assertionFailure("Document: Couldn't load the document.")
            return
        }
    }
}
