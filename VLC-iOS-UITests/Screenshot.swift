/*****************************************************************************
 * Screenshot.swift
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

class Screenshot: XCTestCase {
    let app = XCUIApplication()
    var helper: TestHelper!

    override func setUp() {
        super.setUp()
        app.launchEnvironment = [
            "HOME" : "/Users/caro/Documents/Projects/vlc-ios/AppStoreData28June.xcappdata/AppData",
            "CFFIXED_USER_HOME" : "/Users/caro/Documents/Projects/vlc-ios/AppStoreData28June.xcappdata/AppData"]
        XCUIDevice.shared.orientation = .portrait
        SDStatusBarManager.sharedInstance().enableOverrides()
        setupSnapshot(app)
        helper = TestHelper(app)

        app.launch()
    }

    override func tearDown() {
        SDStatusBarManager.sharedInstance().disableOverrides()
    }

    func testCaptureVideoPlayback() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.video)
        app.collectionViews.cells.element(boundBy: 3).tap()
        snapshot("playback")
    }

    func testCaptureAudioTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.audio)
        app.cells[VLCAccessibilityIdentifier.songs].tap()
        snapshot("audio_tab")
    }

    func testCaptureVideoTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.video)
        snapshot("video_tab")
    }
}
