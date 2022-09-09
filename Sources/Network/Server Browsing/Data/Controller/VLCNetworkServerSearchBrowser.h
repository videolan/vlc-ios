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
#import "VLCNetworkServerBrowser-Protocol.h"

NS_ASSUME_NONNULL_BEGIN
@interface VLCNetworkServerSearchBrowser : NSObject <VLCNetworkServerBrowser, VLCNetworkServerBrowserDelegate>
// change the searchText to update the filters
@property (nonatomic, copy, nullable) NSString *searchText;
// VLCNetworkServerSearchBrowser does not set itself as the delegate of the serverBrowser,
// instead the delegate of the serverBrowser has to relay the delegate methods to VLCNetworkServerSearchBrowser while active.
- (instancetype)initWithServerBrowser:(id<VLCNetworkServerBrowser>)serverBrowser;
@end
NS_ASSUME_NONNULL_END
