/*****************************************************************************
 * VLCDiscoveryListViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkListViewController.h"

@interface VLCDiscoveryListViewController : VLCNetworkListViewController

- (instancetype)initWithMedia:(VLCMedia*)media;

@end
