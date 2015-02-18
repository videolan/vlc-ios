//
//  VLCMigrationViewController.h
//  VLC for iOS
//
//  Created by Carola Nitz on 17/02/15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VLCMigrationViewController : UIViewController

@property(nonatomic) IBOutlet UILabel *statusLabel;
@property(nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property(nonatomic, copy) void (^completionHandler)();
@end
