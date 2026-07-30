/*****************************************************************************
 * GoogleDriveShortcutTests.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Authors: Rex Technology
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <XCTest/XCTest.h>
#import "GTLRDrive_File+VLCShortcut.h"
#import "VLCGoogleDriveConstants.h"

@interface GoogleDriveShortcutTests : XCTestCase
@end

@implementation GoogleDriveShortcutTests

- (GTLRDrive_File *)fileWithJSON:(NSDictionary *)json
{
    return [GTLRDrive_File objectWithJSON:json];
}

- (void)testPlainFolderIsDirectory
{
    GTLRDrive_File *file = [self fileWithJSON:@{ @"id"       : @"folder-1",
                                                 @"name"     : @"Films",
                                                 @"mimeType" : kVLCGoogleDriveFolderMimeType }];

    XCTAssertTrue(file.vlc_isDirectory);
    XCTAssertFalse(file.vlc_isShortcut);
    XCTAssertEqualObjects(file.vlc_targetIdentifier, @"folder-1");
    XCTAssertEqualObjects(file.vlc_effectiveMimeType, kVLCGoogleDriveFolderMimeType);
}

- (void)testPlainVideoIsNotDirectory
{
    GTLRDrive_File *file = [self fileWithJSON:@{ @"id"       : @"video-1",
                                                 @"name"     : @"trailer.mkv",
                                                 @"mimeType" : @"video/x-matroska" }];

    XCTAssertFalse(file.vlc_isDirectory);
    XCTAssertFalse(file.vlc_isShortcut);
    XCTAssertEqualObjects(file.vlc_targetIdentifier, @"video-1");
}

- (void)testShortcutToFolderResolvesAsDirectory
{
    GTLRDrive_File *file = [self fileWithJSON:@{ @"id"       : @"shortcut-1",
                                                 @"name"     : @"Shared Films",
                                                 @"mimeType" : kVLCGoogleDriveShortcutMimeType,
                                                 @"shortcutDetails" : @{ @"targetId"       : @"folder-99",
                                                                         @"targetMimeType" : kVLCGoogleDriveFolderMimeType } }];

    XCTAssertTrue(file.vlc_isShortcut);
    XCTAssertTrue(file.vlc_isDirectory, @"a shortcut to a folder has to browse like a folder");
    XCTAssertEqualObjects(file.vlc_targetIdentifier, @"folder-99",
                          @"navigation and favourites have to use the target, not the shortcut");
    XCTAssertEqualObjects(file.vlc_effectiveMimeType, kVLCGoogleDriveFolderMimeType);
}

- (void)testShortcutToVideoResolvesAsFile
{
    GTLRDrive_File *file = [self fileWithJSON:@{ @"id"       : @"shortcut-2",
                                                 @"name"     : @"clip",
                                                 @"mimeType" : kVLCGoogleDriveShortcutMimeType,
                                                 @"shortcutDetails" : @{ @"targetId"       : @"video-99",
                                                                         @"targetMimeType" : @"video/mp4" } }];

    XCTAssertTrue(file.vlc_isShortcut);
    XCTAssertFalse(file.vlc_isDirectory);
    XCTAssertEqualObjects(file.vlc_targetIdentifier, @"video-99");
    XCTAssertEqualObjects(file.vlc_effectiveMimeType, @"video/mp4");
}

- (void)testShortcutWithoutDetailsFallsBackToItself
{
    GTLRDrive_File *file = [self fileWithJSON:@{ @"id"       : @"shortcut-3",
                                                 @"name"     : @"broken",
                                                 @"mimeType" : kVLCGoogleDriveShortcutMimeType }];

    XCTAssertTrue(file.vlc_isShortcut);
    XCTAssertFalse(file.vlc_isDirectory, @"an unresolvable shortcut must not pose as a folder");
    XCTAssertEqualObjects(file.vlc_targetIdentifier, @"shortcut-3");
    XCTAssertEqualObjects(file.vlc_effectiveMimeType, kVLCGoogleDriveShortcutMimeType);
}

@end
