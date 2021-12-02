/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016, 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *          Felix Paul Kühne <fkuehne # videolan.org>
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
@property (nonatomic, strong) VLCNetworkServerLoginInformation *loginInformation;
@end

@protocol VLCNetworkLoginDataSourceLoginDelegate <NSObject>
- (void)saveLoginDataSource:(VLCNetworkLoginDataSourceLogin *)dataSource;
- (void)connectLoginDataSource:(VLCNetworkLoginDataSourceLogin *)dataSource;
- (void)canConnect:(BOOL)boolValue;
@end

NS_ASSUME_NONNULL_END
