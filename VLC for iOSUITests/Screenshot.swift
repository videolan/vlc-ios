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
        helper = TestHelper(lang: deviceLanguage, target: VLCiOSTestMenu.self)
        
        app.launch()
    }
    
    override func tearDown() {
        SDStatusBarManager.sharedInstance().disableOverrides()
    }
    
    func testCaptureVideoPlayback() {
        download(name: "http://jell.yfish.us/media/jellyfish-10-mbps-hd-h264.mkv")
        helper.tap(tabDescription: "Video", app: app)
        app.collectionViews.cells.element(boundBy: 0).tap()
        app.navigationBars["VLCMovieView"].buttons[helper.localized(key: "VIDEO_ASPECT_RATIO_BUTTON")].tap()
        
        snapshot("playback")
    }
    
    func testCaptureAudioTab() {
        let audio = helper.localized(key: "AUDIO")
        helper.tap(tabDescription: audio, app: app)
        snapshot("audio_tab")
    }
    
    func testCaptureNetworkTab() {
        let localNetwork = helper.localized(key: "LOCAL_NETWORK")
        helper.tap(tabDescription: localNetwork, app: app)
        snapshot("network_tab")
    }
    
    func testCaptureVideoTab() {
        helper.tap(tabDescription: "Video", app: app)
        snapshot("video_tab")
    }
    
    func download(name fileName: String) {
        let download = helper.localized(key: "DOWNLOAD_FROM_HTTP")
        helper.tap(tabDescription: download, app: app)
        
        let downloadTextfield = app.textFields["http://myserver.com/file.mkv"]
        downloadTextfield.clearAndEnter(text: fileName)
        app.buttons[helper.localized(key: "BUTTON_DOWNLOAD")].tap()
        
        let cancelDownloadButton = app.buttons["flatDeleteButton"]
        let predicate = NSPredicate(format: "exists == 0")
        expectation(for: predicate, evaluatedWith: cancelDownloadButton, handler: nil)
        
        waitForExpectations(timeout: 20.0) { err in
            XCTAssertNil(err)
            downloadTextfield.typeText("\n")
        }
    }
}
