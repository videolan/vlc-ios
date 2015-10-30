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
#import "VLCOneDriveController.h"
#import "VLCOneDriveTableViewController2.h"
#import "VLCBoxTableViewController.h"

@interface VLCCloudServicesTVViewController ()
{
    VLCOneDriveController *_oneDriveController;
}

@property (nonatomic) VLCDropboxTableViewController *dropboxTableViewController;
@property (nonatomic) VLCBoxTableViewController *boxTableViewController;

@end

@implementation VLCCloudServicesTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(oneDriveSessionUpdated:) name:VLCOneDriveControllerSessionUpdated object:nil];

    _oneDriveController = [VLCOneDriveController sharedInstance];
    self.dropboxTableViewController = [[VLCDropboxTableViewController alloc] initWithNibName:nil bundle:nil];
    self.boxTableViewController = [[VLCBoxTableViewController alloc] initWithNibName:nil bundle:nil];

    [self oneDriveSessionUpdated:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)title
{
    return NSLocalizedString(@"CLOUD_SERVICES", nil);
}

- (IBAction)dropbox:(id)sender
{
    if ([[VLCDropboxController sharedInstance] restoreFromSharedCredentials]) {
        [self.navigationController pushViewController:self.dropboxTableViewController animated:YES];
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

- (void)oneDriveSessionUpdated:(NSNotification *)aNotification
{
    self.oneDriveButton.enabled = _oneDriveController.activeSession;
}

- (IBAction)onedrive:(id)sender
{
    VLCOneDriveTableViewController2 *newKid = [[VLCOneDriveTableViewController2 alloc] initWithOneDriveObject:nil];
    [self.navigationController pushViewController:newKid animated:YES];
}

- (IBAction)box:(id)sender
{
    [self.navigationController pushViewController:self.boxTableViewController animated:YES];
}

@end
