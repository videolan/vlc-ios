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
    let application = XCUIApplication()
    var helper: TestHelper!
    
    override func setUp() {
        super.setUp()
        
        XCUIDevice.shared.orientation = .portrait
        setupSnapshot(application)
        helper = TestHelper(application)
        setupSnapshot(application)
        application.launch()
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
        application.cells[VLCAccessibilityIdentifier.stream].tap()

        let addressTextField = application.textFields["http://myserver.com/file.mkv"]
        addressTextField.clearAndEnter(text: fileName)
        application.buttons["Open Network Stream"].tap()
        
        let displayTime = application.navigationBars["VLCMovieView"].buttons["--:--"]
        let zeroPredicate = NSPredicate(format: "exists == 0")
        expectation(for: zeroPredicate, evaluatedWith: displayTime, handler: nil)

        waitForExpectations(timeout: 20.0) { err in
            XCTAssertNil(err)
            if !(self.application.buttons["Done"].exists) {
                self.application.otherElements["Video Player Title"].tap()
            }
            let playPause = self.application.buttons[VLCAccessibilityIdentifier.playPause]
            let onePredicate = NSPredicate(format: "exists == 1")
            self.expectation(for: onePredicate, evaluatedWith: playPause, handler: nil)
            self.waitForExpectations(timeout: 20.0, handler: nil)
        }
    }
}
