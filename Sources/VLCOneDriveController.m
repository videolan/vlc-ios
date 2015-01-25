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

@interface VLCOneDriveController () <LiveAuthDelegate, VLCOneDriveObjectDelegate, VLCOneDriveObjectDownloadDelegate>
{
    LiveConnectClient *_liveClient;
    //VLCOneDriveObject *_folderiD;
    NSString *_folderId;
    NSArray *_liveScopes;
    BOOL _activeSession;
    BOOL _userAuthenticated;

    NSMutableArray *_pendingDownloads;
    BOOL _downloadInProgress;

    CGFloat _averageSpeed;
    CGFloat _fileSize;
    NSTimeInterval _startDL;
    NSTimeInterval _lastStatsUpdate;
}

@end

@implementation VLCOneDriveController

+ (VLCCloudStorageController *)sharedInstance
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
    _currentFolder = nil;
    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (NSArray *)currentListFiles
{
    return _currentFolder.items;
}

- (BOOL)isAuthorized
{
    return _liveClient.session != NULL;
}

- (void)authCompleted:(LiveConnectSessionStatus)status session:(LiveConnectSession *)session userState:(id)userState
{
    APLog(@"OneDrive: authCompleted, status %i, state %@", status, userState);

    if (session != NULL && [userState isEqualToString:@"init"] && status == 1)
        _activeSession = YES;

    if (session != NULL && [userState isEqualToString:@"login"] && status == 1)
        _userAuthenticated = YES;

    if (status == 0) {
        _activeSession = NO;
        _userAuthenticated = NO;
    }

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(sessionWasUpdated)])
            [self.delegate performSelector:@selector(sessionWasUpdated)];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCOneDriveControllerSessionUpdated object:self];
}

- (void)authFailed:(NSError *)error userState:(id)userState
{
    APLog(@"OneDrive auth failed: %@, %@", error, userState);
    _activeSession = NO;

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(sessionWasUpdated)])
            [self.delegate performSelector:@selector(sessionWasUpdated)];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCOneDriveControllerSessionUpdated object:self];
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

- (void)requestDirectoryListingAtPath:(NSString *)path
{
    [self loadCurrentFolder];
}

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

- (void)downloadObject:(VLCOneDriveObject *)object
{
    if (object.isFolder)
        return;

    object.downloadDelegate = self;
    if (!_pendingDownloads)
        _pendingDownloads = [[NSMutableArray alloc] init];
    [_pendingDownloads addObject:object];

    [self _triggerNextDownload];
}

- (void)_triggerNextDownload
{
    if (_pendingDownloads.count > 0 && !_downloadInProgress) {
        _downloadInProgress = YES;
        [_pendingDownloads[0] saveObjectToDocuments];
        [_pendingDownloads removeObjectAtIndex:0];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];
    }
}

- (void)downloadStarted:(VLCOneDriveObject *)object
{
    _startDL = [NSDate timeIntervalSinceReferenceDate];
    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStarted)])
        [self.delegate operationWithProgressInformationStarted];
}

- (void)downloadEnded:(VLCOneDriveObject *)object
{
    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
        [self.delegate operationWithProgressInformationStopped];

    _downloadInProgress = NO;
    [self _triggerNextDownload];
}

- (void)progressUpdated:(CGFloat)progress
{
    if ([self.delegate respondsToSelector:@selector(currentProgressInformation:)])
        [self.delegate currentProgressInformation:progress];
}

- (void)calculateRemainingTime:(CGFloat)receivedDataSize expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    CGFloat lastSpeed = receivedDataSize / ([NSDate timeIntervalSinceReferenceDate] - _startDL);
    CGFloat smoothingFactor = 0.005;
    _averageSpeed = isnan(_averageSpeed) ? lastSpeed : smoothingFactor * lastSpeed + (1 - smoothingFactor) * _averageSpeed;

    CGFloat RemainingInSeconds = (expectedDownloadSize - receivedDataSize)/_averageSpeed;

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:RemainingInSeconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSString  *remaingTime = [formatter stringFromDate:date];
    if ([self.delegate respondsToSelector:@selector(updateRemainingTime:)])
        [self.delegate updateRemainingTime:remaingTime];
}

#pragma mark - onedrive object delegation

- (void)folderContentLoaded:(VLCOneDriveObject *)sender
{
    if (self.delegate)
        [self.delegate performSelector:@selector(mediaListUpdated)];
}

- (void)folderContentLoadingFailed:(NSError *)error sender:(VLCOneDriveObject *)sender
{
    APLog(@"folder content loading failed %@", error);
}

- (void)fullFolderTreeLoaded:(VLCOneDriveObject *)sender
{
    if (self.delegate)
        [self.delegate performSelector:@selector(mediaListUpdated)];
}

@end
