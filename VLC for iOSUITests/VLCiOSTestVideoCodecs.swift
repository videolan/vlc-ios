/*****************************************************************************
 * VLCiOSTestVideoCodecs.swift
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

class VLCiOSTestVideoCodecs: XCTestCase {
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
        helper.tapTabBarItem(.Stream)

        let addressTextField = app.textFields["http://myserver.com/file.mkv"]
        addressTextField.clearAndEnter(text: fileName)
        app.buttons["Open Network Stream"].tap()
        
        let displayTime = app.navigationBars["VLCMovieView"].buttons["--:--"]
        let zeroPredicate = NSPredicate(format: "exists == 0")
        expectation(for: zeroPredicate, evaluatedWith: displayTime, handler: nil)

        waitForExpectations(timeout: 20.0) { err in
            XCTAssertNil(err)
            if !(self.app.buttons["Done"].exists) {
                self.app.otherElements["Video Player Title"].tap()
            }
            let playPause = self.app.buttons["Play Pause"]
            let onePredicate = NSPredicate(format: "exists == 1")
            self.expectation(for: onePredicate, evaluatedWith: playPause, handler: nil)
            self.waitForExpectations(timeout: 20.0, handler: nil)
        }
    }
}
