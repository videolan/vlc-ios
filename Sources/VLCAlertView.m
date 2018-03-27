/*****************************************************************************
 * VLCStatusLabel.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@interface VLCAlertView () <UIAlertViewDelegate>

@end

// via http://stackoverflow.com/a/10082549/928646

@implementation VLCAlertView

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles {

    self = [self initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];

    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        for (NSString *buttonTitle in otherButtonTitles) {
            [self addButtonWithTitle:buttonTitle];
        }
    }
    return self;
}

- (void)appWillResignActive:(NSNotification *)aNotification
{
    [self dismissWithClickedButtonIndex:self.cancelButtonIndex animated:NO];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (self.completion) {
        self.completion(buttonIndex == self.cancelButtonIndex, buttonIndex);
        self.completion = nil;
        self.delegate = nil;
    }
}

- (void)show
{
    if (self.completion)
        self.delegate = self;

    [super show];
}

@end
