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

#import <UIKit/UIKit.h>
#import "VLCNetworkServerLoginInformation.h"
#import "VLCNetworkLoginDataSourceSection.h"

NS_ASSUME_NONNULL_BEGIN

@protocol VLCNetworkLoginDataSourceLoginDelegate;

@interface VLCNetworkLoginDataSourceLogin : NSObject <VLCNetworkLoginDataSourceSection>
@property (nonatomic, weak) id <VLCNetworkLoginDataSourceLoginDelegate> delegate;
@property (nonatomic, nullable) VLCNetworkServerLoginInformation *loginInformation;
@end

@protocol VLCNetworkLoginDataSourceLoginDelegate <NSObject>
- (void)saveLoginDataSource:(VLCNetworkLoginDataSourceLogin *)dataSource;
- (void)connectLoginDataSource:(VLCNetworkLoginDataSourceLogin *)dataSource;
@end

NS_ASSUME_NONNULL_END
