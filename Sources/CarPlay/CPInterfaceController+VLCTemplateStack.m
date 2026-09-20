/*****************************************************************************
 * CPInterfaceController+VLCTemplateStack.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "CPInterfaceController+VLCTemplateStack.h"

// CarPlay terminates the app as soon as a sixth template enters the hierarchy
static const NSUInteger VLCCarPlayMaximumTemplateDepth = 5;

@implementation CPInterfaceController (VLCTemplateStack)

- (void)pushTemplateWithinDepthLimit:(__kindof CPTemplate *)templateToPush animated:(BOOL)animated
{
    if (self.templates.count < VLCCarPlayMaximumTemplateDepth) {
        [self pushTemplate:templateToPush animated:animated completion:nil];
        return;
    }

    [self popTemplateAnimated:NO completion:^(BOOL success, NSError * _Nullable error) {
        [self pushTemplate:templateToPush animated:animated completion:nil];
    }];
}

- (void)returnToRootTemplateAnimated:(BOOL)animated
{
    [self popToRootTemplateAnimated:animated completion:nil];
}

@end
