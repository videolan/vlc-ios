/*****************************************************************************
 * VLC_for_iOSTestVideoCodecs.m
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
#import "XCUIElement+Helpers.h"

@interface VLC_for_iOSTestVideoCodecs : XCTestCase
@property (nonatomic, strong) XCUIApplication *application;
@end

@implementation VLC_for_iOSTestVideoCodecs

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = YES;

    self.application = [[XCUIApplication alloc] init];
    [self.application launch];
    [[XCUIDevice sharedDevice] setOrientation:UIDeviceOrientationFaceUp];
}

- (void)testMovCodec
{
    [self playWithFilename:@"rtsp://184.72.239.149/vod/mp4:BigBuckBunny_175k.mov"];
}

- (void)testHEVCCodec10b
{
    [self playWithFilename:@"http://jell.yfish.us/media/jellyfish-90-mbps-hd-hevc-10bit.mkv"];
}

- (void)testHEVCCodec
{
    [self playWithFilename:@"http://jell.yfish.us/media/jellyfish-25-mbps-hd-hevc.mkv"];
}

- (void)testH264Codec
{
    [self playWithFilename:@"http://jell.yfish.us/media/jellyfish-25-mbps-hd-h264.mkv"];
}

#pragma mark - Private

- (void)playWithFilename:(NSString *)filename
{
    [self.application.tabBars.buttons[@"More"] tap];
    [self.application.staticTexts[@"Open Network Stream"] tap];

    XCUIElement *httpMyserverComFileMkvTextField = self.application.textFields[@"http://myserver.com/file.mkv"];
    [httpMyserverComFileMkvTextField tap];
    [httpMyserverComFileMkvTextField clearAndEnterText:filename];

    [[[XCUIApplication alloc] init].buttons[@"Open Network Stream"] tap];
    
    XCUIElement *displayTime = self.application.buttons[@"--:--"];
    __block NSPredicate *predicate = [NSPredicate predicateWithFormat:@"exists == 0"];

    [self expectationForPredicate:predicate evaluatedWithObject:displayTime handler:nil];
    //we wait for the displaytime to change
    [self waitForExpectationsWithTimeout:20.0 handler:^(NSError * _Nullable error) {
        //once it changes we tap the videoplayer to bring up the playelements
        [self.application.otherElements[@"Video Player"] doubleTap];
        XCUIElement *playpause = self.application.buttons[@"Play or Pause current playback"];
        predicate = [NSPredicate predicateWithFormat:@"exists == 1"];
        [self expectationForPredicate:predicate evaluatedWithObject:playpause handler:nil];
        [self waitForExpectationsWithTimeout:20.0 handler:nil];
    }];
}
@end

