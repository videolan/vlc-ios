/*****************************************************************************
 * VLCLocalNetworkService.h
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

NS_ASSUME_NONNULL_BEGIN
@interface VLCNetworkServerLoginInformation : NSObject
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *address;
@property (nonatomic) NSNumber *port;
@property (nonatomic) NSString *protocolIdentifier;
@end


#pragma mark - item

@interface VLCLocalNetworkServiceItem : NSObject <VLCLocalNetworkService>
- (instancetype)initWithTile:(NSString *)title icon:(nullable UIImage *)icon;
@end

@interface VLCLocalNetworkServiceItemLogin : VLCLocalNetworkServiceItem
- (instancetype)init;
@end


#pragma mark - NetService based services
@interface VLCLocalNetworkServiceNetService : NSObject <VLCLocalNetworkService>
@property (nonatomic, readonly, strong) NSNetService *netService;
- (instancetype)initWithNetService:(NSNetService *)service;
@end

extern NSString *const VLCNetworkServerProtocolIdentifierPlex;
@interface VLCLocalNetworkServicePlex : VLCLocalNetworkServiceNetService
@end

extern NSString *const VLCNetworkServerProtocolIdentifierFTP;
@interface VLCLocalNetworkServiceFTP : VLCLocalNetworkServiceNetService

@end
@interface VLCLocalNetworkServiceHTTP : VLCLocalNetworkServiceNetService

@end

#pragma mark - VLCMedia based services
@interface VLCLocalNetworkServiceVLCMedia : NSObject <VLCLocalNetworkService>
- (instancetype)initWithMediaItem:(VLCMedia *)mediaItem;
@end

extern NSString *const VLCNetworkServerProtocolIdentifierSMB;
@interface VLCLocalNetworkServiceDSM: VLCLocalNetworkServiceVLCMedia

@end

@interface VLCLocalNetworkServiceSAP: VLCLocalNetworkServiceVLCMedia

@end

#pragma mark - UPnP
@class BasicUPnPDevice;
@interface VLCLocalNetworkServiceUPnP : NSObject <VLCLocalNetworkService>
- (instancetype)initWithUPnPDevice:(BasicUPnPDevice *)device;
@end

NS_ASSUME_NONNULL_END
