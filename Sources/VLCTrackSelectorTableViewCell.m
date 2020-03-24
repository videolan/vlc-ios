/*****************************************************************************
 * VLCTrackSelectorTableViewCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2020 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCTrackSelectorTableViewCell.h"

@implementation VLCTrackSelectorTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self prepareForReuse];
    }
    return self;
}

- (void)setShowsCurrentTrack
{
    self.backgroundColor = [UIColor VLCLightTextColor];
    self.textLabel.textColor = [UIColor VLCDarkBackgroundColor];
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.backgroundColor = [UIColor clearColor];
    self.textLabel.textColor = [UIColor VLCLightTextColor];
}
@end
