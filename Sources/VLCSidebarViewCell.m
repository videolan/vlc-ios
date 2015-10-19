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
        self.selectedBackgroundView = [[UIView alloc] init];
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;

        self.imageView.contentMode = UIViewContentModeCenter;

        self.textLabel.font = [UIFont systemFontOfSize:([UIFont systemFontSize] * 1.2f)];
        self.textLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
        self.textLabel.shadowColor = [UIColor VLCDarkTextShadowColor];
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.minimumScaleFactor = 0.5f;
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        UILabel *textLabel = self.textLabel;
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        UIImageView *imageView = self.imageView;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;

        NSDictionary *dict = NSDictionaryOfVariableBindings(textLabel,imageView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(50)]-==8-[textLabel]|" options:0 metrics:0 views:dict]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView(50)]|" options:0 metrics:0 views:dict]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textLabel]|" options:0 metrics:0 views:dict]];
    }
    return self;
}

@end
