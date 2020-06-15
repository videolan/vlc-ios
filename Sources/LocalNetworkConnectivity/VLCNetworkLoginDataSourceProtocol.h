/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "VLCNetworkLoginDataSourceSection.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, VLCServerProtocol) {
    VLCServerProtocolSMB,
    VLCServerProtocolFTP,
    VLCServerProtocolPLEX,
    VLCServerProtocolNFS,
    VLCServerProtocolSFTP,
    VLCServerProtocolUndefined,
};
@class VLCNetworkLoginDataSourceProtocol;
@protocol VLCNetworkLoginDataSourceProtocolDelegate <NSObject>
- (void)protocolDidChange:(VLCNetworkLoginDataSourceProtocol *)protocolSection;
@end

@interface VLCNetworkLoginDataSourceProtocol : NSObject <VLCNetworkLoginDataSourceSection>
@property (nonatomic) VLCServerProtocol protocol;
@property (nonatomic, weak) id<VLCNetworkLoginDataSourceProtocolDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
