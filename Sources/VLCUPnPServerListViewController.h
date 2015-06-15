/*****************************************************************************
 * VLCUPnPServerListViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkListViewController.h"

@class MediaServer1Device;

@interface VLCUPnPServerListViewController : VLCLocalNetworkListViewController

- (id)initWithUPNPDevice:(MediaServer1Device *)device header:(NSString *)header andRootID:(NSString *)rootID;

@end
