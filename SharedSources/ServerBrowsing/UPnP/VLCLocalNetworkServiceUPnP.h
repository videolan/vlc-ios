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

@class BasicUPnPDevice;
@interface VLCLocalNetworkServiceUPnP : NSObject <VLCLocalNetworkService>
- (instancetype)initWithUPnPDevice:(BasicUPnPDevice *)device serviceName:(NSString *)serviceName;
@end

NS_ASSUME_NONNULL_END
