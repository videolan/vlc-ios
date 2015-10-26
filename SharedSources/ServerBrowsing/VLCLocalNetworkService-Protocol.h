/*****************************************************************************
 * VLCLocalNetworkService-Protocol.h
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
#import "VLCNetworkServerBrowser-Protocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol VLCNetworkServerLoginInformation <NSObject>
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *address;
@property (nonatomic) NSNumber *port;
@property (nonatomic) NSString *protocolIdentifier;
@end

@protocol VLCLocalNetworkService <NSObject>

@required
@property (nonatomic, readonly, nullable) UIImage *icon;
@property (nonatomic, readonly) NSString *title;

@optional
- (nullable id<VLCNetworkServerBrowser>)serverBrowser;
- (NSURL *)directPlaybackURL;
- (nullable id<VLCNetworkServerLoginInformation>)loginInformation;

@end

NS_ASSUME_NONNULL_END
