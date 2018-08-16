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

#import "VLC-Swift.h"

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
    NSArray<VLCAlertButton *> *buttonsAction = @[[[VLCAlertButton alloc] initWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                                                 style: UIAlertActionStyleCancel
                                                                                action:nil],
                                                 [[VLCAlertButton alloc] initWithTitle:NSLocalizedString(@"BUG_REPORT_BUTTON", nil)
                                                                                action: ^(UIAlertAction *action) {
                                                                                    NSURL *url = [NSURL URLWithString:@"https://trac.videolan.org/vlc/newticket"];
                                                                                    [[UIApplication sharedApplication] openURL:url];
                                                                                }]
                                                 
                                                 ];
    [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"BUG_REPORT_TITLE", nil)
                                         errorMessage:NSLocalizedString(@"BUG_REPORT_MESSAGE", nil)
                                       viewController:[UIApplication sharedApplication].keyWindow.rootViewController
                                        buttonsAction:buttonsAction];
}
@end
