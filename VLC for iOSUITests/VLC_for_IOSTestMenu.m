//
//  VLCTestLibrary.m
//  VLC
//
//  Created by Carola Nitz on 9/21/17.
//  Copyright © 2017 VideoLAN. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface VLC_for_IOSTestMenu : XCTestCase

@end

@implementation VLC_for_IOSTestMenu

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = YES;

    [[[XCUIApplication alloc] init] launch];
    [[XCUIDevice sharedDevice] setOrientation:UIDeviceOrientationFaceUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMenuTabAllFiles {

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [app.cells/*@START_MENU_TOKEN@*/.staticTexts[@"All Files"]/*[[".cells.staticTexts[@\"All Files\"]",".staticTexts[@\"All Files\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
    XCTAssertNotNil(app.navigationBars[@"All Files"]);
}

- (void)testMenuTabMusicAlbums {

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [app.cells/*@START_MENU_TOKEN@*/.staticTexts[@"Music Albums"]/*[[".cells.staticTexts[@\"Music Albums\"]",".staticTexts[@\"Music Albums\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];

    XCTAssertNotNil(app.navigationBars[@"Music Albums"]);

}

- (void)testMenuTabTVShows {

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [app.cells.staticTexts[@"TV Shows"] tap];

    XCTAssertNotNil(app.navigationBars[@"TV Shows"]);

}

- (void)testMenuTabLocalNetwork {

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [app.cells.staticTexts[@"Local Network"] tap];

    XCTAssertNotNil(app.navigationBars[@"Local Network"]);

}

- (void)testMenuTabNetworkStream {

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [app.cells.staticTexts[@"Network Stream"] tap];

    XCTAssertNotNil(app.navigationBars[@"Network Stream"]);

}

- (void)testMenuTabDownloads {

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    [app.cells.staticTexts[@"Downloads"] tap];

    XCTAssertNotNil(app.navigationBars[@"Downloads"]);

}

- (void)testMenuTabWifi {

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];

    [app.cells.staticTexts[@"Sharing via WiFi"] tap];

    XCTAssertFalse(app.tables.staticTexts[@"Inactive Server"].exists);
}

- (void)testMenuTabCloudServices {

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];

    [app.cells.staticTexts[@"Cloud Services"] tap];

    XCTAssertNotNil(app.navigationBars[@"Cloud Services"]);
}

- (void)testMenuTabSettings {

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];

    [app.cells.staticTexts[@"Settings"] tap];

    XCTAssertNotNil(app.navigationBars[@"Settings"]);
}

- (void)testMenuTabAbout {

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];

    [app.cells.staticTexts[@"About VLC for iOS"] tap];

    XCTAssertNotNil(app.navigationBars[@"About"]);
}

@end
