/*****************************************************************************
 * VLCLocalNetworkServiceBrowser-Protocol.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkService-Protocol.h"

@protocol VLCLocalNetworkServiceBrowserDelegate;
@protocol VLCLocalNetworkServiceBrowser <NSObject>

@property (nonatomic, weak) id <VLCLocalNetworkServiceBrowserDelegate> delegate;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSUInteger numberOfItems;
- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index;

- (void)startDiscovery;
- (void)stopDiscovery;
@end

@protocol VLCLocalNetworkServiceBrowserDelegate <NSObject>
- (void) localNetworkServiceBrowserDidUpdateServices:(id<VLCLocalNetworkServiceBrowser>)serviceBrowser;
@end
