/*****************************************************************************
 * VLCActiveDownloadCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Jean-Romain Bouquet <cabbry # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCActiveDownloadCell.h"
#import "VLCDownloadProgressView.h"

@interface VLCActiveDownloadCell ()
{
    VLCDownloadProgressView *_progressView;
}
@end

@implementation VLCActiveDownloadCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }

    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _progressView = [[VLCDownloadProgressView alloc] init];
    _progressView.contentInsets = UIEdgeInsetsMake(8, 16, 8, 16);
    _progressView.subtitleNumberOfLines = 2;
    [_progressView setTitleFontSize:14 subtitleFontSize:12];
    [self.contentView addSubview:_progressView];

    [NSLayoutConstraint activateConstraints:@[
        [_progressView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [_progressView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [_progressView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [_progressView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];

    return self;
}

- (void)setName:(NSString *)name
{
    _name = name;
    _progressView.title = name;
}

- (void)setStatsText:(NSString *)statsText
{
    _statsText = statsText;
    _progressView.subtitle = statsText;
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
    [_progressView applyTheme];
}

@end
