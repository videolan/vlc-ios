//
//  VLCGoogleDriveTableViewCell.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 24.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCGoogleDriveTableViewCell.h"

@implementation VLCGoogleDriveTableViewCell

+ (VLCGoogleDriveTableViewCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCGoogleDriveTableViewCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCGoogleDriveTableViewCell class]], @"meh meh");
    VLCGoogleDriveTableViewCell *cell = (VLCGoogleDriveTableViewCell *)[nibContentArray lastObject];

    return cell;
}

- (void)_updatedDisplayedInformation
{
    [self setNeedsDisplay];
}

+ (CGFloat)heightOfCell
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return 80.;

    return 48.;
}

@end
