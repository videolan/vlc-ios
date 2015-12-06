/*****************************************************************************
 * VLCNetworkServerLoginInformation.h
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
#import "VLCLocalNetworkService-Protocol.h"

NS_ASSUME_NONNULL_BEGIN
@interface VLCNetworkServerLoginInformation : NSObject <VLCNetworkServerLoginInformation>
@property (nonatomic, nullable) NSString *username;
@property (nonatomic, nullable) NSString *password;
@property (nonatomic) NSString *address;
@property (nonatomic) NSNumber *port;
@property (nonatomic) NSString *protocolIdentifier;
@end
NS_ASSUME_NONNULL_END
