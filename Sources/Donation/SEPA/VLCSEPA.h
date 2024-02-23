/*****************************************************************************
 * VLCSEPA.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCSEPA : NSObject

+ (BOOL)isAvailable;
+ (NSString *)authorizationTextForCurrentLocale;

@end

NS_ASSUME_NONNULL_END
