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

typedef NS_ENUM(NSUInteger, VLCNetworkServerLoginInformationFieldType) {
    VLCNetworkServerLoginInformationFieldTypeText,
    VLCNetworkServerLoginInformationFieldTypeNumber
};

@protocol VLCNetworkServerLoginInformationField <NSObject>
@property (nonatomic, readonly) VLCNetworkServerLoginInformationFieldType type;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *localizedLabel;
@property (nonatomic, copy) NSString *textValue;
@end

@protocol VLCNetworkServerLoginInformation <NSObject>
@property (nonatomic, copy, nullable) NSString *username;
@property (nonatomic, copy, nullable) NSString *password;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSNumber *port;
@property (nonatomic, copy) NSString *protocolIdentifier;
@property (nonatomic, copy) NSArray< id<VLCNetworkServerLoginInformationField>> *additionalFields;
@end

@protocol VLCLocalNetworkService <NSObject>

@required
@property (nonatomic, readonly, nullable) UIImage *icon;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *serviceName;

@optional
@property (nonatomic, readonly, nullable) NSURL *iconURL;
- (nullable id<VLCNetworkServerBrowser>)serverBrowser;
- (NSURL *)directPlaybackURL;
- (nullable id<VLCNetworkServerLoginInformation>)loginInformation;

@end

NS_ASSUME_NONNULL_END
