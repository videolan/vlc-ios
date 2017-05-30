/*****************************************************************************
 * VLCProgressView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCProgressView.h"

@implementation VLCProgressView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressLabel = [[UILabel alloc] init];
    self.progressLabel.textColor = [UIColor whiteColor];
    self.progressLabel.font = [UIFont systemFontOfSize:11.];

    self.progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:_progressBar];
    [self addSubview:_progressLabel];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_progressLabel attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_progressBar(200)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_progressBar)]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressBar attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_progressBar]-[_progressLabel(8)]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_progressBar, _progressLabel)]];
}

- (void)updateTime:(NSString *)time
{
    [self.progressLabel setText:[NSString stringWithFormat:NSLocalizedString(@"REMAINING_TIME", nil), time]];
    CGSize size = [self.progressLabel.text sizeWithAttributes:self.progressLabel.font.fontDescriptor.fontAttributes];
    [self.progressLabel setFrame:CGRectMake(self.progressLabel.frame.origin.x, self.progressLabel.frame.origin.y, size.width, size.height)];
}

@end
