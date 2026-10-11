/*****************************************************************************
 * VLCArtworkImageView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCArtworkImageView.h"
#import "VLCPlaceholderArtworkView.h"

@implementation VLCArtworkImageView
{
    VLCPlaceholderArtworkView *_placeholderView;
}

- (void)setImage:(UIImage *)image placeholderName:(NSString *)placeholderName
{
    _placeholderName = [placeholderName copy];
    self.image = image;
}

- (void)setImage:(UIImage *)image
{
    [super setImage:image];
    [self updatePlaceholderView];
}

- (void)updatePlaceholderView
{
    if (self.image || !_placeholderName) {
        _placeholderView.hidden = YES;
        return;
    }

    if (!_placeholderView) {
        _placeholderView = [[VLCPlaceholderArtworkView alloc] init];
        _placeholderView.translatesAutoresizingMaskIntoConstraints = NO;

#if TARGET_OS_TV
        UIView *containerView = self.overlayContentView;
#else
        UIView *containerView = self;
#endif
        [containerView insertSubview:_placeholderView atIndex:0];

        [NSLayoutConstraint activateConstraints:@[
            [_placeholderView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
            [_placeholderView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
            [_placeholderView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
            [_placeholderView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor]
        ]];
    }

    _placeholderView.name = _placeholderName;
    _placeholderView.hidden = NO;
}

@end
