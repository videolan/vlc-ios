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
}

- (void)testNavigationToTabAudio
{
    [self.application.tabBars.buttons[@"Audio"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"Audio"]);
}

- (void)testNavigationToLocalNetwork
{
    [self.application.tabBars.buttons[@"Local Network"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"Local Network"]);
}

- (void)testNavigationToTabVideo
{
    [self.application.tabBars.buttons[@"Video"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"Video"]);
}

- (void)testNavigationToTabSettings
{
    [self.application.tabBars.buttons[@"Settings"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"Settings"]);
}

- (void)testNavigationToTabMore
{
    [self.application.tabBars.buttons[@"More"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"More"]);
}

- (void)testNavigationToCloudServices
{
    [self.application.tabBars.buttons[@"More"] tap];
    [self.application.staticTexts[@"Cloud Services"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"Cloud Services"]);
}

- (void)testNavigationToDownloads
{
    [self.application.tabBars.buttons[@"More"] tap];
    [self.application.staticTexts[@"Downloads"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"Downloads"]);
}

- (void)testNavigationToOpenNetworkStream
{
    [self.application.tabBars.buttons[@"More"] tap];
    [self.application.staticTexts[@"Open Network Stream"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"Open Network Stream"]);
}

- (void)testNavigationToAbout
{
    [self.application.tabBars.buttons[@"More"] tap];
    [self.application.staticTexts[@"About"] tap];

    XCTAssertNotNil(self.application.navigationBars[@"About"]);
}

@end
