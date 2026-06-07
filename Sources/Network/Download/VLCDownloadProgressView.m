/*****************************************************************************
 * VLCDownloadProgressView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Jean-Romain Bouquet <cabbry # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDownloadProgressView.h"
#import "VLC-Swift.h"

@interface VLCDownloadProgressView ()
{
    UILabel *_titleLabel;
    UILabel *_percentLabel;
    UILabel *_subtitleLabel;
    UIProgressView *_progressView;
    UIActivityIndicatorView *_spinner;

    NSLayoutConstraint *_leadingConstraint;
    NSLayoutConstraint *_trailingConstraint;
    NSLayoutConstraint *_topConstraint;
    NSLayoutConstraint *_bottomConstraint;
}
@end

@implementation VLCDownloadProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    self.translatesAutoresizingMaskIntoConstraints = NO;
    _contentInsets = UIEdgeInsetsMake(8, 16, 8, 16);
    _subtitleNumberOfLines = 1;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self addSubview:_titleLabel];

    _percentLabel = [[UILabel alloc] init];
    _percentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _percentLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
    _percentLabel.textAlignment = NSTextAlignmentRight;
    [_percentLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [_percentLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self addSubview:_percentLabel];

    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _subtitleLabel.font = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightRegular];
    _subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _subtitleLabel.numberOfLines = _subtitleNumberOfLines;
    [self addSubview:_subtitleLabel];

#if TARGET_OS_VISION
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
#else
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    } else {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    }
#endif
    _spinner.translatesAutoresizingMaskIntoConstraints = NO;
    _spinner.hidesWhenStopped = YES;
    [self addSubview:_spinner];

    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_progressView];

    _leadingConstraint = [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:_contentInsets.left];
    _trailingConstraint = [_percentLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-_contentInsets.right];
    _topConstraint = [_titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:_contentInsets.top];
    _bottomConstraint = [_subtitleLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-_contentInsets.bottom];

    [NSLayoutConstraint activateConstraints:@[
        _leadingConstraint,
        _topConstraint,
        [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_percentLabel.leadingAnchor constant:-8],

        _trailingConstraint,
        [_percentLabel.centerYAnchor constraintEqualToAnchor:_titleLabel.centerYAnchor],

        [_spinner.centerXAnchor constraintEqualToAnchor:_percentLabel.centerXAnchor],
        [_spinner.centerYAnchor constraintEqualToAnchor:_percentLabel.centerYAnchor],

        [_progressView.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
        [_progressView.trailingAnchor constraintEqualToAnchor:_percentLabel.trailingAnchor],
        [_progressView.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:6],

        [_subtitleLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
        [_subtitleLabel.trailingAnchor constraintEqualToAnchor:_percentLabel.trailingAnchor],
        [_subtitleLabel.topAnchor constraintEqualToAnchor:_progressView.bottomAnchor constant:4],
        _bottomConstraint,
    ]];

    [self applyTheme];

    return self;
}

#pragma mark - Public API

- (void)setTitle:(NSString *)title
{
    _title = title;
    _titleLabel.text = title;
}

- (void)setSubtitle:(NSString *)subtitle
{
    _subtitle = subtitle;
    _subtitleLabel.text = subtitle;
    _subtitleLabel.hidden = (subtitle.length == 0);
}

- (void)setProgress:(CGFloat)progress
{
    // Animate only when moving forward. When progress drops (e.g. a queued
    // download starts and resets it), jump without animation so the bar does
    // not visibly run backwards.
    BOOL animated = progress >= _progress;
    _progress = progress;
    [_progressView setProgress:progress animated:animated];
    _percentLabel.text = [NSString stringWithFormat:@"%.0f%%", progress * 100.0];
}

- (void)setProgressKnown:(BOOL)progressKnown
{
    _progressKnown = progressKnown;
    _progressView.hidden = !progressKnown;
    _percentLabel.hidden = !progressKnown;
    if (progressKnown) {
        [_spinner stopAnimating];
    } else {
        [_spinner startAnimating];
    }
}

- (void)setSubtitleNumberOfLines:(NSInteger)subtitleNumberOfLines
{
    _subtitleNumberOfLines = subtitleNumberOfLines;
    _subtitleLabel.numberOfLines = subtitleNumberOfLines;
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets
{
    _contentInsets = contentInsets;
    _leadingConstraint.constant = contentInsets.left;
    _trailingConstraint.constant = -contentInsets.right;
    _topConstraint.constant = contentInsets.top;
    _bottomConstraint.constant = -contentInsets.bottom;
    [self setNeedsLayout];
}

- (void)setTitleFontSize:(CGFloat)titleSize subtitleFontSize:(CGFloat)subtitleSize
{
    _titleLabel.font = [UIFont systemFontOfSize:titleSize weight:UIFontWeightMedium];
    _percentLabel.font = [UIFont monospacedDigitSystemFontOfSize:subtitleSize weight:UIFontWeightRegular];
    _subtitleLabel.font = [UIFont monospacedDigitSystemFontOfSize:subtitleSize weight:UIFontWeightRegular];
}

- (void)setTitleFont:(UIFont *)titleFont subtitleFont:(UIFont *)subtitleFont
{
    _titleLabel.font = titleFont;
    _percentLabel.font = subtitleFont;
    _subtitleLabel.font = subtitleFont;
}

- (void)applyTheme
{
    ColorPalette *colors = PresentationTheme.current.colors;
    _titleLabel.textColor = colors.cellTextColor;
    _percentLabel.textColor = colors.cellDetailTextColor;
    _subtitleLabel.textColor = colors.cellDetailTextColor;
    _spinner.color = colors.cellDetailTextColor;
    _progressView.progressTintColor = colors.orangeUI;
}

@end
