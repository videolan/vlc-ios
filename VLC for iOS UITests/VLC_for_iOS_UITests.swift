/*****************************************************************************
* VLC_for_iOS_UITests.swift
* VLC for iOS
*****************************************************************************
* Copyright (c) 2015 VideoLAN. All rights reserved.
* $Id$
*
* Authors: Felix Paul Kühne <fkuehne # videolan.org>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import XCTest

class VLC_for_iOS_UITests: XCTestCase {

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = true
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        for _ in 0...15 {
            let app = XCUIApplication()
            let collectionViewsQuery = app.collectionViews
            collectionViewsQuery.cells.otherElements.childrenMatchingType(.Image).elementBoundByIndex(1).tap()

            let okButton = app.alerts["Codec not supported"].collectionViews.buttons["OK"]
            okButton.tap()
            okButton.tap()

            sleep(4)

            app.tap()

            let titleNavigationBar = app.navigationBars["Title"]
            let minimizePlaybackButton = titleNavigationBar.buttons["Minimize playback"]
            minimizePlaybackButton.tap()

            let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element
            element.tap()
            minimizePlaybackButton.tap()
            element.tap()
            titleNavigationBar.buttons["Done"].tap()
        }
    }

}
