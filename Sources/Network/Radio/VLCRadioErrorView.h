/*****************************************************************************
 * VLCRadioErrorView.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCRadioErrorView : UIView

- (instancetype)initWithMessage:(NSString *)message
                    retryTarget:(id)target
                    retryAction:(SEL)action;

@end

NS_ASSUME_NONNULL_END
