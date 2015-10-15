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
#import "UPnPManager.h"

#import "VLCLocalNetworkService.h"

@protocol VLCLocalServerDiscoveryControllerDelegate <NSObject>

@required
- (void)discoveryFoundSomethingNew;

@end

@interface VLCLocalServerDiscoveryController : NSObject

@property (nonatomic, readwrite, weak) id delegate;
@property (nonatomic, readonly) NSArray *sectionHeaderTexts;

- (id<VLCLocalNetworkService>)networkServiceForIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfItemsInSection:(NSInteger)section;

- (void)stopDiscovery;
- (BOOL)refreshDiscoveredData;
- (void)startDiscovery;

@end
