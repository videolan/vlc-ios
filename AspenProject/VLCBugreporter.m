//
//  VLCBugreporter.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 21.07.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCBugreporter.h"

@implementation VLCBugreporter

static VLCBugreporter *_sharedInstance = nil;

+ (VLCBugreporter *)sharedInstance
{
    return _sharedInstance ? _sharedInstance : [[self alloc] init];
}

#pragma mark -
#pragma mark Initialization

- (id)init
{
    if (_sharedInstance) {
        self = nil;
        return _sharedInstance;
    } else
        _sharedInstance = [super init];

    return _sharedInstance;
}

- (void)handleBugreportRequest
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"BUG_REPORT_TITLE", @"")
                          message:NSLocalizedString(@"BUG_REPORT_MESSAGE", @"") delegate:self
                          cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"")
                          otherButtonTitles:NSLocalizedString(@"BUG_REPORT_BUTTON", @""), nil];;
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
