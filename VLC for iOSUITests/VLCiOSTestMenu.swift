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
        helper = TestHelper(lang: deviceLanguage, target: VLCiOSTestMenu.self)
        app.launch()
    }

    func testNavigationToAudioTab() {
        let audio = helper.localized(key: "AUDIO")
        helper.tap(tabDescription: audio, app: app)
        XCTAssertNotNil(app.navigationBars[audio])

        snapshot("audio_tab")
    }

    func testNavigationToNetworkTab() {
        let localNetwork = helper.localized(key: "LOCAL_NETWORK")
        helper.tap(tabDescription: localNetwork, app: app)
        XCTAssertNotNil(app.navigationBars[localNetwork])

        snapshot("network_tab")
    }

    func testNavigationToVideoTab() {
        helper.tap(tabDescription: "Video", app: app)
        XCTAssertNotNil(app.navigationBars["Video"])
        
        snapshot("video_tab")
    }

    func testNavigationToSettingsTab() {
        let settings = helper.localized(key: "Settings")
        helper.tap(tabDescription: settings, app: app)
        XCTAssertNotNil(app.navigationBars[settings])
    }

    func testNavigationToCloudServices() {
        let cloudServices = helper.localized(key: "CLOUD_SERVICES")
        helper.tap(tabDescription: cloudServices, app: app)
        XCTAssertNotNil(app.navigationBars[cloudServices])
    }

    func testNavigationToDownloads() {
        let downloads = helper.localized(key: "DOWNLOAD_FROM_HTTP")
        helper.tap(tabDescription: downloads, app: app)
        XCTAssertNotNil(app.navigationBars[downloads])
    }

    func testNavigationToNetworkStream() {
        let network = helper.localized(key: "OPEN_NETWORK")
        helper.tap(tabDescription: network, app: app)
        XCTAssertNotNil(app.navigationBars[network])
    }

    func testNavigationToAbout() {
        let about = helper.localized(key: "ABOUT_APP")
        helper.tap(tabDescription: about, app: app)
        XCTAssertNotNil(app.navigationBars[about])
    }
}
