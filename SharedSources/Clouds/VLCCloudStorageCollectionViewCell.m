/*****************************************************************************
 * VLCCloudStorageCollectionViewCell.m
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

#import "VLCCloudStorageCollectionViewCell.h"

@implementation VLCCloudStorageCollectionViewCell

- (void)setDropboxFile:(DBMetadata *)dropboxFile
{
    if (dropboxFile != _dropboxFile)
        _dropboxFile = dropboxFile;

    [self performSelectorOnMainThread:@selector(_updatedDisplayedInformation)
                           withObject:nil waitUntilDone:NO];
}

- (void)setBoxFile:(BoxItem *)boxFile
{
    if (boxFile != _boxFile)
        _boxFile = boxFile;

    [self performSelectorOnMainThread:@selector(_updatedDisplayedInformation)
                           withObject:nil waitUntilDone:NO];
}

- (void)setOneDriveFile:(VLCOneDriveObject *)oneDriveFile
{
    if (oneDriveFile != _oneDriveFile)
        _oneDriveFile = oneDriveFile;

    [self performSelectorOnMainThread:@selector(_updatedDisplayedInformation)
                           withObject:nil waitUntilDone:NO];
}


- (void)_updatedDisplayedInformation
{
    if (_dropboxFile != nil) {
        if (self.dropboxFile.isDirectory) {
            self.isDirectory = YES;
            self.title = self.dropboxFile.filename;
        } else {
            self.isDirectory = NO;
            self.subtitle = (self.dropboxFile.totalBytes > 0) ? self.dropboxFile.humanReadableSize : @"";

        }
        self.title = self.dropboxFile.filename;

        NSString *iconName = self.dropboxFile.icon;
        if ([iconName isEqualToString:@"folder_user"] || [iconName isEqualToString:@"folder"] || [iconName isEqualToString:@"folder_public"] || [iconName isEqualToString:@"folder_photos"] || [iconName isEqualToString:@"package"]) {
            self.thumbnailImage = [UIImage imageNamed:@"folder"];
        } else if ([iconName isEqualToString:@"page_white"] || [iconName isEqualToString:@"page_white_text"])
            self.thumbnailImage = [UIImage imageNamed:@"blank"];
        else if ([iconName isEqualToString:@"page_white_film"])
            self.thumbnailImage = [UIImage imageNamed:@"movie"];
        else if ([iconName isEqualToString:@"page_white_sound"])
            self.thumbnailImage = [UIImage imageNamed:@"audio"];
        else {
            self.thumbnailImage = [UIImage imageNamed:@"blank"];
            APLog(@"missing icon for type '%@'", self.dropboxFile.icon);
        }
    }
    else if(_boxFile != nil) {
        BOOL isDirectory = [self.boxFile.type isEqualToString:@"folder"];
        if (isDirectory) {
            self.isDirectory = YES;
            self.thumbnailImage = [UIImage imageNamed:@"folder"];
        } else {
            self.isDirectory = NO;
            self.subtitle = (self.boxFile.size > 0) ? [NSByteCountFormatter stringFromByteCount:[self.boxFile.size longLongValue] countStyle:NSByteCountFormatterCountStyleFile]: @"";
            self.thumbnailImage = [UIImage imageNamed:@"blank"];
        }
        self.title = self.boxFile.name;
    } else if(_oneDriveFile != nil) {
        if (_oneDriveFile.isFolder) {
            self.isDirectory = YES;
            self.thumbnailImage = [UIImage imageNamed:@"folder"];
        } else {
            self.isDirectory = NO;

            NSMutableString *subtitle = [[NSMutableString alloc] init];

            if (self.oneDriveFile.isAudio)
                self.thumbnailImage = [UIImage imageNamed:@"audio"];
            else if (self.oneDriveFile.isVideo) {
                self.thumbnailImage = [UIImage imageNamed:@"movie"];
                NSString *thumbnailURLString = _oneDriveFile.thumbnailURL;
                if (thumbnailURLString) {
                    [self setThumbnailURL:[NSURL URLWithString:thumbnailURLString]];
                }
            } else
                self.thumbnailImage = [UIImage imageNamed:@"blank"];
            self.title = self.oneDriveFile.name;

            if (self.oneDriveFile.size > 0) {
                [subtitle appendString:[NSByteCountFormatter stringFromByteCount:[self.oneDriveFile.size longLongValue] countStyle:NSByteCountFormatterCountStyleFile]];
                if (self.oneDriveFile.duration > 0) {
                    VLCTime *time = [VLCTime timeWithNumber:self.oneDriveFile.duration];
                    [subtitle appendFormat:@" — %@", [time verboseStringValue]];
                }
            } else if (self.oneDriveFile.duration > 0) {
                VLCTime *time = [VLCTime timeWithNumber:self.oneDriveFile.duration];
                [subtitle appendString:[time verboseStringValue]];
            }
            self.subtitle = subtitle;
        }
    }
}

@end
