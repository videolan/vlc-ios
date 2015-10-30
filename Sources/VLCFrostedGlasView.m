/*****************************************************************************
 * VLCFrostedGlasView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan # org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFrostedGlasView.h"

@interface VLCFrostedGlasView ()

#if TARGET_OS_IOS
@property (nonatomic) UIToolbar *toolbar;
@property (nonatomic) UIImageView *imageview;
#else
@property (nonatomic)  UIVisualEffectView *effectView;
#endif

@end

@implementation VLCFrostedGlasView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
        [self setupView];

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
        [self setupView];

    return self;
}

- (void)setupView
{
    [self setClipsToBounds:YES];

#if TARGET_OS_IOS
    if (![self toolbar]) {
        [self setToolbar:[[UIToolbar alloc] initWithFrame:[self bounds]]];
        [self.layer insertSublayer:[self.toolbar layer] atIndex:0];
        [self.toolbar setBarStyle:UIBarStyleBlack];
    }
#else
    _effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    _effectView.frame = self.bounds;
    _effectView.clipsToBounds = YES;
    _effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self insertSubview:_effectView atIndex:0];
#endif
}

#if TARGET_OS_IOS
- (void)layoutSubviews {
    [super layoutSubviews];
    [self.toolbar setFrame:[self bounds]];
}
#endif

@end
