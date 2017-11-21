/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkLoginViewButtonCell.h"
NSString * const kVLCNetworkLoginViewButtonCellIdentifier = @"VLCNetworkLoginViewButtonCellIdentifier";

@interface VLCNetworkLoginViewButtonCell ()
@property (nonatomic) UIView *blackView;
@end
@implementation VLCNetworkLoginViewButtonCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor VLCDarkBackgroundColor];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.accessibilityTraits = UIAccessibilityTraitButton;

        UIView *blackView = [[UIView alloc] init];
        [self insertSubview:blackView atIndex:0];
        blackView.backgroundColor = [UIColor blackColor];
        self.blackView = blackView;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.blackView.frame = CGRectInset(self.bounds, 0.0, 2.0);
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.titleString = nil;
}

- (void)setTitleString:(NSString *)title
{
    self.textLabel.text = title;
    self.accessibilityValue = title;
}
- (NSString *)titleString
{
    return self.textLabel.text;
}

@end
