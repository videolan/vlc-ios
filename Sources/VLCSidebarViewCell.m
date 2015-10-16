/*****************************************************************************
 * VLCSidebarViewCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
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

        self.textLabel.font = [UIFont fontWithName:@"Helvetica" size:([UIFont systemFontSize] * 1.2f)];
        self.textLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
        self.textLabel.shadowColor = [UIColor VLCDarkTextShadowColor];
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.minimumScaleFactor = 0.5f;
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
        topLine.backgroundColor = [UIColor colorWithRed:(16.0f/255.0f) green:(16.0f/255.0f) blue:(16.0f/255.0f) alpha:1.0f];
        [self.textLabel.superview addSubview:topLine];

        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 50.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
        bottomLine.backgroundColor = [UIColor colorWithRed:(23.0f/255.0f) green:(23.0f/255.0f) blue:(23.0f/255.0f) alpha:1.0f];
        [self.textLabel.superview addSubview:bottomLine];

        UILabel *textLabel = self.textLabel;
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        UIImageView *imageView = self.imageView;

        NSDictionary *dict = NSDictionaryOfVariableBindings(textLabel,imageView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(50)]-==8-[textLabel]|" options:0 metrics:0 views:dict]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView(50)]|" options:0 metrics:0 views:dict]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textLabel]|" options:0 metrics:0 views:dict]];
    }
    return self;
}

@end
