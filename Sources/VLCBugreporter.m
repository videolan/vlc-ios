/*****************************************************************************
 * VLCBugreporter.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCBugreporter.h"

@implementation VLCBugreporter

#pragma mark - Initialization

+ (VLCBugreporter *)sharedInstance
{
    static dispatch_once_t onceToken;
    static VLCBugreporter *_sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [VLCBugreporter new];
    });

    return _sharedInstance;
}

#pragma mark -

- (void)handleBugreportRequest
{
    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"BUG_REPORT_TITLE", nil)
                                                      message:NSLocalizedString(@"BUG_REPORT_MESSAGE", nil) delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                            otherButtonTitles:NSLocalizedString(@"BUG_REPORT_BUTTON", nil), nil];;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSURL *url = [NSURL URLWithString:@"https://trac.videolan.org/vlc/newticket"];
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
