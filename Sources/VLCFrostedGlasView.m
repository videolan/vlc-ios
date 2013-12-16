/*****************************************************************************
 * VLCFrostedGlasView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFrostedGlasView.h"

@interface VLCFrostedGlasView ()

@property (nonatomic) UIToolbar *toolbar;
@property (nonatomic) UIImageView *imageview;

@end

@implementation VLCFrostedGlasView


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setClipsToBounds:YES];
        if (SYSTEM_RUNS_IOS7_OR_LATER) {
            if (![self toolbar]) {
                [self setToolbar:[[UIToolbar alloc] initWithFrame:[self bounds]]];
                [self.layer insertSublayer:[self.toolbar layer] atIndex:0];
                [self.toolbar setBarStyle:UIBarStyleBlack];
            }
        } else {
            if(![self imageview]) {
                [self setImageview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"playbackControllerBg"]]];
                [self insertSubview:self.imageview atIndex:0];
            }
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
     if (SYSTEM_RUNS_IOS7_OR_LATER) {
         [self.toolbar setFrame:[self bounds]];
     } else {
         [self.imageview setFrame:[self bounds]];
     }
}

@end