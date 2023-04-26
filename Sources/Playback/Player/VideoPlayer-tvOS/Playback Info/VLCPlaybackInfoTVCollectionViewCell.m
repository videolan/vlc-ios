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

#import "VLCPlaybackInfoTVCollectionViewCell.h"


@interface VLCPlaybackInfoTVCollectionViewCell()

@property (strong, nonatomic) UIColor *textColor;

@end

@implementation VLCPlaybackInfoTVCollectionViewCell

+ (NSString *)identifier
{
    return @"VLCPlaybackInfoTVCollectionViewCell";
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self prepareForReuse];
}

- (BOOL)selectionMarkerVisible
{
    return !self.selectionMarkerView.hidden;
}

- (void)setSelectionMarkerVisible:(BOOL)selectionMarkerVisible
{
    self.selectionMarkerView.hidden = !selectionMarkerVisible;

    UIFont *titleFont;
    if (selectionMarkerVisible) {
        titleFont = [UIFont boldSystemFontOfSize:29.];
    } else {
        titleFont = [UIFont systemFontOfSize:29.];
    }

    self.titleLabel.font = titleFont;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.selectionMarkerVisible = NO;
    self.titleLabel.text = nil;
    if ([UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        self.textColor = [UIColor VLCDarkFadedTextColor];
    } else {
        self.textColor = [UIColor VLCDarkTextColor];
    }
    self.selectionMarkerView.textColor = self.textColor;
    self.titleLabel.textColor = self.textColor;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    [coordinator addCoordinatedAnimations:^{
        self.titleLabel.textColor = self.focused ? [UIColor whiteColor] : self.textColor;
    } completion:nil];
}

@end
