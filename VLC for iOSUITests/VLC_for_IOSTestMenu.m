/*****************************************************************************
 * VLC_for_IOSTestMenu.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <XCTest/XCTest.h>

@interface VLC_for_IOSTestMenu : XCTestCase
@property (nonatomic, strong) XCUIApplication *application;
@end

@implementation VLC_for_IOSTestMenu

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = YES;

    self.application = [[XCUIApplication alloc] init];
    [self.application launch];
    [[XCUIDevice sharedDevice] setOrientation:UIDeviceOrientationFaceUp];

    if (self.application.navigationBars[@"Welcome"].exists) {
        [self.application.navigationBars[@"Welcome"].buttons[@"Done"] tap];
    }
}

- (void)testMenuTabAllFiles
{
    [self.application.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [self.application.cells/*@START_MENU_TOKEN@*/.staticTexts[@"All Files"]/*[[".cells.staticTexts[@\"All Files\"]",".staticTexts[@\"All Files\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
    XCTAssertNotNil(self.application.navigationBars[@"All Files"]);
}

- (void)testMenuTabMusicAlbums
{
    [self.application.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [self.application.cells/*@START_MENU_TOKEN@*/.staticTexts[@"Music Albums"]/*[[".cells.staticTexts[@\"Music Albums\"]",".staticTexts[@\"Music Albums\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];

    XCTAssertNotNil(self.application.navigationBars[@"Music Albums"]);
}

- (void)testMenuTabTVShows
{
    [self.application.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [self.application.cells.staticTexts[@"TV Shows"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"TV Shows"]);
}

- (void)testMenuTabLocalNetwork
{
    [self.application.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [self.application.cells.staticTexts[@"Local Network"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"Local Network"]);
}

- (void)testMenuTabNetworkStream
{
    [self.application.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [self.application.cells.staticTexts[@"Network Stream"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"Network Stream"]);
}

- (void)testMenuTabDownloads
{
    [self.application.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [self.application.cells.staticTexts[@"Downloads"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"Downloads"]);
}

- (void)testMenuTabWifi
{
    [self.application.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [self.application.cells.staticTexts[@"Sharing via WiFi"] tap];

    XCTAssertFalse(self.application.tables.staticTexts[@"Inactive Server"].exists);
}

- (void)testMenuTabCloudServices
{
    [self.application.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [self.application.cells.staticTexts[@"Cloud Services"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"Cloud Services"]);
}

- (void)testMenuTabSettings
{
    [self.application.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [self.application.cells.staticTexts[@"Settings"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"Settings"]);
}

- (void)testMenuTabAbout
{
    [self.application.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [self.application.cells.staticTexts[@"About VLC for iOS"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"About"]);
}

@end
