/*****************************************************************************
 * VLCTrackSelectorHeaderView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCTrackSelectorHeaderView.h"
#import "UIDevice+VLC.h"

@implementation VLCTrackSelectorHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];

    if (!self)
        return self;

    self.contentView.backgroundColor = [UIColor VLCDarkBackgroundColor];
    self.textLabel.textColor = [UIColor whiteColor];
    self.opaque = NO;
    self.alpha = .8;

    return self;
}

@end
