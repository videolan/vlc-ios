/*****************************************************************************
 * VLCNetworkServerBrowserViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkListViewController.h"
#import "VLCNetworkServerBrowser-Protocol.h"

@class MediaLibraryService;

@interface VLCNetworkServerBrowserViewController : VLCNetworkListViewController

- (instancetype)initWithServerBrowser:(id<VLCNetworkServerBrowser>)browser
                  medialibraryService:(MediaLibraryService *)medialibraryService;
@end
