/*****************************************************************************
 * TestHelper.swift
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

struct TestHelper {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    func tapTabBarItem(_ identifier: String) {
        XCTContext.runActivity(named: "Tap \"\(identifier)\" tab") { _ in
            app.tabBars.buttons[identifier].firstMatch.tap()
        }
    }
}
