/*****************************************************************************
 * VLCMLMedia+App.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import <VLCMediaLibraryKit/VLCMediaLibraryKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCMLMedia(AppExtension)

+ (VLCMLMedia *_Nullable)mediaForPlayingMedia:(nullable VLCMedia *)media;

@end

NS_ASSUME_NONNULL_END
