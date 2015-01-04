/*****************************************************************************
 * VLCOneDriveController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "VLCOneDriveController.h"
#import "VLCOneDriveConstants.h"
#import "VLCOneDriveObject.h"

/* the Live SDK doesn't have an umbrella header so we need to import what we need */
#import <LiveSDK/LiveConnectClient.h>

/* include private API headers */
#import <LiveSDK/LiveApiHelper.h>

@interface VLCOneDriveController () <LiveAuthDelegate, LiveDownloadOperationDelegate, VLCOneDriveObjectDelegate>
{
    LiveConnectClient *_liveClient;
    NSArray *_liveScopes;
    BOOL _activeSession;
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

    _liveScopes = @[@"wl.signin",@"wl.offline_access",@"wl.skydrive"];

    _liveClient = [[LiveConnectClient alloc] initWithClientId:kVLCOneDriveClientID
                                                       scopes:_liveScopes
                                                     delegate:self
                                                    userState:@"init"];

    return self;
}

#pragma mark - authentication

- (BOOL)activeSession
{
    return _activeSession;
}

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
    _activeSession = NO;
    _userAuthenticated = NO;
}

- (void)authCompleted:(LiveConnectSessionStatus)status session:(LiveConnectSession *)session userState:(id)userState
{
    NSLog(@"authCompleted, status %i, state %@", status, userState);

    if (status == 1 && session != NULL && [userState isEqualToString:@"init"])
        _activeSession = YES;
    else
        _activeSession = NO;

    if (status == 1 && session != NULL && [userState isEqualToString:@"login"])
        _userAuthenticated = YES;
    else
        _userAuthenticated = NO;

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(sessionWasUpdated)])
            [self.delegate performSelector:@selector(sessionWasUpdated)];
    }
}

- (void)authFailed:(NSError *)error userState:(id)userState
{
    APLog(@"OneDrive auth failed: %@, %@", error, userState);
    _activeSession = NO;

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(sessionWasUpdated)])
            [self.delegate performSelector:@selector(sessionWasUpdated)];
    }
}

- (void)liveOperationSucceeded:(LiveDownloadOperation *)operation
{
    APLog(@"ODC: liveOperationSucceeded (%@)", operation.userState);
}

- (void)liveOperationFailed:(NSError *)error operation:(LiveDownloadOperation *)operation
{
    APLog(@"ODC: liveOperationFailed %@ (%@)", error, operation.userState);
}

#pragma mark - listing

- (void)loadTopLevelFolder
{
    _rootFolder = [[VLCOneDriveObject alloc] init];
    _rootFolder.objectId = @"me/skydrive";
    _rootFolder.name = @"OneDrive";
    _rootFolder.type = @"folder";
    _rootFolder.liveClient = _liveClient;
    _rootFolder.delegate = self;

    _currentFolder = _rootFolder;
    [_rootFolder loadFolderContent];
}

- (void)loadCurrentFolder
{
    if (_currentFolder == nil)
        [self loadTopLevelFolder];
    else {
        _currentFolder.delegate = self;
        [_currentFolder loadFolderContent];
    }
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

#pragma mark - skydrive object delegation

- (void)folderContentLoaded:(VLCOneDriveObject *)sender
{
    if (self.delegate)
        [self.delegate performSelector:@selector(mediaListUpdated)];
}

- (void)folderContentLoadingFailed:(NSError *)error sender:(VLCOneDriveObject *)sender
{
    APLog(@"folder content loading failed %@", error);
}

- (void)fileContentLoaded:(VLCOneDriveObject *)sender
{
}

- (void)fileContentLoadingFailed:(NSError *)error sender:(VLCOneDriveObject *)sender
{
    APLog(@"file content loading failed %@", error);
}

- (void)fullFolderTreeLoaded:(VLCOneDriveObject *)sender
{
    if (self.delegate)
        [self.delegate performSelector:@selector(mediaListUpdated)];
}

@end
