/*****************************************************************************
 * VLCRadioErrorView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRadioErrorView.h"

#import "VLC-Swift.h"

@implementation VLCRadioErrorView

- (instancetype)initWithMessage:(NSString *)message
                    retryTarget:(id)target
                    retryAction:(SEL)action
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        ColorPalette *themeColors = PresentationTheme.current.colors;

        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = themeColors.cellDetailTextColor;
        label.font = [UIFont systemFontOfSize:16.0];
        label.text = message;
        [self addSubview:label];

        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.tintColor = themeColors.orangeUI;
        button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
        [button setTitle:NSLocalizedString(@"BUTTON_RETRY", nil) forState:UIControlStateNormal];
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];

        [NSLayoutConstraint activateConstraints:@[
            [label.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
            [label.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor],
            [label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [button.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:16.0],
            [button.centerXAnchor constraintEqualToAnchor:self.centerXAnchor]
        ]];
    }
    return self;
}

@end
