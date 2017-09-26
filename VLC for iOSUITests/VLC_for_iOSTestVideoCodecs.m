//
//  VLC_for_iOSTestVideoCodecs.m
//  VLC for iOSUITests
//
//  Created by Carola Nitz on 9/25/17.
//  Copyright © 2017 VideoLAN. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface XCUIElement(Test)

- (void)clearAndEnterText:(NSString *)text;

@end

@implementation XCUIElement(Test)

- (void)clearAndEnterText:(NSString *)text {
    if( ![[self value] isKindOfClass:[NSString class]]) {
        XCTFail("Tried to clear and enter text into a non string value");
        return;
    }

    [self tap];
    NSString *deleteString = @"";
    for (int i = 0; i < [(NSString *)[self value] length]; i++){
        deleteString = [deleteString stringByAppendingString:XCUIKeyboardKeyDelete];
    }

    [self typeText:deleteString];
    [self typeText:text];
}
@end

@interface VLC_for_iOSTestVideoCodecs : XCTestCase

@end

@implementation VLC_for_iOSTestVideoCodecs

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

- (void)playWithFilename:(NSString *)filename
{
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.navigationBars[@"All Files"].buttons[@"Open VLC sidebar menu"] tap];
    
    [app.cells.staticTexts[@"Network Stream"] tap];

    XCUIElement *httpMyserverComFileMkvTextField = app.textFields.allElementsBoundByIndex.firstObject;

    [httpMyserverComFileMkvTextField clearAndEnterText:filename];
    [[[XCUIApplication alloc] init].buttons[@"Open Network Stream"] tap];
    
    XCUIElement *displayTime = app.buttons[@"--:--"];
    __block NSPredicate *predicate = [NSPredicate predicateWithFormat:@"exists == 0"];

    [self expectationForPredicate:predicate evaluatedWithObject:displayTime handler:nil];
    //we wait for the displaytime to change
    [self waitForExpectationsWithTimeout:20.0 handler:^(NSError * _Nullable error) {
        //once it changes we tap the videoplayer to bring up the playelements
        [app.otherElements[@"Video Player"] doubleTap];
        XCUIElement *playpause = app.buttons[@"Play or Pause current playback"];
        predicate = [NSPredicate predicateWithFormat:@"exists == 1"];
        [self expectationForPredicate:predicate evaluatedWithObject:playpause handler:nil];
        [self waitForExpectationsWithTimeout:20.0 handler:nil];
    }];
}
@end

