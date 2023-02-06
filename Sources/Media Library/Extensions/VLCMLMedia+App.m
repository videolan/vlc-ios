/*****************************************************************************
 * VLCMLMedia+App.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMLMedia+App.h"
#import "VLCAppCoordinator.h"
#import "VLC-Swift.h"

@implementation VLCMLMedia(AppExtension)

+ (VLCMLMedia *)mediaForPlayingMedia:(VLCMedia *)media
{
    return [[VLCAppCoordinator sharedInstance].mediaLibraryService fetchMediaWith:media.url];
}

@end
