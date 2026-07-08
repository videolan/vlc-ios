/*****************************************************************************
 * VLCAppCoordinator.m
 * VLC for watchOS
 *****************************************************************************
 * Copyright (c) 2025 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Fahri Novaldi <fnovaldi@icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppCoordinator.h"
#import "VLC-Swift.h"

@interface VLCAppCoordinator()
{
    MediaLibraryService *_mediaLibraryService;
    MediaLibraryService *_snapshotMediaLibraryService;
}

@end

@implementation VLCAppCoordinator

+ (instancetype)sharedInstance
{
    static VLCAppCoordinator *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCAppCoordinator new];
    });

    return sharedInstance;
}

- (MediaLibraryService *)mediaLibraryService
{
    if (!_mediaLibraryService) {
        _mediaLibraryService = [[MediaLibraryService alloc] initWithLibraryType:MLServiceTypeMediaLibrary];
    }
    return _mediaLibraryService;
}

- (MediaLibraryService *)snapshotMediaLibraryService
{
    if (!_snapshotMediaLibraryService) {
        _snapshotMediaLibraryService = [[MediaLibraryService alloc] initWithLibraryType:MLServiceTypeSnapshotLibrary];
    }
    return _snapshotMediaLibraryService;
}

- (VLCMLMedia *)mediaForUserActivity:(NSUserActivity *)userActivity
{
    VLCMLIdentifier identifier = 0;
    NSDictionary *userInfo = userActivity.userInfo;

    // On watchOS, we only support the playingmedia userInfo key
    identifier = [userInfo[@"playingmedia"] integerValue];

    if (identifier > 0) {
        return [self.mediaLibraryService mediaFor:identifier];
    }

    return nil;
}

@end
