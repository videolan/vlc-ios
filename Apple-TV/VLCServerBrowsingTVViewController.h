/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

#import "VLCRemoteBrowsingCollectionViewController.h"
#import "VLCNetworkServerBrowser-Protocol.h"

@interface VLCServerBrowsingTVViewController : VLCRemoteBrowsingCollectionViewController <VLCNetworkServerBrowserDelegate>

@property (nonatomic) BOOL downloadArtwork;

- (instancetype)initWithServerBrowser:(id<VLCNetworkServerBrowser>)serverBrowser;

@end
