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

@interface VLCCloudServicesTVViewController ()

@property (nonatomic) VLCDropboxTableViewController *dropboxTableViewController;
@end

@implementation VLCCloudServicesTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.dropboxTableViewController = [[VLCDropboxTableViewController alloc] initWithNibName:@"VLCCloudStorageTableViewController" bundle:nil];
}

- (NSString *)title
{
    return @"Cloud Services";
}

- (void)dropbox:(id)sender
{
    if ([[VLCDropboxController sharedInstance] restoreFromSharedCredentials]) {
        [self showDetailViewController:self.dropboxTableViewController sender:self];
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Login failure"
                                                                   message:@"To use Dropbox, you need to login to iCloud with the same ID to both this Apple TV and an iOS device.\nAfterwards, login to Dropbox using the VLC app on your iOS device and try again."
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

@end
