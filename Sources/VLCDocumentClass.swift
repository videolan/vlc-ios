/*****************************************************************************
 * VLCDocumentClass.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

@objc(VLCDocumentClass)
class DocumentClass: UIDocument {
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        //we should probably test the documenttype here
    }
}

