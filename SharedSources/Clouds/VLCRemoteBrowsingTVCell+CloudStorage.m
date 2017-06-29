/*****************************************************************************
 * VLCRemoteBrowsingTVCell+CloudStorage.m
 * VLC for tvOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRemoteBrowsingTVCell+CloudStorage.h"

@implementation VLCRemoteBrowsingTVCell (CloudStorage)

- (void)setDropboxFile:(DBFILESMetadata *)dropboxFile
{
    [self performSelectorOnMainThread:@selector(_updateDropboxRepresentation:)
                           withObject:dropboxFile waitUntilDone:NO];
}

- (void)setBoxFile:(BoxItem *)boxFile
{
    [self performSelectorOnMainThread:@selector(_updateBoxRepresentation:)
                           withObject:boxFile waitUntilDone:NO];
}

- (void)setOneDriveFile:(VLCOneDriveObject *)oneDriveFile
{
    [self performSelectorOnMainThread:@selector(_updateOneDriveRepresentation:)
                           withObject:oneDriveFile waitUntilDone:NO];
}

- (void)_updateDropboxRepresentation:(DBFILESMetadata *)dropboxFile
{
    if (dropboxFile != nil) {
        if ([dropboxFile isKindOfClass: [DBFILESFolderMetadata class]]) {
            self.isDirectory = YES;
            self.thumbnailImage = [UIImage imageNamed:@"folder"];
        } else {
            DBFILESFileMetadata *file = (DBFILESFileMetadata *)dropboxFile;

            self.isDirectory = NO;
            self.subtitle = (file.size.integerValue > 0) ? [NSByteCountFormatter stringFromByteCount:file.size.longLongValue countStyle:NSByteCountFormatterCountStyleFile] : @"";
            self.thumbnailImage = [UIImage imageNamed:@"folder"];
        }
        self.title = dropboxFile.name;
    }
}

- (void)_updateBoxRepresentation:(BoxItem *)boxFile
{
    if (boxFile != nil) {
        BOOL isDirectory = [boxFile.type isEqualToString:@"folder"];
        if (isDirectory) {
            self.isDirectory = YES;
            self.thumbnailImage = [UIImage imageNamed:@"folder"];
        } else {
            self.isDirectory = NO;
            self.subtitle = (boxFile.size > 0) ? [NSByteCountFormatter stringFromByteCount:[boxFile.size longLongValue] countStyle:NSByteCountFormatterCountStyleFile]: @"";
            self.thumbnailImage = [UIImage imageNamed:@"blank"];
        }
        self.title = boxFile.name;
    }
}

- (void)_updateOneDriveRepresentation:(VLCOneDriveObject *)oneDriveFile
{
    if (oneDriveFile != nil) {
        if (oneDriveFile.isFolder) {
            self.isDirectory = YES;
            self.thumbnailImage = [UIImage imageNamed:@"folder"];
        } else {
            self.isDirectory = NO;

            NSMutableString *subtitle = [[NSMutableString alloc] init];
            self.thumbnailImage = [UIImage imageNamed:@"blank"];

            if (oneDriveFile.isVideo) {
                NSString *thumbnailURLString = oneDriveFile.thumbnailURL;
                if (thumbnailURLString) {
                    [self setThumbnailURL:[NSURL URLWithString:thumbnailURLString]];
                }
            }

            if (oneDriveFile.size > 0) {
                [subtitle appendString:[NSByteCountFormatter stringFromByteCount:[oneDriveFile.size longLongValue] countStyle:NSByteCountFormatterCountStyleFile]];
                if (oneDriveFile.duration > 0) {
                    VLCTime *time = [VLCTime timeWithNumber:oneDriveFile.duration];
                    [subtitle appendFormat:@" — %@", [time verboseStringValue]];
                }
            } else if (oneDriveFile.duration > 0) {
                VLCTime *time = [VLCTime timeWithNumber:oneDriveFile.duration];
                [subtitle appendString:[time verboseStringValue]];
            }
            self.subtitle = subtitle;
        }
        self.title = oneDriveFile.name;
    }
}

@end
