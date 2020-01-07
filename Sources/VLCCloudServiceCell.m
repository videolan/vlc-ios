/*****************************************************************************
 * VLCCloudServiceCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCloudServiceCell.h"
#import "VLC-Swift.h"

@implementation VLCCloudServiceCell

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange)
                                                 name:kVLCThemeDidChangeNotification object:nil];
    [self themeDidChange];
    [super awakeFromNib];
}

- (void)themeDidChange
{
    self.backgroundColor = PresentationTheme.current.colors.background;
    self.cloudTitle.textColor = PresentationTheme.current.colors.cellTextColor;
    self.cloudInformation.textColor = PresentationTheme.current.colors.cellDetailTextColor;
    self.lonesomeCloudTitle.textColor = PresentationTheme.current.colors.cellTextColor;
}

@end
