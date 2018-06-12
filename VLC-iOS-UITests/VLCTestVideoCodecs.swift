/*****************************************************************************
 * VLCTestVideoCodecs.swift
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

class VLCTestVideoCodecs: XCTestCase {
    let app = XCUIApplication()
    var helper: TestHelper!

    override func setUp() {
        super.setUp()

        XCUIDevice.shared.orientation = .portrait
        setupSnapshot(app)
        helper = TestHelper(app)
        setupSnapshot(app)
        app.launch()
    }

    func testMovCodec() {
        stream(named: "rtsp://184.72.239.149/vod/mp4:BigBuckBunny_175k.mov")
    }

    func testHEVCCodec10b() {
        stream(named: "http://jell.yfish.us/media/jellyfish-90-mbps-hd-hevc-10bit.mkv")
    }

    func testHEVCCodec() {
        stream(named: "http://jell.yfish.us/media/jellyfish-25-mbps-hd-hevc.mkv")
    }

    func testH264Codec() {
        stream(named: "http://jell.yfish.us/media/jellyfish-25-mbps-hd-h264.mkv")
    }

    func stream(named fileName: String) {
        helper.tapTabBarItem(VLCAccessibilityIdentifier.localNetwork)
        app.cells[VLCAccessibilityIdentifier.stream].tap()

        let addressTextField = app.textFields["http://myserver.com/file.mkv"].firstMatch
        addressTextField.clearAndEnter(text: fileName)
        app.buttons["Open Network Stream"].tap()

        XCTContext.runActivity(named: "Wait for video to load") { _ in
            let displayTime = app.navigationBars["VLCMovieView"].buttons["--:--"]
            let zeroPredicate = NSPredicate(format: "exists == 0")
            let videoOpened = expectation(for: zeroPredicate, evaluatedWith: displayTime, handler: nil)
            wait(for: [videoOpened], timeout: 20.0)
        }
        
        XCTContext.runActivity(named: "Check if video is playing") { _ in
            let playPause = app.buttons[VLCAccessibilityIdentifier.playPause]
            let onePredicate = NSPredicate(format: "exists == 1")
            let videoPlaying = expectation(for: onePredicate, evaluatedWith: playPause, handler: nil)
            
            if !(app.navigationBars["VLCMovieView"].buttons["Done"].exists) {
                app.otherElements["Video Player Title"].tap()
            }
            
            wait(for: [videoPlaying], timeout: 20)
        }
    }
}
