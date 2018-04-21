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
        helper.tapTabBarItem(.Audio)
        XCTAssertNotNil(app.navigationBars[Tab.Audio.rawValue])
    }

    func testNavigationToNetworkTab() {
        helper.tapTabBarItem(.LocalNetwork)
        XCTAssertNotNil(app.navigationBars[Tab.LocalNetwork.rawValue])
    }

    func testNavigationToVideoTab() {
        helper.tapTabBarItem(.Video)
        XCTAssertNotNil(app.navigationBars[Tab.Video.rawValue])
    }

    func testNavigationToSettingsTab() {
        helper.tapTabBarItem(.Settings)
        XCTAssertNotNil(app.navigationBars[Tab.Settings.rawValue])
    }

    func testNavigationToCloudServices() {
        helper.tapTabBarItem(.LocalNetwork)
        app.cells["Cloud"].tap()
        XCTAssertNotNil(app.navigationBars[Tab.Cloud.rawValue])
    }

    func testNavigationToDownloads() {
        helper.tapTabBarItem(.LocalNetwork)
        app.cells["Downloads"].tap()
        XCTAssertNotNil(app.navigationBars[Tab.Downloads.rawValue])
    }

    func testNavigationToNetworkStream() {
        helper.tapTabBarItem(.LocalNetwork)
        app.cells["Stream"].tap()
        XCTAssertNotNil(app.navigationBars[Tab.Stream.rawValue])
    }

    func testNavigationToAbout() {
        helper.tapTabBarItem(.Settings)
        app.cells["About"].tap()
        XCTAssertNotNil(app.navigationBars[Tab.About.rawValue])
    }
}
