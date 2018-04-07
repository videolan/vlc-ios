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
        helper.tap(.Audio)
        XCTAssertNotNil(app.navigationBars[Tab.Audio.rawValue])
    }

    func testNavigationToNetworkTab() {
        helper.tap(.Server)
        XCTAssertNotNil(app.navigationBars[Tab.Server.rawValue])
    }

    func testNavigationToVideoTab() {
        helper.tap(.Video)
        XCTAssertNotNil(app.navigationBars[Tab.Video.rawValue])
    }

    func testNavigationToSettingsTab() {
        helper.tap(.Settings)
        XCTAssertNotNil(app.navigationBars[Tab.Settings.rawValue])
    }

    func testNavigationToCloudServices() {
        helper.tap(.Cloud)
        XCTAssertNotNil(app.navigationBars[Tab.Cloud.rawValue])
    }

    func testNavigationToDownloads() {
        helper.tap(.Downloads)
        XCTAssertNotNil(app.navigationBars[Tab.Downloads.rawValue])
    }

    func testNavigationToNetworkStream() {
        helper.tap(.Stream)
        XCTAssertNotNil(app.navigationBars[Tab.Stream.rawValue])
    }

    func testNavigationToAbout() {
        helper.tap(.About)
        XCTAssertNotNil(app.navigationBars[Tab.About.rawValue])
    }
}
