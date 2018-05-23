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
    let application = XCUIApplication()
    var helper: TestHelper!

    override func setUp() {
        super.setUp()

        XCUIDevice.shared.orientation = .portrait
        setupSnapshot(application)
        helper = TestHelper(application)
        application.launchArguments = ["-disableAnimations"]
        application.launch()
    }

    func testNavigationToAudioTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.audio)
        XCTAssertNotNil(application.navigationBars[VLCAccessibilityIdentifier.audio])
    }

    func testNavigationToNetworkTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.localNetwork)
        XCTAssertNotNil(application.navigationBars[VLCAccessibilityIdentifier.localNetwork])
    }

    func testNavigationToVideoTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.video)
        XCTAssertNotNil(application.navigationBars[VLCAccessibilityIdentifier.video])
    }

    func testNavigationToSettingsTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.settings)
        XCTAssertNotNil(application.navigationBars[VLCAccessibilityIdentifier.settings])
    }

    func testNavigationToCloudServices() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.localNetwork)
        application.cells[VLCAccessibilityIdentifier.cloud].tap()
        XCTAssertNotNil(application.navigationBars[VLCAccessibilityIdentifier.cloud])
    }

    func testNavigationToDownloads() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.localNetwork)
        application.cells[VLCAccessibilityIdentifier.downloads].tap()
        XCTAssertNotNil(application.navigationBars[VLCAccessibilityIdentifier.downloads])
    }

    func testNavigationToNetworkStream() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.localNetwork)
        application.cells[VLCAccessibilityIdentifier.stream].tap()
        XCTAssertNotNil(application.navigationBars[VLCAccessibilityIdentifier.stream])
    }

    func testNavigationToAbout() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.settings)
        application.cells[VLCAccessibilityIdentifier.about].tap()
        XCTAssertNotNil(application.navigationBars[VLCAccessibilityIdentifier.about])
    }
}
