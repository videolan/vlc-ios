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

#import "VLCDeleteHintTVView.h"

@implementation VLCDeleteHintTVView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self sharedSetup];
    }
    return self;
}
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self sharedSetup];
}
- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    [self sharedSetup];
}

- (void)sharedSetup
{
    self.backgroundColor = nil;

    /*
     * Views
     */

    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    effectView.frame = self.bounds;
    effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    effectView.layer.cornerRadius = 5.0;
    effectView.clipsToBounds = YES;

    [self addSubview:effectView];
    self.effectView = effectView;

    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    UIColor *textColor = [UIColor whiteColor];

    UILabel *leadingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    leadingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    leadingLabel.font = font;
    leadingLabel.textColor = textColor;
    [self addSubview:leadingLabel];
    self.leadingLabel = leadingLabel;

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PlayPauseRemoteButton"]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.tintColor = textColor;
    [self addSubview:imageView];
    self.glyphImageView = imageView;

    UILabel *trailingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    trailingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    trailingLabel.font = font;
    trailingLabel.textColor = textColor;
    [self addSubview:trailingLabel];
    self.trailingLabel = trailingLabel;


    /*
     * Content
     */

    NSString *localizedString = NSLocalizedString(@"DELETE_ITEM_HINT", @"Insert %@ where play-pause-glyph should be placed");
    NSArray *strings = [localizedString componentsSeparatedByString:@"%@"];
    NSCharacterSet *trimmSet = [NSCharacterSet whitespaceCharacterSet];
    leadingLabel.text = [strings.firstObject stringByTrimmingCharactersInSet:trimmSet];
    if (strings.count > 1) {
        trailingLabel.text = [strings.lastObject stringByTrimmingCharactersInSet:trimmSet];
    }


    /*
     * Constraints
     */

    NSMutableArray<NSLayoutConstraint*> *constraints = [NSMutableArray array];

    // label margins
    const CGFloat sideMargin = -60.0;
    [constraints addObject:[self.leadingAnchor constraintEqualToAnchor:leadingLabel.leadingAnchor constant:sideMargin]];
    [constraints addObject:[trailingLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:sideMargin]];

    // image margins
    const CGFloat imageMargin = -16.0;
    [constraints addObject:[leadingLabel.trailingAnchor constraintEqualToAnchor:imageView.leadingAnchor constant:imageMargin]];
    [constraints addObject:[imageView.trailingAnchor constraintEqualToAnchor:trailingLabel.leadingAnchor constant:imageMargin]];
    [constraints addObject:[self.topAnchor constraintEqualToAnchor:imageView.topAnchor constant:imageMargin]];
    [constraints addObject:[self.bottomAnchor constraintEqualToAnchor:imageView.bottomAnchor constant:-imageMargin]];

    // vertical alignment
    [constraints addObject:[leadingLabel.centerYAnchor constraintEqualToAnchor:imageView.centerYAnchor]];
    [constraints addObject:[imageView.centerYAnchor constraintEqualToAnchor:trailingLabel.centerYAnchor]];

    [self addConstraints:constraints];
}

@end
