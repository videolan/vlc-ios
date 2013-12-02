/*****************************************************************************
 * VLCSidebarViewCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSidebarViewCell.h"

@implementation VLCSidebarViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];

        UIView *bgView = [[UIView alloc] init];
        bgView.backgroundColor = [UIColor colorWithRed:0.1137 green:0.1137 blue:0.1137 alpha:1.0f];
        self.selectedBackgroundView = bgView;

        self.imageView.contentMode = UIViewContentModeCenter;
        self.titleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 260.0f, 50.0f)];
        self.titleImageView.contentMode = UIViewContentModeCenter;
        [self.textLabel.superview addSubview:self.titleImageView];

        self.textLabel.font = [UIFont fontWithName:@"Helvetica" size:([UIFont systemFontSize] * 1.2f)];
        self.textLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
        self.textLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.25f];
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        if ([self.textLabel respondsToSelector:@selector(setAdjustsLetterSpacingToFitWidth:)])
            self.textLabel.adjustsLetterSpacingToFitWidth = YES;
        self.textLabel.minimumScaleFactor = 0.5f;
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
        topLine.backgroundColor = [UIColor colorWithRed:(16.0f/255.0f) green:(16.0f/255.0f) blue:(16.0f/255.0f) alpha:1.0f];
        [self.textLabel.superview addSubview:topLine];

        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 50.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
        bottomLine.backgroundColor = [UIColor colorWithRed:(23.0f/255.0f) green:(23.0f/255.0f) blue:(23.0f/255.0f) alpha:1.0f];
        [self.textLabel.superview addSubview:bottomLine];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.frame = CGRectMake(50.0f, 0.0f, 200.0f, 50.0f);
    self.titleImageView.frame = CGRectMake(0.0f, 0.0f, 260.0f, 50.0f);
    self.imageView.frame = CGRectMake(0.0f, 0.0f, 50.0f, 50.0f);
}

@end
