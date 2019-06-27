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
        download(name: "http://jell.yfish.us/media/jellyfish-10-mbps-hd-h264.mkv")
        helper.tapTabBarItem(VLCAccessibilityIdentifier.video)
        app.collectionViews.cells.element(boundBy: 0).tap()

        snapshot("playback")
    }

    func testCaptureAudioTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.audio)
        snapshot("audio_tab")
    }

    func testCaptureVideoTab() {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.video)
        snapshot("video_tab")
    }

    func download(name fileName: String) {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.localNetwork)
        app.cells[VLCAccessibilityIdentifier.downloads].tap()

        let downloadTextfield = app.textFields["http://myserver.com/file.mkv"].firstMatch
        downloadTextfield.clearAndEnter(text: fileName)
        app.buttons["Download"].firstMatch.tap()

        XCTContext.runActivity(named: "Wait for download to complete") { _ in
            let cancelDownloadButton = app.buttons["flatDeleteButton"]
            let predicate = NSPredicate(format: "exists == 0")
            let downloadCompleted = expectation(for: predicate, evaluatedWith: cancelDownloadButton, handler: nil)
            wait(for: [downloadCompleted], timeout: 20.0)
        }
        
        downloadTextfield.typeText("\n")
    }
}
