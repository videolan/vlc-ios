/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <QuartzCore/QuartzCore.h>

static NSString *const VLCWiggleAnimationKey = @"VLCWiggleAnimation";

@interface CAAnimation (VLCWiggle)
+ (instancetype)vlc_wiggleAnimationwithSoftMode:(BOOL)softmode;
@end
