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
    let helper = LocaleHelper(lang: deviceLanguage, target: VLCiOSTestVideoCodecs.self)
    let moreTab = XCUIApplication().tabBars.buttons.element(boundBy: 4)

    override func setUp() {
        super.setUp()

        XCUIDevice.shared.orientation = .portrait
        setupSnapshot(app)
        app.launch()
    }

    func testNavigationToAudioTab() {
        let audio = helper.localized(key: "AUDIO")
        app.tabBars.buttons[audio].tap()
        XCTAssertNotNil(app.navigationBars[audio])

        snapshot("audio_tab")
    }

    func testNavigationToNetworkTab() {
        let localNetwork = helper.localized(key: "LOCAL_NETWORK")
        app.tabBars.buttons[localNetwork].tap()
        XCTAssertNotNil(app.navigationBars[localNetwork])

        snapshot("network_tab")
    }

    func testNavigationToVideoTab() {
        app.tabBars.buttons["Video"].tap()
        XCTAssertNotNil(app.navigationBars["Video"])

        snapshot("video_tab")
    }

    func testNavigationToSettingsTab() {
        let settings = helper.localized(key: "Settings")
        app.tabBars.buttons[settings].tap()
        XCTAssertNotNil(app.navigationBars[settings])
    }

    func testNavigationToCloudServices() {
        moreTab.tap()

        let cloudServices = helper.localized(key: "CLOUD_SERVICES")
        app.cells.staticTexts[cloudServices].tap()
        XCTAssertNotNil(app.navigationBars[cloudServices])
    }

    func testNavigationToDownloads() {
        moreTab.tap()

        let downloads = helper.localized(key: "DOWNLOAD_FROM_HTTP")
        app.cells.staticTexts[downloads].tap()
        XCTAssertNotNil(app.navigationBars[downloads])
    }

    func testNavigationToNetworkStream() {
        moreTab.tap()

        let network = helper.localized(key: "OPEN_NETWORK")
        app.cells.staticTexts[network].tap()
        XCTAssertNotNil(app.navigationBars[network])
    }

    func testNavigationToAbout() {
        moreTab.tap()

        let about = helper.localized(key: "ABOUT_APP")
        app.cells.staticTexts[about].tap()
        XCTAssertNotNil(app.navigationBars[about])
    }
}
