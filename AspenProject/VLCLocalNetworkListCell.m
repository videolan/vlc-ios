//
//  VLCLocalNetworkListCell.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 10.08.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCLocalNetworkListCell.h"

@implementation VLCLocalNetworkListCell

+ (VLCLocalNetworkListCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCLocalNetworkListCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCLocalNetworkListCell class]], @"meh meh");
    VLCLocalNetworkListCell *cell = (VLCLocalNetworkListCell *)[nibContentArray lastObject];

    return cell;
}

- (void)awakeFromNib
{
    self.titleLabel.text = @"";
    self.subtitleLabel.text = @"";
}

- (void)setTitle:(NSString *)title
{
    BOOL isDir = self.isDirectory;
    if (isDir)
        self.folderTitleLabel.text = title;
    else
        self.titleLabel.text = title;

    self.titleLabel.hidden = self.subtitleLabel.hidden = isDir;
    self.folderTitleLabel.hidden = !isDir;
}

- (void)setSubtitle:(NSString *)subtitle
{
    self.subtitleLabel.text = subtitle;
}

+ (CGFloat)heightOfCell
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return 80.;

    return 48.;
}

@end
