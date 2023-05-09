/*****************************************************************************
 * VLCOneDriveController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOneDriveController.h"
#import "VLCOneDriveConstants.h"
#import "NSString+SupportedMedia.h"
#import <OneDriveSDK.h>

#if TARGET_OS_IOS
# import "VLC-Swift.h"
#endif

@interface VLCOneDriveController ()
{
    NSMutableArray *_pendingDownloads;
    BOOL _downloadInProgress;
    NSProgress *_progress;

    CGFloat _averageSpeed;
    CGFloat _fileSize;
    NSTimeInterval _startDL;
    NSTimeInterval _lastStatsUpdate;

    ODClient *_oneDriveClient;
    NSMutableArray *_currentItems;
}

@end

static void *ProgressObserverContext = &ProgressObserverContext;

@implementation VLCOneDriveController

+ (VLCCloudStorageController *)sharedInstance
{
    static VLCOneDriveController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [[VLCOneDriveController alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];

    if (self) {
        _oneDriveClient = [ODClient loadCurrentClient];
        [self setupSession];
    }
    return self;
}

- (void)setupSession
{
    _parentItem = nil;
    _currentItem  = nil;
    _rootItemID = nil;
    _currentItems = [[NSMutableArray alloc] init];
}

#pragma mark - authentication

- (BOOL)activeSession
{
    return _oneDriveClient != nil;
}

- (void)loginWithViewController:(UIViewController *)presentingViewController
{
    _presentingViewController = presentingViewController;

    if (@available(iOS 11.0, *)) {
        [[UINavigationBar appearance] setPrefersLargeTitles:NO];
    }

    [ODClient authenticatedClientWithCompletion:^(ODClient *client, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (@available(iOS 11.0, *)) {
                [VLCAppearanceManager setupAppearanceWithTheme:PresentationTheme.current];
            }
            if (@available(iOS 13.0, *)) {
                [VLCAppearanceManager setupUserInterfaceStyleWithTheme:PresentationTheme.current];
            }
        });
        if (error) {
            [self authFailed:error];
            return;
        }
        self->_oneDriveClient = client;
        [self authSuccess];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate) {
                if ([self.delegate respondsToSelector:@selector(sessionWasUpdated)])
                    [self.delegate performSelector:@selector(sessionWasUpdated)];
            }
        });
    }];
}

- (void)logout
{
    [_oneDriveClient signOutWithCompletion:^(NSError *error) {
        NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
        [ubiquitousStore removeObjectForKey:kVLCStoreOneDriveCredentials];
        [ubiquitousStore synchronize];
        self->_oneDriveClient = nil;
        self->_currentItem  = nil;
        self->_currentItems = nil;
        self->_rootItemID = nil;
        self->_parentItem = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate) {
                [self.delegate performSelector:@selector(mediaListUpdated)];
            }
            if (self->_presentingViewController) {
                [self->_presentingViewController.navigationController popViewControllerAnimated:YES];
            }
        });
    }];
}

- (NSArray *)currentListFiles
{
    return [_currentItems copy];
}

- (BOOL)isAuthorized
{
    return _oneDriveClient != nil;
}

- (void)sessionWasUpdated
{
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(sessionWasUpdated)])
            [self.delegate performSelector:@selector(sessionWasUpdated)];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCOneDriveControllerSessionUpdated object:self];
}

- (void)authSuccess
{
    APLog(@"VLCOneDriveController: Authentication complete.");

    [self setupSession];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self sessionWasUpdated];
    });
}

- (void)authFailed:(NSError *)error
{
    APLog(@"VLCOneDriveController: Authentication failure.");

    dispatch_async(dispatch_get_main_queue(), ^{
        [self sessionWasUpdated];
    });
}

#pragma mark - listing

- (void)requestDirectoryListingAtPath:(NSString *)path
{
    [self loadODItems];
}

- (void)prepareODItems:(NSArray<ODItem *> *)items
{
    for (ODItem *item in items) {
        if (!_rootItemID) {
            _rootItemID = item.parentReference.id;
        }

        if (![_currentItems containsObject:item.id] && ([item.name isSupportedFormat] || item.folder)) {
            [_currentItems addObject:item];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate) {
            [self.delegate performSelector:@selector(mediaListUpdated)];
        }
    });

}

- (void)loadODItemsContinueWithRequest:(ODChildrenCollectionRequest *)request
                                result:(NSMutableArray *)result
{
    __weak typeof(self) weakSelf = self;
    [request getWithCompletion:^(ODCollection *response,
                                 ODChildrenCollectionRequest *nextRequest, NSError *error) {
        if (!error) {
            [result addObjectsFromArray:response.value];
            if (nextRequest != NULL) {
                [weakSelf loadODItemsContinueWithRequest:nextRequest result:result];
            } else {
                [weakSelf sendMediaListUpdateWithContent:result completionHandler:NULL];
            }
        } else {
            [weakSelf handleLoadODItemErrorWithError:error itemID:@"root"];
        }
    }];
}

- (void)loadODItemsWithCompletionHandler:(void (^)(void))completionHandler
{
    NSString *itemID = _currentItem ? _currentItem.id : @"root";
    ODChildrenCollectionRequest * request = [[[[_oneDriveClient drive] items:itemID] children] request];
    NSMutableArray<ODItem *> *requestContent = [[NSMutableArray alloc] init];

    // Clear all current
    [_currentItems removeAllObjects];

    __weak typeof(self) weakSelf = self;

    [request getWithCompletion:^(ODCollection *response, ODChildrenCollectionRequest *nextRequest, NSError *error) {
        if (!error) {
            if (nextRequest != NULL) {
                [weakSelf loadODItemsContinueWithRequest:nextRequest result:requestContent];
            } else {
                [weakSelf sendMediaListUpdateWithContent:response.value
                                       completionHandler:completionHandler];
            }
        } else {
            [weakSelf handleLoadODItemErrorWithError:error itemID:itemID];
        }
    }];
}

- (void)sendMediaListUpdateWithContent:(NSArray *)content completionHandler:(void (^)(void))completionHandler
{
    [self prepareODItems:content];
    if (completionHandler) {
        completionHandler();
    }
}

- (void)handleLoadODItemErrorWithError:(NSError *)error itemID:(NSString *)itemID
{
    __weak typeof(self) weakSelf = self;

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[error localizedFailureReason]
                                                                             message:[error localizedDescription]
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction *alertAction) {
                                                         if (weakSelf.presentingViewController && [itemID isEqualToString:@"root"]) {
                                                             [weakSelf.presentingViewController.navigationController popViewControllerAnimated:YES];
                                                         }
                                                     }];

    [alertController addAction:okAction];

    if (weakSelf.presentingViewController) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.presentingViewController presentViewController:alertController animated:YES completion:nil];
        });
    }
}

- (void)loadODParentItem
{
    NSString *parentID = _parentItem.id ? _parentItem.id : @"root";

    ODItemRequest *request = [[[_oneDriveClient drive] items:parentID] request];

    __weak typeof(self) weakSelf = self;

    [request getWithCompletion:^(ODItem *response, NSError *error) {
        if (!error) {
            weakSelf.parentItem = response;
        } else {
            [weakSelf handleLoadODItemErrorWithError:error itemID:parentID];
        }
    }];
}

- (void)loadODItems
{
    [self loadODItemsWithCompletionHandler:nil];
}

- (void)loadThumbnails:(NSArray<ODItem *> *)items
{
    for (ODItem *item in items) {
        if ([item thumbnails:0]) {
            [[[[[_oneDriveClient.drive items:item.id] thumbnails:@"0"] small] contentRequest]
             downloadWithCompletion:^(NSURL *location, NSURLResponse *response, NSError *error) {
                 if (!error) {
                 }
             }];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate) {
            [self.delegate performSelector:@selector(mediaListUpdated)];
        }
    });
}

#pragma - subtitle

- (NSString *)configureSubtitleWithFileName:(NSString *)fileName folderItems:(NSArray *)folderItems
{
    return [self _getFileSubtitleFromServer:[self _searchSubtitle:fileName folderItems:folderItems]];
}

- (NSMutableDictionary *)_searchSubtitle:(NSString *)fileName folderItems:(NSArray *)folderItems
{
    NSMutableDictionary *itemSubtitle = [[NSMutableDictionary alloc] init];

    NSString *urlTemp = [[fileName lastPathComponent] stringByDeletingPathExtension];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", urlTemp];
    NSArray *results = [folderItems filteredArrayUsingPredicate:predicate];

    for (ODItem *item in results) {
        if ([item.name isSupportedSubtitleFormat]) {
            [itemSubtitle setObject:item.name forKey:@"filename"];
            [itemSubtitle setObject:[NSURL URLWithString:item.dictionaryFromItem[@"@content.downloadUrl"]] forKey:@"url"];
        }
    }
    return itemSubtitle;
}

- (NSString *)_getFileSubtitleFromServer:(NSMutableDictionary *)itemSubtitle
{
    NSString *fileSubtitlePath = nil;
    if (itemSubtitle[@"filename"]) {
        NSData *receivedSub = [NSData dataWithContentsOfURL:[itemSubtitle objectForKey:@"url"]]; // TODO: fix synchronous load

        if (receivedSub.length < [[UIDevice currentDevice] VLCFreeDiskSpace].longLongValue) {
            NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *directoryPath = searchPaths.firstObject;
            fileSubtitlePath = [directoryPath stringByAppendingPathComponent:[itemSubtitle objectForKey:@"filename"]];

            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:fileSubtitlePath]) {
                //create local subtitle file
                [fileManager createFileAtPath:fileSubtitlePath contents:nil attributes:nil];
                if (![fileManager fileExistsAtPath:fileSubtitlePath]) {
                    APLog(@"file creation failed, no data was saved");
                    return nil;
                }
            }
            [receivedSub writeToFile:fileSubtitlePath atomically:YES];
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                                                     message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil),
                                                                                              [itemSubtitle objectForKey:@"filename"],
                                                                                              [[UIDevice currentDevice] model]]
                                                                              preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];

            [alertController addAction:okAction];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
        }
    }

    return fileSubtitlePath;
}

#pragma mark - file handling

- (BOOL)canPlayAll
{
    return YES;
}

- (void)startDownloadingODItem:(ODItem *)item
{
    if (item == nil)
        return;
    if (item.folder)
        return;

    if (!_pendingDownloads)
        _pendingDownloads = [[NSMutableArray alloc] init];
    [_pendingDownloads addObject:item];

    [self _triggerNextDownload];
}

- (void)downloadODItem:(ODItem *)item
{
    [self downloadStarted];
    ODURLSessionDownloadTask *task = [[[_oneDriveClient.drive items:item.id] contentRequest]
     downloadWithCompletion:^(NSURL *filePath, NSURLResponse *response, NSError *error) {
         if (error) {
             [self downloadFailedWithErrorDescription: error.localizedDescription];
         } else {
             NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                          NSUserDomainMask, YES).firstObject;
             NSString *newFilePath = [self createPotentialPathFrom:[documentPath
                                                                    stringByAppendingPathComponent:item.name]];
             NSError *movingError;

             [[NSFileManager defaultManager] moveItemAtURL:filePath
                                                     toURL:[NSURL fileURLWithPath:newFilePath] error:&movingError];

             if (movingError) {
                 [self downloadFailedWithErrorDescription: movingError.localizedDescription];
             }
         }
         dispatch_async(dispatch_get_main_queue(), ^{
             [self downloadEnded];
         });
     }];
    task.progress.totalUnitCount = item.size;
    [self showProgress:task.progress];
}

- (void)_triggerNextDownload
{
    if (_pendingDownloads.count > 0 && !_downloadInProgress) {
        _downloadInProgress = YES;
        [self downloadODItem:_pendingDownloads.firstObject];
        [_pendingDownloads removeObjectAtIndex:0];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];
    }
}

- (void)downloadStarted
{
    _startDL = [NSDate timeIntervalSinceReferenceDate];
    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStarted)])
        [self.delegate operationWithProgressInformationStarted];
}

- (void)downloadEnded
{
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"GDRIVE_DOWNLOAD_SUCCESSFUL", nil));

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
        [self.delegate operationWithProgressInformationStopped];

#if TARGET_OS_IOS
    // FIXME: Replace notifications by cleaner observers
    [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.VLCNewFileAddedNotification
                                                        object:self];
#endif
    [self hideProgress];
    _downloadInProgress = NO;
    [self _triggerNextDownload];
}

- (void)downloadFailedWithErrorDescription:(NSString *)description
{
    APLog(@"VLCOneDriveController: Download failed (%@)", description);
}

- (void)showProgress:(NSProgress *)progress
{
    _progress = progress;
    [progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:0 context:ProgressObserverContext];
}

- (void)hideProgress
{
    if (_progress) {
        [_progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) context:ProgressObserverContext];
        _progress = nil;
    }
}

- (void)progressUpdatedTo:(CGFloat)percentage receivedDataSize:(CGFloat)receivedDataSize expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    [self progressUpdated:percentage];
    [self calculateRemainingTime:receivedDataSize expectedDownloadSize:expectedDownloadSize];
}

- (void)progressUpdated:(CGFloat)progress
{
    if ([self.delegate respondsToSelector:@selector(currentProgressInformation:)])
        [self.delegate currentProgressInformation:progress];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ProgressObserverContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSProgress *progress = object;
            [self progressUpdatedTo:progress.fractionCompleted receivedDataSize:progress.completedUnitCount expectedDownloadSize:progress.totalUnitCount];
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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

@end
