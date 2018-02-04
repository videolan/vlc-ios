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

@implementation VLCPlaybackInfoTVCollectionViewCell {
    UIColor *textColor;
}

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
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.selectionMarkerVisible = NO;
    self.titleLabel.text = nil;
    if ([UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        textColor = [UIColor VLCDarkFadedTextColor];
    } else {
        textColor = [UIColor VLCDarkTextColor];
    }
    self.selectionMarkerView.textColor = textColor;
    self.titleLabel.textColor = textColor;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    [coordinator addCoordinatedAnimations:^{
        self.titleLabel.textColor = self.focused ? [UIColor whiteColor] : textColor;
    } completion:nil];
}

@end
