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

#import "VLCLocalNetworkTVViewController.h"

#import "VLCLocalNetworkServiceBrowserManualConnect.h"
#import "VLCLocalNetworkServiceBrowserPlex.h"
//#import "VLCLocalNetworkServiceBrowserFTP.h"
#import "VLCLocalNetworkServiceBrowserUPnP.h"
#import "VLCLocalNetworkServiceBrowserSAP.h"
#import "VLCLocalNetworkServiceBrowserDSM.h"

@interface VLCLocalNetworkTVViewController ()

@end

@implementation VLCLocalNetworkTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *classes = @[
                         [VLCLocalNetworkServiceBrowserManualConnect class],
                         [VLCLocalNetworkServiceBrowserUPnP class],
                         [VLCLocalNetworkServiceBrowserPlex class],
//                         [VLCLocalNetworkServiceBrowserFTP class],
                         [VLCLocalNetworkServiceBrowserSAP class],
                         [VLCLocalNetworkServiceBrowserDSM class],
                         ];
    self.discoveryController = [[VLCLocalServerDiscoveryController alloc] initWithServiceBrowserClasses:classes];
    self.discoveryController.delegate = self;
}
- (NSString *)title {
    return NSLocalizedString(@"LOCAL_NETWORK", nil);
}

@end
