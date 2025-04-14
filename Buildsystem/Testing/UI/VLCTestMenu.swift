/*****************************************************************************
 * VLCTestMenu.swift
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

class VLCTestMenu: XCTestCase {
    let app = XCUIApplication()
    var helper: TestHelper!

    override func setUp() {
        super.setUp()

        XCUIDevice.shared.orientation = .portrait
        helper = TestHelper(app)
        app.launch()
    }

    func testNavigationToAudioTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.audio)
        XCTAssertNotNil(app.navigationBars[VLCAccessibilityIdentifier.audio])
    }

    func testNavigationToNetworkTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.localNetwork)
        XCTAssertNotNil(app.navigationBars[VLCAccessibilityIdentifier.localNetwork])
    }

    func testNavigationToVideoTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.video)
        XCTAssertNotNil(app.navigationBars[VLCAccessibilityIdentifier.video])
    }

    func testNavigationToPlaylistTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.playlist)
        XCTAssertNotNil(app.navigationBars[VLCAccessibilityIdentifier.playlist])
    }

    func testNavigationToSettingsTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.settings)
        XCTAssertNotNil(app.navigationBars[VLCAccessibilityIdentifier.settings])
    }

    func testNavigationToCloudServices() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.localNetwork)
        app.cells[VLCAccessibilityIdentifier.cloud].tap()
        XCTAssertNotNil(app.navigationBars[VLCAccessibilityIdentifier.cloud])
    }

    func testNavigationToDownloads() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.localNetwork)
        app.cells[VLCAccessibilityIdentifier.downloads].tap()
        XCTAssertNotNil(app.navigationBars[VLCAccessibilityIdentifier.downloads])
    }

    func testNavigationToNetworkStream() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.localNetwork)
        app.cells[VLCAccessibilityIdentifier.stream].tap()
        XCTAssertNotNil(app.navigationBars[VLCAccessibilityIdentifier.stream])
    }
    
    func testNavigationToFavorite() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.localNetwork)
        app.cells[VLCAccessibilityIdentifier.favorite].tap()
        XCTAssertNotNil(app.navigationBars[VLCAccessibilityIdentifier.favorite])
    }

    func testNavigationToAbout() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.settings)
        app.navigationBars.buttons[VLCAccessibilityIdentifier.about].tap()
        XCTAssertNotNil(app.navigationBars.buttons[VLCAccessibilityIdentifier.done])
        XCTAssertNotNil(app.navigationBars.buttons[VLCAccessibilityIdentifier.contribute])
    }
}
