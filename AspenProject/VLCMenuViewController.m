//
//  VLCMenuViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 19.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCMenuViewController.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "VLCAboutViewController.h"
#import "VLCMovieViewController.h"
#import "VLCHTTPUploaderController.h"
#import "VLCSettingsController.h"
#import "HTTPServer.h"
#import "Reachability.h"
#import "VLCHTTPFileDownloader.h"
#import "IASKAppSettingsViewController.h"
#import "UINavigationController+Theme.h"
#import "UIBarButtonItem+Theme.h"
#import "VLCOpenNetworkStreamViewController.h"
#import "VLCHTTPDownloadViewController.h"
#import "VLCBugreporter.h"

@interface VLCMenuViewController () {
    VLCHTTPDownloadViewController *_downloadViewController;
    Reachability *_reachability;
}
- (void)_presentViewController:(UIViewController *)viewController;
- (void)_dismissModalViewController;

@property(nonatomic) VLCHTTPUploaderController *uploadController;
@property(nonatomic) VLCAppDelegate *appDelegate;;

@end

@implementation VLCMenuViewController

- (void)dealloc
{
    [_reachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.view.frame = CGRectMake(0.0f, 0.0f, kGHRevealSidebarWidth, CGRectGetHeight(self.view.bounds));
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;

    [self.aboutButton setTitle:NSLocalizedString(@"ABOUT_APP", @"") forState:UIControlStateNormal];
    [self.openNetworkStreamButton setTitle:NSLocalizedString(@"OPEN_NETWORK", @"") forState:UIControlStateNormal];
    [self.downloadFromHTTPServerButton setTitle:NSLocalizedString(@"DOWNLOAD_FROM_HTTP", @"") forState:UIControlStateNormal];
    self.httpUploadLabel.text = NSLocalizedString(@"HTTP_UPLOAD", @"");
    [self.settingsButton setTitle:NSLocalizedString(@"Settings", @"") forState:UIControlStateNormal]; // plain text key to keep compatibility with InAppSettingsKit's upstream
    _reachability = [Reachability reachabilityForLocalWiFi];
    [_reachability startNotifier];

    [self netReachabilityChanged:nil];

    self.appDelegate = [[UIApplication sharedApplication] delegate];
    self.uploadController = self.appDelegate.uploadController;

    BOOL isHTTPServerOn = [[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingSaveHTTPUploadServerStatus];
    [self.httpUploadServerSwitch setOn:isHTTPServerOn];
    [self updateHTTPServerAddress];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.view.frame = CGRectMake(0.0f, 0.0f,kGHRevealSidebarWidth, CGRectGetHeight(self.view.bounds));
}

- (void)netReachabilityChanged:(NSNotification *)notification
{
    if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
        self.httpUploadServerSwitch.enabled = YES;
        self.httpUploadServerLocationLabel.text = NSLocalizedString(@"HTTP_UPLOAD_SERVER_OFF", @"");
    } else {
        self.httpUploadServerSwitch.enabled = NO;
        self.httpUploadServerSwitch.on = NO;
        self.httpUploadServerLocationLabel.text = NSLocalizedString(@"HTTP_UPLOAD_NO_CONNECTIVITY", @"");
    }
}

- (IBAction)showAllFiles:(id)sender
{
    [self _presentViewController:[(VLCAppDelegate*)[UIApplication sharedApplication].delegate playlistViewController]];
}

- (IBAction)openAboutPanel:(id)sender
{
    UIViewController *aboutController = [[VLCAboutViewController alloc] initWithNibName:nil bundle:nil];
    [self _presentViewController:aboutController];
}

- (IBAction)openNetworkStream:(id)sender
{
    UIViewController *openURLController = [[VLCOpenNetworkStreamViewController alloc] initWithNibName:nil bundle:nil];
    [self _presentViewController:openURLController];
}

- (IBAction)downloadFromHTTPServer:(id)sender
{
    if (!_downloadViewController)
        _downloadViewController = [[VLCHTTPDownloadViewController alloc] initWithNibName:nil bundle:nil];

    [self _presentViewController:_downloadViewController];
}

- (IBAction)showSettings:(id)sender
{
    if (!self.settingsController) {
        self.settingsController = [[VLCSettingsController alloc] init];
    }

    if (!self.settingsViewController) {
        self.settingsViewController = [[IASKAppSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        self.settingsController.viewController = self.settingsViewController;
        self.settingsViewController.navigationItem.leftBarButtonItem = [UIBarButtonItem themedBackButtonWithTarget:self.settingsViewController andSelector:@selector(dismiss:)];
    }

    self.settingsViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    self.settingsViewController.delegate = self.settingsController;
    self.settingsViewController.showDoneButton = NO;
    self.settingsViewController.showCreditsFooter = NO;

    [self _presentViewController:self.settingsController.viewController];
}

- (void)updateHTTPServerAddress
{
    HTTPServer *server = self.uploadController.httpServer;
    if (server.isRunning)
        self.httpUploadServerLocationLabel.text = [NSString stringWithFormat:@"http://%@:%i", [self.uploadController currentIPAddress], server.listeningPort];
    else
        self.httpUploadServerLocationLabel.text = NSLocalizedString(@"HTTP_UPLOAD_SERVER_OFF", @"");
}

- (IBAction)toggleHTTPServer:(UISwitch *)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:kVLCSettingSaveHTTPUploadServerStatus];
    [self.uploadController changeHTTPServerState:sender.on];
    [self updateHTTPServerAddress];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)showDropbox:(id)sender
{
    self.appDelegate.dropboxTableViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self _presentViewController:self.appDelegate.dropboxTableViewController];
}

#pragma mark - Private methods

- (void)_presentViewController:(UIViewController *)viewController
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [navController loadTheme];

    GHRevealViewController *ghVC = [(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController];
    ghVC.contentViewController = navController;
    [ghVC toggleSidebar:NO duration:kGHRevealSidebarDefaultAnimationDuration];
}

#pragma mark - shake to support

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake)
        [[VLCBugreporter sharedInstance] handleBugreportRequest];
}

- (void)_dismissModalViewController
{
    [self dismissModalViewControllerAnimated:YES];
}
@end
