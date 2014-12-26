/*****************************************************************************
 * VLCOneDriveController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "VLCOneDriveController.h"
#import "VLCOneDriveConstants.h"

/* the Live SDK doesn't have an umbrella header so we need to import what we need */
#import <LiveSDK/LiveConnectClient.h>

/* include private API headers */
#import <LiveSDK/LiveApiHelper.h>

@interface VLCOneDriveController () <LiveAuthDelegate, LiveDownloadOperationDelegate, LiveOperationDelegate>
{
    LiveConnectClient *_liveClient;
    NSArray *_liveScopes;
}

@end

@implementation VLCOneDriveController

+ (VLCOneDriveController *)sharedInstance
{
    static VLCOneDriveController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];

    if (!self)
        return self;

    _liveScopes = @[@"wl.signin",@"wl.basic",@"wl.skydrive"];

    _liveClient = [[LiveConnectClient alloc] initWithClientId:kVLCOneDriveClientID
                                                        scopes:_liveScopes
                                                     delegate:self
                                                    userState:@"init"];

    return self;
}

#pragma mark - authentication

- (void)login
{
    [_liveClient login:self.delegate
               scopes:_liveScopes
             delegate:self
            userState:@"login"];
}

- (void)logout
{
    [_liveClient logoutWithDelegate:self userState:@"logout"];
}

- (void)authCompleted:(LiveConnectSessionStatus)status session:(LiveConnectSession *)session userState:(id)userState
{
}

- (void)authFailed:(NSError *)error userState:(id)userState
{
}

#pragma mark - listing

- (void)requestDirectoryListingAtPath:(NSString *)path
{
}

- (void)liveOperationSucceeded:(LiveOperation *)operation
{
}

- (void)liveOperationFailed:(NSError *)error operation:(LiveOperation *)operation
{
}

#pragma mark - file handling

- (void)downloadFileWithPath:(NSString *)path
{
}

- (void)liveDownloadOperationProgressed:(LiveOperationProgress *)progress
                                   data:(NSData *)receivedData
                              operation:(LiveDownloadOperation *)operation
{
}

- (void)streamFileWithPath:(NSString *)path
{
}

@end
