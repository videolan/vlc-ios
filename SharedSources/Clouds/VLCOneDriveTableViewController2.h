//
//  VLCOneDriveTableViewController2.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 30/10/15.
//  Copyright © 2015 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VLCCloudStorageTVTableViewController.h"

@class VLCOneDriveObject;

@interface VLCOneDriveTableViewController2 : VLCCloudStorageTVTableViewController

- (instancetype)initWithOneDriveObject:(VLCOneDriveObject *)object;

@end
