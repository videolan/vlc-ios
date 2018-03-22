/*****************************************************************************
 * VLCOneDriveObject.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOneDriveObject.h"
#import "VLCHTTPFileDownloader.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+VLC.h"

#if TARGET_OS_IOS
@interface VLCOneDriveObject () <VLCHTTPFileDownloader>
{
    VLCHTTPFileDownloader *_fileDownloader;
}

@end
#else
@interface VLCOneDriveObject ()

@end
#endif

@implementation VLCOneDriveObject

#pragma mark properties

- (BOOL)isFolder
{
    return [self.type isEqual:@"folder"] || [self.type isEqual:@"album"];
}

- (BOOL)isVideo
{
    return [self.type isEqual:@"video"];
}

- (BOOL)isAudio
{
    return [self.type isEqual:@"audio"];
}

- (NSString *)filesPath
{
    return [self.objectId stringByAppendingString:@"/files"];
}

- (BOOL)hasFullFolderTree
{
    BOOL hasFullTree = YES;

    if (self.folders != nil) {
        NSUInteger count = self.folders.count;

        for (NSUInteger x = 0; x < count; x++) {
            VLCOneDriveObject *folder = self.folders[x];
            if (!folder.hasFullFolderTree) {
                hasFullTree = NO;
                break;
            }
        }
    } else
        hasFullTree = NO;

    return hasFullTree;
}

#pragma mark - actions

- (void)loadFolderContent
{
    if (!self.isFolder) {
        APLog(@"%@ is no folder, can't load content", self.objectId);
        return;
    }

    if (self.folders == nil) {
        [self.liveClient getWithPath:self.filesPath
                            delegate:self
                           userState:@"load-folder-content"];
    } else {
        NSUInteger count = self.folders.count;

        for (NSUInteger x = 0; x < count; x++) {
            VLCOneDriveObject *folder = self.folders[x];
            if (!folder.hasFullFolderTree) {
                folder.delegate = self.delegate;
                [folder loadFolderContent];
                return;
            }
        }

        [self.delegate fullFolderTreeLoaded:self];
    }
}

#pragma mark - live operations

- (void)liveOperationSucceeded:(LiveDownloadOperation *)operation
{
    NSString *userState = operation.userState;

    if ([userState isEqualToString:@"load-folder-content"]) {
        NSMutableArray *subFolders = [[NSMutableArray alloc] init];
        NSMutableArray *folderFiles = [[NSMutableArray alloc] init];
        NSMutableArray *items = [[NSMutableArray alloc] init];
        NSArray *rawFolderObjects = operation.result[@"data"];
        BOOL hasSubFolders = NO;
        NSUInteger count = rawFolderObjects.count;

        for (NSUInteger x = 0; x < count; x++) {
            NSDictionary *rawObject = rawFolderObjects[x];
            VLCOneDriveObject *oneDriveObject = [[VLCOneDriveObject alloc] init];

            oneDriveObject.parent = self;
            oneDriveObject.objectId = rawObject[@"id"];
            oneDriveObject.name = rawObject[@"name"];
            oneDriveObject.type = rawObject[@"type"];

            oneDriveObject.liveClient = self.liveClient;

            if (oneDriveObject.isFolder) {
                hasSubFolders = YES;
                [subFolders addObject:oneDriveObject];
            } else {
                oneDriveObject.size = rawObject[@"size"];
                oneDriveObject.thumbnailURL = rawObject[@"picture"];
                oneDriveObject.downloadPath = rawObject[@"source"];

                if (oneDriveObject.isVideo)
                    oneDriveObject.subtitleURL = [self configureSubtitle:oneDriveObject.name folderItems:rawFolderObjects];

                oneDriveObject.duration = rawObject[@"duration"];
                [folderFiles addObject:oneDriveObject];
            }

            //Display only folders and supported files.
            if (oneDriveObject.isFolder || [oneDriveObject.name isSupportedFormat])
                [items addObject:oneDriveObject];

        }

        self.folders = subFolders;
        self.files = folderFiles;
        self.items = items;
        [self.delegate folderContentLoaded:self];
    }
}

- (void)liveOperationFailed:(NSError *)error operation:(LiveDownloadOperation *)operation
{
    NSString *userState = operation.userState;

    APLog(@"liveOperationFailed %@ (%@)", userState, error);

    if ([userState isEqualToString:@"load-folder-content"])
        [self.delegate folderContentLoadingFailed:error sender:self];
}

#pragma - subtitle

- (NSString *)configureSubtitle:(NSString *)fileName folderItems:(NSArray *)folderItems
{
    NSString *subtitleURL = nil;
    NSString *subtitlePath = [self _searchSubtitle:fileName folderItems:folderItems];

    if (subtitlePath)
        subtitleURL = [self _getFileSubtitleFromServer:[NSURL URLWithString:subtitlePath]];

    return subtitleURL;
}

- (NSString *)_searchSubtitle:(NSString *)fileName folderItems:(NSArray *)folderItems
{
    NSString *urlTemp = [[fileName lastPathComponent] stringByDeletingPathExtension];
    NSString *itemPath = nil;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", urlTemp];
    NSArray *results = [folderItems filteredArrayUsingPredicate:predicate];

    for (int cnt = 0; cnt < results.count; cnt++) {
        NSDictionary *dictObject = results[cnt];
        NSString *itemName = dictObject[@"name"];
        if ([itemName isSupportedSubtitleFormat])
            itemPath = dictObject[@"source"];
    }
    return itemPath;
}

- (NSString *)_getFileSubtitleFromServer:(NSURL *)subtitleURL
{
    NSString *FileSubtitlePath = nil;
    NSData *receivedSub = [NSData dataWithContentsOfURL:subtitleURL]; // TODO: fix synchronous load

    if (receivedSub.length < [[UIDevice currentDevice] VLCFreeDiskSpace].longLongValue) {
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *directoryPath = searchPaths[0];
        FileSubtitlePath = [directoryPath stringByAppendingPathComponent:[subtitleURL lastPathComponent]];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
            //create local subtitle file
            [fileManager createFileAtPath:FileSubtitlePath contents:nil attributes:nil];
            if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
                APLog(@"file creation failed, no data was saved");
                return nil;
            }
        }
        [receivedSub writeToFile:FileSubtitlePath atomically:YES];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                                                 message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), [subtitleURL lastPathComponent], [[UIDevice currentDevice] model]]
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];

        [alertController addAction:okAction];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    }

    return FileSubtitlePath;
}

#pragma mark - delegation

- (void)folderContentLoaded:(VLCOneDriveObject *)sender
{
}

- (void)folderContentLoadingFailed:(NSError *)error sender:(VLCOneDriveObject *)sender
{
    if (self.delegate)
        [self.delegate folderContentLoadingFailed:error sender:self];
}

- (void)fullFolderTreeLoaded:(VLCOneDriveObject *)sender
{
    [self loadFolderContent];
}

#pragma mark - file downloading

- (void)saveObjectToDocuments
{
#if TARGET_OS_IOS
    _fileDownloader = [[VLCHTTPFileDownloader alloc] init];
    _fileDownloader.delegate = self;
    [_fileDownloader downloadFileFromURL:[NSURL URLWithString:self.downloadPath] withFileName:self.name];
#endif
}

- (void)downloadStarted
{
    if ([self.downloadDelegate respondsToSelector:@selector(downloadStarted:)])
        [self.downloadDelegate downloadStarted:self];
}

- (void)downloadEnded
{
    if ([self.downloadDelegate respondsToSelector:@selector(downloadEnded:)])
        [self.downloadDelegate downloadEnded:self];
}

- (void)downloadFailedWithErrorDescription:(NSString *)description
{
    APLog(@"download failed (%@)", description);
}

- (void)progressUpdatedTo:(CGFloat)percentage receivedDataSize:(CGFloat)receivedDataSize expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    if ([self.downloadDelegate respondsToSelector:@selector(progressUpdated:)])
        [self.downloadDelegate progressUpdated:percentage];
    if ([self.downloadDelegate respondsToSelector:@selector(calculateRemainingTime:expectedDownloadSize:)])
        [self.downloadDelegate calculateRemainingTime:receivedDataSize expectedDownloadSize:expectedDownloadSize];
}

@end
