/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCPlaybackInfoTVViewController : UIViewController <UITabBarControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) IBOutlet UIView *containerView;
@property (nonatomic) IBOutlet UIVisualEffectView *visualEffectView;
@property (nonatomic) IBOutlet UIView *dimmingView;
@property (nonatomic) IBOutlet NSLayoutConstraint *tabBarRegiomHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *containerHeightConstraint;
@property (nonatomic) IBOutlet UITabBarController *tabBarController;

@end

