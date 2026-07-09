/*****************************************************************************
 * NSString+SupportedMedia.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "NSString+SupportedMedia.h"
#import <VLCMediaLibraryKit/VLCMediaLibrary.h>

@implementation NSString (SupportedMedia)

- (BOOL)isSupportedMediaFormat
{
    return [VLCMediaLibrary isMediaExtensionSupported:self.pathExtension];
}

- (BOOL)isSupportedSubtitleFormat
{
    return [VLCMediaLibrary isSubtitleExtensionSupported:self.pathExtension];
}

- (BOOL)isSupportedPlaylistFormat
{
    return [VLCMediaLibrary isPlaylistExtensionSupported:self.pathExtension];
}

- (BOOL)isSupportedFormat
{
    NSString *extension = self.pathExtension;
    return [VLCMediaLibrary isMediaExtensionSupported:extension]
        || [VLCMediaLibrary isSubtitleExtensionSupported:extension];
}

@end
