//
//  VLCSettingsController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 23.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "IASKAppSettingsViewController.h"
#import "PAPasscodeViewController.h"

@interface VLCSettingsController : NSObject <PAPasscodeViewControllerDelegate, IASKSettingsDelegate>

@property (nonatomic, retain) IASKAppSettingsViewController *viewController;

@end
