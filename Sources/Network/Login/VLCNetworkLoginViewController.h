/*****************************************************************************
 * VLCNetworkLoginViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@class VLCNetworkServerLoginInformation, VLCNetworkLoginViewController;

NS_ASSUME_NONNULL_BEGIN
@protocol VLCNetworkLoginViewControllerDelegate <NSObject>
@required
- (void)loginWithLoginViewController:(VLCNetworkLoginViewController *)loginViewController loginInfo:(VLCNetworkServerLoginInformation *)loginInformation;
@end

@interface VLCNetworkLoginViewController : UIViewController
@property (nonatomic) VLCNetworkServerLoginInformation *loginInformation;
@property (nonatomic, weak, nullable) id<VLCNetworkLoginViewControllerDelegate> delegate;

@end
NS_ASSUME_NONNULL_END
