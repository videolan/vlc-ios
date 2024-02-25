/*****************************************************************************
 * VLCAppCoordinator.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppCoordinator.h"
#import "VLCRemoteControlService.h"
#import "VLCHTTPUploaderController.h"
#import "VLCFavoriteService.h"
#import "VLC-Swift.h"

@interface VLCAppCoordinator()
{
    VLCHTTPUploaderController *_httpUploaderController;
    VLCRemoteControlService *_remoteControlService;
    VLCFavoriteService *_favoriteService;
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Init the HTTP Server
        _httpUploaderController = [[VLCHTTPUploaderController alloc] init];
        // in contrast to the iOS port, never clean the cache! We don't have ~/Documents here!

        _remoteControlService = [[VLCRemoteControlService alloc] init];
    }
    return self;
}

- (VLCHTTPUploaderController *)httpUploaderController
{
    return _httpUploaderController;
}

- (VLCFavoriteService *)favoriteService
{
    if (!_favoriteService) {
        _favoriteService = [[VLCFavoriteService alloc] init];
    }

    return _favoriteService;
}

@end
