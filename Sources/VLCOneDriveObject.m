/*****************************************************************************
 * VLCOneDriveObject.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOneDriveObject.h"

@implementation VLCOneDriveObject

#pragma mark properties

- (BOOL)isFolder
{
    return [self.type isEqual:@"folder"] || [self.type isEqual:@"album"];
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
    NSLog(@"loadFolderContent");
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
                [folder loadFolderContent];
                return;
            }
        }

        [self.delegate fullFolderTreeLoaded:self];
    }
}

- (void)loadFileContent
{
}

#pragma mark - live operations

- (void)liveOperationSucceeded:(LiveDownloadOperation *)operation
{
    NSString *userState = operation.userState;

    NSLog(@"liveOperationSucceeded: %@", userState);

    if ([userState isEqualToString:@"load-file-content"]) {
//        LiveDownloadOperation *downloadOperation = (LiveDownloadOperation *)operation;

        //FIXME: handle the incoming data!

        [self.delegate fileContentLoaded:self];
    } else if ([userState isEqualToString:@"load-folder-content"]) {
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
                oneDriveObject.duration = rawObject[@"duration"];
                [folderFiles addObject:oneDriveObject];
            }
            [items addObject:oneDriveObject];
        }

        NSLog(@"we found %i items", items.count);
        for (NSUInteger x = 0; x < items.count; x++)
            NSLog(@"%@", [items[x] name]);

        self.folders = subFolders;
        self.files = folderFiles;
        self.items = items;
        [self.delegate folderContentLoaded:self];
    }
}

- (void)liveOperationFailed:(NSError *)error operation:(LiveDownloadOperation *)operation
{
    NSString *userState = operation.userState;

    NSLog(@"liveOperationFailed %@ (%@)", userState, error);

    if ([userState isEqualToString:@"load-folder-content"])
        [self.delegate folderContentLoadingFailed:error sender:self];
    else if ([userState isEqualToString:@"load-file-content"])
        [self.delegate fileContentLoadingFailed:error sender:self];
    else
        APLog(@"failing live operation with state %@ failed with error %@", userState, error);
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

- (void)fileContentLoaded:(VLCOneDriveObject *)sender
{
}

- (void)fileContentLoadingFailed:(NSError *)error sender:(VLCOneDriveObject *)sender
{
}

@end
