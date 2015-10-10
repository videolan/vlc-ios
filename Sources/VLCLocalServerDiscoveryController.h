/*****************************************************************************
 * VLCLocalServerDiscoveryController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "UPnPManager.h"

@protocol VLCLocalServerDiscoveryControllerDelegate <NSObject>

@required
- (void)discoveryFoundSomethingNew;

@end

@interface VLCLocalServerDiscoveryController : NSObject

@property (nonatomic, readwrite, weak) id delegate;
@property (nonatomic, readonly) NSArray *sectionHeaderTexts;

- (NSInteger)numberOfItemsInSection:(NSInteger)section;

- (NSString *)titleForIndexPath:(NSIndexPath *)indexPath;
- (UIImage *)iconForIndexPath:(NSIndexPath *)indexPath;

- (BasicUPnPDevice *)upnpDeviceForIndexPath:(NSIndexPath *)indexPath;
- (NSDictionary *)plexServiceDescriptionForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)ftpHostnameForIndexPath:(NSIndexPath *)indexPath;
- (NSDictionary *)httpServiceDescriptionForIndexPath:(NSIndexPath *)indexPath;
- (VLCMedia *)dsmDiscoveryForIndexPath:(NSIndexPath *)indexPath;
- (VLCMedia *)sapDiscoveryForIndexPath:(NSIndexPath *)indexPath;

- (void)stopDiscovery;
- (BOOL)refreshDiscoveredData;
- (void)startDiscovery;

@end
