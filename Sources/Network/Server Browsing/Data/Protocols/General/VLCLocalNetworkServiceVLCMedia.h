/*****************************************************************************
 * VLCLocalNetworkServiceVLCMedia.h
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

@interface VLCLocalNetworkServiceVLCMedia : NSObject <VLCLocalNetworkService>
- (instancetype)initWithMediaItem:(VLCMedia *)mediaItem serviceName:(NSString *)serviceName;
@property (nonatomic, readonly) VLCMedia *mediaItem;
@end

NS_ASSUME_NONNULL_END
