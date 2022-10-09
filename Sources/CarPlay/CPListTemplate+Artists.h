/*****************************************************************************
 * CPListTemplate+Artists.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <CarPlay/CarPlay.h>

NS_ASSUME_NONNULL_BEGIN

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@interface CPListTemplate (Artists)

+ (CPListTemplate *)artistList;

@end

#pragma clang diagnostic pop

NS_ASSUME_NONNULL_END
