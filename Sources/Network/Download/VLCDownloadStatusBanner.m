/*****************************************************************************
 * VLCDownloadStatusBanner.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Jean-Romain Bouquet <cabbry # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDownloadStatusBanner.h"
#import "VLCDownloadProgressView.h"
#import "VLC-Swift.h"

@interface VLCDownloadStatusBanner ()
{
    VLCDownloadProgressView *_progressView;
}
@end

@implementation VLCDownloadStatusBanner

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    self.layer.masksToBounds = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;

    _progressView = [[VLCDownloadProgressView alloc] init];
    _progressView.subtitleNumberOfLines = 1;
#if TARGET_OS_TV
    self.layer.cornerRadius = 18.0;
    _progressView.contentInsets = UIEdgeInsetsMake(20, 32, 20, 32);
    [_progressView setTitleFont:[UIFont systemFontOfSize:28.0 weight:UIFontWeightSemibold]
                   subtitleFont:[UIFont systemFontOfSize:22.0 weight:UIFontWeightRegular]];
#else
    self.layer.cornerRadius = 10.0;
    _progressView.contentInsets = UIEdgeInsetsMake(8, 12, 8, 12);
    [_progressView setTitleFontSize:13 subtitleFontSize:11];
#endif
    [self addSubview:_progressView];

    [NSLayoutConstraint activateConstraints:@[
        [_progressView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_progressView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_progressView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_progressView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self addGestureRecognizer:tap];
    self.userInteractionEnabled = YES;
    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;

    [self applyTheme];

    return self;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    _progressView.title = title;
    self.accessibilityLabel = title;
}

- (void)setBytesText:(NSString *)bytesText
{
    _bytesText = bytesText;
    _progressView.subtitle = bytesText;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    _progressView.progress = progress;
}

- (void)setProgressKnown:(BOOL)progressKnown
{
    _progressKnown = progressKnown;
    _progressView.progressKnown = progressKnown;
}

- (void)applyTheme
{
    ColorPalette *colors = PresentationTheme.current.colors;
    self.backgroundColor = [colors.background colorWithAlphaComponent:0.96];
    self.layer.borderColor = [colors.mediaCategorySeparatorColor CGColor];
    CGFloat scale = self.traitCollection.displayScale;
    self.layer.borderWidth = 1.0 / (scale > 0 ? scale : 2.0);
    [_progressView applyTheme];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if (self.traitCollection.displayScale != previousTraitCollection.displayScale) {
        CGFloat scale = self.traitCollection.displayScale;
        self.layer.borderWidth = 1.0 / (scale > 0 ? scale : 2.0);
    }
}

- (void)handleTap
{
    if (self.onTap) {
        self.onTap();
    }
}

@end
