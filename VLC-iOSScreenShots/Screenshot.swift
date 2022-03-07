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
    // Path to the xcappdata we need to fill the application for the screenshots
    let dataPath: String = ""
    let app = XCUIApplication()
    var helper: TestHelper!

    override func setUp() {
        super.setUp()
        app.launchEnvironment = [
            "HOME" : dataPath,
            "CFFIXED_USER_HOME" : dataPath]
        XCUIDevice.shared.orientation = .portrait
        SDStatusBarManager.sharedInstance().enableOverrides()
        setupSnapshot(app)
        helper = TestHelper(app)

        app.launch()
    }

    override func tearDown() {
        SDStatusBarManager.sharedInstance().disableOverrides()
    }

    func testCaptureAudioTabTracks() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.audio)
        app.cells[VLCAccessibilityIdentifier.songs].tap()
        snapshot("audio_tab_tracks")
    }

    func testCaptureAudioTabArtists() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.audio)
        app.cells[VLCAccessibilityIdentifier.artists].tap()
        snapshot("audio_tab_artists")
    }

    func testCaptureVideoTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.video)
        snapshot("video_tab")
    }

    func testCaptureVideoPlayback() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.video)
        app.collectionViews.cells.element(boundBy: 5).tap()
        app.collectionViews.cells.element(boundBy: 1).tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        app.sliders[VLCAccessibilityIdentifier.videoPlayerScrubBar]
            .adjust(toNormalizedSliderPosition: 0.5)
        snapshot("video_tab_playback")
    }
}
