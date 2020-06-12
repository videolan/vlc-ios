/*****************************************************************************
 * VLCExternalDisplayController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCExternalDisplayController.h"

@interface VLCExternalDisplayController ()

@end

@implementation VLCExternalDisplayController

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return ~UIInterfaceOrientationMaskAll;
}

@end
