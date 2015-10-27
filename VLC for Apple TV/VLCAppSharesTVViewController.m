/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppSharesTVViewController.h"
#import "VLCLocalNetworkServiceBrowserHTTP.h"

@interface VLCAppSharesTVViewController ()

@end

@implementation VLCAppSharesTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *classes = @[[VLCLocalNetworkServiceBrowserHTTP class]];
    self.discoveryController = [[VLCLocalServerDiscoveryController alloc] initWithServiceBrowserClasses:classes];
    self.discoveryController.delegate = self;
}

- (NSString *)title {
    return NSLocalizedString(@"VLC_SHARES", nil);
}

@end
