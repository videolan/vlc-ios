//
//  VLCGoogleDriveTableViewController.h
//  VLC for iOS
//
//  Created by Carola Nitz on 21.09.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCGoogleDriveController.h"
#import "GTMOAuth2ViewControllerTouch.h"

@interface VLCGoogleDriveTableViewController : UIViewController <VLCGoogleDriveController>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *loginToGoogleDriveView;
@property (nonatomic, strong) IBOutlet UIButton *loginToGoogleDriveButton;


- (IBAction)loginToGoogleDriveAction:(id)sender;
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)authResult error:(NSError *)error;
- (void)updateViewAfterSessionChange;

@end
