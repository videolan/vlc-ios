/*****************************************************************************
 * CPInterfaceController+VLCTemplateStack.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <CarPlay/CarPlay.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPInterfaceController (VLCTemplateStack)

- (void)pushTemplateWithinDepthLimit:(__kindof CPTemplate *)templateToPush animated:(BOOL)animated;
- (void)returnToRootTemplateAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
