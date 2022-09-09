/*****************************************************************************
 * VLCLocalNetworkServiceBrowserNetService.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "VLCLocalNetworkServiceBrowser-Protocol.h"
#import "VLCLocalNetworkServiceNetService.h"

@interface VLCLocalNetworkServiceBrowserNetService : NSObject <VLCLocalNetworkServiceBrowser>
- (instancetype)initWithName:(NSString *)name serviceType:(NSString *)serviceType domain:(NSString *)domain NS_DESIGNATED_INITIALIZER;
@property (nonatomic, weak) id<VLCLocalNetworkServiceBrowserDelegate> delegate;
@end

@interface VLCLocalNetworkServiceBrowserNetService() <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@property (nonatomic, readonly) NSNetServiceBrowser *netServiceBrowser;
@property (nonatomic, readonly) NSString *serviceType;
@property (nonatomic, readonly) NSString *domain;

@property (nonatomic, readonly, getter=isDiscovering) BOOL discovering;

@property (nonatomic, readonly) NSMutableArray<NSNetService*> *rawNetServices;
@property (nonatomic, readonly) NSMutableArray<VLCLocalNetworkServiceNetService*> *resolvedLocalNetworkServices;

// adds netservice and informs delegate
- (void)addResolvedLocalNetworkService:(VLCLocalNetworkServiceNetService *)localNetworkService;

// override in subclasses for different configurations
- (VLCLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService;
- (void)netServiceDidResolveAddress:(NSNetService *)sender;
@end
