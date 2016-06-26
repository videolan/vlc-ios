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
@class VLCNetworkServerLoginInformation, VLCNetworkLoginDataSourceSavedLogins;

@protocol VLCNetworkLoginDataSourceSavedLoginsDelegate <NSObject>

- (void)loginsDataSource:(VLCNetworkLoginDataSourceSavedLogins *)dataSource selectedLogin:(VLCNetworkServerLoginInformation *)login;

@end

@interface VLCNetworkLoginDataSourceSavedLogins : NSObject <VLCNetworkLoginDataSourceSection>
@property (nonatomic, weak) id<VLCNetworkLoginDataSourceSavedLoginsDelegate> delegate;
- (BOOL)saveLogin:(VLCNetworkServerLoginInformation *)login error:(NSError **)error;
- (BOOL)deleteItemAtRow:(NSUInteger)row error:(NSError **)error;

@end
NS_ASSUME_NONNULL_END
