/*****************************************************************************
 * VLCMLMedia+isWatched.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: İbrahim Çetin <cetinibrahim.ci # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import <VLCMediaLibraryKit/VLCMediaLibraryKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCMLMedia (isWatched)

- (BOOL)isWatched;

@end

NS_ASSUME_NONNULL_END
