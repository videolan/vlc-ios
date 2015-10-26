/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCloudServicesTVViewController.h"
#import <DropboxTVSDK/DropboxSDK.h>
#import "VLCDropboxController.h"
#import "VLCDropboxTableViewController.h"
#import "SSKeychain.h"
#import "VLCPlayerDisplayController.h"
#import "VLCOneDriveTableViewController.h"
#import "VLCBoxTableViewController.h"

@interface VLCCloudServicesTVViewController ()

@property (nonatomic) VLCDropboxTableViewController *dropboxTableViewController;
@property (nonatomic) VLCOneDriveTableViewController *oneDriveTableViewController;
@property (nonatomic) VLCBoxTableViewController *boxTableViewController;

@end

@implementation VLCCloudServicesTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.dropboxTableViewController = [[VLCDropboxTableViewController alloc] initWithNibName:@"VLCCloudStorageTableViewController" bundle:nil];
    self.oneDriveTableViewController = [[VLCOneDriveTableViewController alloc] initWithNibName:@"VLCCloudStorageTableViewController" bundle:nil];
    self.boxTableViewController = [[VLCBoxTableViewController alloc] initWithNibName:@"VLCCloudStorageTableViewController" bundle:nil];
}

- (NSString *)title
{
    return NSLocalizedString(@"CLOUD_SERVICES", nil);
}

- (IBAction)dropbox:(id)sender
{
    if ([[VLCDropboxController sharedInstance] restoreFromSharedCredentials]) {
        [self showDetailViewController:self.dropboxTableViewController sender:self];
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"LOGIN_FAIL", nil)
                                                                   message:[NSString stringWithFormat:NSLocalizedString(@"CLOUD_LOGIN_FAIL_LONG", nil), @"Dropbox", @"Dropbox"]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                          }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_RETRY", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             [self dropbox:nil];
                                                         }];
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onedrive:(id)sender
{
    [self showDetailViewController:self.oneDriveTableViewController sender:self];
}

- (IBAction)box:(id)sender
{
    [self showDetailViewController:self.boxTableViewController sender:self];
}

@end
