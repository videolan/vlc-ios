/*****************************************************************************
 * VLCRadioCountry.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

@protocol VLCNetworkServerBrowser;
@class UIImage;

NS_ASSUME_NONNULL_BEGIN

@interface VLCRadioCountry : NSObject <NSCoding>

- (instancetype)initWithMrl:(NSString *)mrl;

@property (readonly, copy) NSString *mrl;
@property (readonly) NSString *localizedName;
@property (readonly, nullable) UIImage *flagImage;

- (nullable id<VLCNetworkServerBrowser>)makeServerBrowser;

@end

NS_ASSUME_NONNULL_END
