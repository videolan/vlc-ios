/*****************************************************************************
 * VLCWiFiUploadTableViewCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCWiFiUploadTableViewCell.h"

@implementation VLCWiFiUploadTableViewCell

+ (VLCWiFiUploadTableViewCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCWiFiUploadTableViewCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCWiFiUploadTableViewCell class]], @"meh meh");
    VLCWiFiUploadTableViewCell *cell = (VLCWiFiUploadTableViewCell *)[nibContentArray lastObject];

    return cell;
}

- (void)awakeFromNib
{
    self.titleLabel.text = NSLocalizedString(@"HTTP_UPLOAD", @"");
    self.titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.titleLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.25f];
    self.titleLabel.textColor = [UIColor whiteColor];

    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    self.titleLabel.superview.backgroundColor = [UIColor colorWithRed:(43.0f/255.0f) green:(43.0f/255.0f) blue:(43.0f/255.0f) alpha:1.0f];

    self.uploadAddressLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.uploadAddressLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.25f];
    self.uploadAddressLabel.textColor = [UIColor whiteColor];

    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
    topLine.backgroundColor = [UIColor colorWithRed:(16.0f/255.0f) green:(16.0f/255.0f) blue:(16.0f/255.0f) alpha:1.0f];
    [self.titleLabel.superview addSubview:topLine];

    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 50.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
    bottomLine.backgroundColor = [UIColor colorWithRed:(23.0f/255.0f) green:(23.0f/255.0f) blue:(23.0f/255.0f) alpha:1.0f];
    [self.titleLabel.superview addSubview:bottomLine];
}

+ (CGFloat)heightOfCell
{
    return 50.;
}

@end
