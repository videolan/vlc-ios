/*****************************************************************************
 * VLCLocalServerDiscoveryController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "VLCLocalNetworkService-Protocol.h"

@protocol VLCLocalServerDiscoveryControllerDelegate <NSObject>
- (void)discoveryFoundSomethingNew;
@end

@interface VLCLocalServerDiscoveryController : NSObject
@property (nonatomic, readwrite, weak) id delegate;

// array of classes conforming to VLCLocalNetworkServiceBrowser
- (instancetype)initWithServiceBrowserClasses:(NSArray<Class> *)serviceBrowserClasses;

- (NSUInteger)numberOfSections;
- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;
- (BOOL)foundAnythingAtAll;

- (id<VLCLocalNetworkService>)networkServiceForIndexPath:(NSIndexPath *)indexPath;

- (void)stopDiscovery;
- (BOOL)refreshDiscoveredData;
- (void)startDiscovery;

@end
