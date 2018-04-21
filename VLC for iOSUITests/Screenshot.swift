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
        helper.tapTabBarItem(.video)
        app.collectionViews.cells.element(boundBy: 0).tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        
        snapshot("playback")
    }
    
    func testCaptureAudioTab() {
        helper.tapTabBarItem(.audio)
        snapshot("audio_tab")
    }
    
    func testCaptureNetworkTab() {
        helper.tapTabBarItem(.localNetwork)
        snapshot("network_tab")
    }
    
    func testCaptureVideoTab() {
        helper.tapTabBarItem(.video)
        snapshot("video_tab")
    }
    
    func download(name fileName: String) {
        helper.tapTabBarItem(.localNetwork)
        app.cells["Downloads"].tap()
        
        let downloadTextfield = app.textFields["http://myserver.com/file.mkv"]
        downloadTextfield.clearAndEnter(text: fileName)
        app.buttons["Download"].tap()
        
        let cancelDownloadButton = app.buttons["flatDeleteButton"]
        let predicate = NSPredicate(format: "exists == 0")
        expectation(for: predicate, evaluatedWith: cancelDownloadButton, handler: nil)
        
        waitForExpectations(timeout: 20.0) { err in
            XCTAssertNil(err)
            downloadTextfield.typeText("\n")
        }
    }
}
