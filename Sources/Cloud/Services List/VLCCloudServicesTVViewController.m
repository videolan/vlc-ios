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
#import "VLCPlayerDisplayController.h"
#import "VLCBoxCollectionViewController.h"
#import "VLCBoxController.h"
#import "MetaDataFetcherKit.h"

@interface VLCCloudServicesTVViewController ()
{
    VLCBoxController *_boxController;
}
@end

@implementation VLCCloudServicesTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.helpLabel.text = NSLocalizedString(@"CLOUD_LOGIN_LONG", nil);
    [self.helpLabel sizeToFit];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(boxSessionUpdated:) name:VLCBoxControllerSessionUpdated object:nil];

    if (![kVLCfortvOSMovieDBKey isEqualToString:@""]) {
        MDFMovieDBSessionManager *movieDBSessionManager = [MDFMovieDBSessionManager sharedInstance];
        movieDBSessionManager.apiKey = kVLCfortvOSMovieDBKey;
        [movieDBSessionManager fetchProperties];
    }

    _boxController = [VLCBoxController sharedInstance];
    [_boxController startSession];

    [self boxSessionUpdated:nil];
}

- (NSString *)title
{
    return NSLocalizedString(@"CLOUD_SERVICES", nil);
}

- (void)boxSessionUpdated:(NSNotification *)aNotification
{
    self.boxButton.enabled = YES;
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
