/*****************************************************************************
 * VLCiOSTestMenu.swift
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

class VLCiOSTestMenu: XCTestCase {
    let app = XCUIApplication()
    var helper: TestHelper!

    override func setUp() {
        super.setUp()

        XCUIDevice.shared.orientation = .portrait
        setupSnapshot(app)
        helper = TestHelper(app)
        app.launch()
    }

    func testNavigationToAudioTab() {
        helper.tapTabBarItem(.audio)
        XCTAssertNotNil(app.navigationBars[Tab.audio.rawValue])
    }

    func testNavigationToNetworkTab() {
        helper.tapTabBarItem(.localNetwork)
        XCTAssertNotNil(app.navigationBars[Tab.localNetwork.rawValue])
    }

    func testNavigationToVideoTab() {
        helper.tapTabBarItem(.video)
        XCTAssertNotNil(app.navigationBars[Tab.video.rawValue])
    }

    func testNavigationToSettingsTab() {
        helper.tapTabBarItem(.settings)
        XCTAssertNotNil(app.navigationBars[Tab.settings.rawValue])
    }

    func testNavigationToCloudServices() {
        helper.tapTabBarItem(.localNetwork)
        app.cells["Cloud"].tap()
        XCTAssertNotNil(app.navigationBars[Tab.cloud.rawValue])
    }

    func testNavigationToDownloads() {
        helper.tapTabBarItem(.localNetwork)
        app.cells["Downloads"].tap()
        XCTAssertNotNil(app.navigationBars[Tab.downloads.rawValue])
    }

    func testNavigationToNetworkStream() {
        helper.tapTabBarItem(.localNetwork)
        app.cells["Stream"].tap()
        XCTAssertNotNil(app.navigationBars[Tab.stream.rawValue])
    }

    func testNavigationToAbout() {
        helper.tapTabBarItem(.settings)
        app.cells["About"].tap()
        XCTAssertNotNil(app.navigationBars[Tab.about.rawValue])
    }
}
