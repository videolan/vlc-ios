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

NS_ASSUME_NONNULL_BEGIN
@interface VLCServerBrowsingTVViewController : VLCRemoteBrowsingCollectionViewController <VLCNetworkServerBrowserDelegate>

@property (nonatomic) BOOL downloadArtwork;
@property (nonatomic, readonly) id<VLCNetworkServerBrowser>serverBrowser;
@property (nonatomic, null_resettable) Class subdirectoryBrowserClass; // if not set returns [self class], must be subclass of VLCServerBrowsingTVViewController

- (instancetype)initWithServerBrowser:(id<VLCNetworkServerBrowser>)serverBrowser;

@end
NS_ASSUME_NONNULL_END
