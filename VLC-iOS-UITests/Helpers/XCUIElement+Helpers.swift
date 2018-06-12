/*****************************************************************************
 * XCUIElement+Helpers.swift
 * VLC for iOSUITests
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Mike JS. Choi <mkchoi212 # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import XCTest

extension XCUIElement {
    func clearAndEnter(text: String) {
        XCTContext.runActivity(named: "Enter \"\(text)\" into Textfield") { _ in
            guard let stringValue = self.value as? String else {
                XCTFail("Tried to clear and enter text into a non string value")
                return
            }
            
            tap()
            
            let deleteString = stringValue.map { _ in XCUIKeyboardKey.delete.rawValue }.joined(separator: "")
            typeText(deleteString)
            typeText(text)
        }
    }
}
