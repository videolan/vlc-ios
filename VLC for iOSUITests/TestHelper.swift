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

enum Tab: String {
    case Video, Audio, LocalNetwork, Cloud
    case Settings, Downloads, Stream, About
}

struct TestHelper {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    func tapTabBarItem(_ type: Tab) {
        app.tabBars.buttons[type.rawValue].tap()
    }
}
