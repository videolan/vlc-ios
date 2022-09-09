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

- (void)setBoxFile:(BoxItem *)boxFile
{
    [self performSelectorOnMainThread:@selector(_updateBoxRepresentation:)
                           withObject:boxFile waitUntilDone:NO];
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
            self.subtitle = (boxFile.size.intValue > 0) ? [NSByteCountFormatter stringFromByteCount:[boxFile.size longLongValue] countStyle:NSByteCountFormatterCountStyleFile]: @"";
            self.thumbnailImage = [UIImage imageNamed:@"blank"];
        }
        self.title = boxFile.name;
    }
}

@end
