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
#import "VLCDropboxController.h"
#import "VLCDropboxCollectionViewController.h"
#import "VLCPlayerDisplayController.h"
#import "VLCOneDriveController.h"
#import "VLCOneDriveCollectionViewController.h"
#import "VLCBoxCollectionViewController.h"
#import "VLCBoxController.h"
#import "MetaDataFetcherKit.h"

@interface VLCCloudServicesTVViewController ()
{
    VLCOneDriveController *_oneDriveController;
    VLCBoxController *_boxController;
}
@end

@implementation VLCCloudServicesTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.helpLabel.text = NSLocalizedString(@"CLOUD_LOGIN_LONG", nil);
    [self.helpLabel sizeToFit];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(oneDriveSessionUpdated:) name:VLCOneDriveControllerSessionUpdated object:nil];
    [center addObserver:self selector:@selector(boxSessionUpdated:) name:VLCBoxControllerSessionUpdated object:nil];

    MDFMovieDBSessionManager *movieDBSessionManager = [MDFMovieDBSessionManager sharedInstance];
    movieDBSessionManager.apiKey = kVLCfortvOSMovieDBKey;
    [movieDBSessionManager fetchProperties];

    _oneDriveController = [VLCOneDriveController sharedInstance];
    _boxController = [VLCBoxController sharedInstance];
    [_boxController startSession];

    self.dropboxButton.enabled = self.gDriveButton.enabled = NO;
    [self oneDriveSessionUpdated:nil];
    [self boxSessionUpdated:nil];

    [self performSelector:@selector(updateDropbox) withObject:nil afterDelay:0.1];
}

- (NSString *)title
{
    return NSLocalizedString(@"CLOUD_SERVICES", nil);
}

- (IBAction)dropbox:(id)sender
{
    VLCDropboxCollectionViewController *targetViewController = [[VLCDropboxCollectionViewController alloc] initWithNibName:@"VLCRemoteBrowsingCollectionViewController" bundle:nil];
    [self.navigationController pushViewController:targetViewController animated:YES];
}

- (void)updateDropbox
{
    self.dropboxButton.enabled = [[VLCDropboxController sharedInstance] restoreFromSharedCredentials];
}

- (void)oneDriveSessionUpdated:(NSNotification *)aNotification
{
    self.oneDriveButton.enabled = _oneDriveController.activeSession;
}

- (void)boxSessionUpdated:(NSNotification *)aNotification
{
    self.boxButton.enabled = YES;
}

- (IBAction)onedrive:(id)sender
{
    VLCOneDriveCollectionViewController *targetViewController = [[VLCOneDriveCollectionViewController alloc] initWithOneDriveObject:nil];
    [self.navigationController pushViewController:targetViewController animated:YES];
}

- (IBAction)box:(id)sender
{
    VLCBoxCollectionViewController *targetViewController = [[VLCBoxCollectionViewController alloc] initWithPath:@""];
    [self.navigationController pushViewController:targetViewController animated:YES];
}

- (IBAction)gdrive:(id)sender
{
    // TODO
}

@end
