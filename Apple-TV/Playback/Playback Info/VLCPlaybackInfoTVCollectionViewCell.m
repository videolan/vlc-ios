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
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.selectionMarkerVisible = NO;
    self.titleLabel.text = nil;
    self.selectionMarkerView.textColor = [UIColor darkGrayColor];
    self.titleLabel.textColor = [UIColor darkGrayColor];
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    [coordinator addCoordinatedAnimations:^{
        self.titleLabel.textColor = self.focused ? [UIColor whiteColor] : [UIColor darkGrayColor];
    } completion:nil];
}

@end
