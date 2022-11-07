/*****************************************************************************
 * VLCNowPlayingTemplateObserver.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import <CarPlay/CarPlay.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCNowPlayingTemplateObserver : NSObject <CPNowPlayingTemplateObserver>

- (void)configureNowPlayingTemplate;

@end

NS_ASSUME_NONNULL_END
