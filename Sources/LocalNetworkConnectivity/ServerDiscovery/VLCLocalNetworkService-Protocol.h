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

NS_ASSUME_NONNULL_BEGIN
@protocol VLCLocalNetworkService <NSObject>

@required
@property (nonatomic, readonly, nullable) UIImage *icon;
@property (nonatomic, readonly) NSString *title;

@optional
- (nullable UIViewController *)detailViewController;

typedef void (^VLCLocalNetworkServiceActionBlock)(void);
@property (nonatomic, readonly) VLCLocalNetworkServiceActionBlock action;
@end

NS_ASSUME_NONNULL_END
