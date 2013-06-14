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

#import <ifaddrs.h>
#import <arpa/inet.h>

@interface VLCMenuViewController () {
    VLCHTTPUploaderController *_uploadController;
    Reachability *_reachability;
    VLCHTTPFileDownloader *_httpDownloader;
}
- (void)_presentOpenURLViewFromView:(UIView *)view forSelector:(SEL)selector;
@end

@implementation VLCMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    return self;
}

- (void)dealloc
{
    [_reachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", @"")
                                                                          style:UIBarButtonItemStyleBordered
                                                                         target:self
                                                                         action:@selector(dismiss:)];
        [dismissButton setBackgroundImage:[UIImage imageNamed:@"doneButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [dismissButton setBackgroundImage:[UIImage imageNamed:@"doneButtonHighlight"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
        [dismissButton setTitleTextAttributes:@{UITextAttributeTextShadowColor : [UIColor whiteColor], UITextAttributeTextColor : [UIColor blackColor]} forState:UIControlStateNormal];
        dismissButton.width = 80.;

        self.navigationItem.rightBarButtonItem = dismissButton;

        self.scrollView.contentSize = self.view.frame.size;
    }
    [self.aboutButton setTitle:NSLocalizedString(@"ABOUT_APP", @"") forState:UIControlStateNormal];
    [self.openNetworkStreamButton setTitle:NSLocalizedString(@"OPEN_NETWORK", @"") forState:UIControlStateNormal];
    [self.downloadFromHTTPServerButton setTitle:NSLocalizedString(@"DOWNLOAD_FROM_HTTP", @"") forState:UIControlStateNormal];
    [self.openURLButton setTitle:NSLocalizedString(@"BUTTON_OPEN", @"") forState:UIControlStateNormal];
    self.httpUploadLabel.text = NSLocalizedString(@"HTTP_UPLOAD", @"");
    [self.settingsButton setTitle:NSLocalizedString(@"Settings", @"") forState:UIControlStateNormal]; // plain text key to keep compatibility with InAppSettingsKit's upstream
    _reachability = [Reachability reachabilityForLocalWiFi];
    [_reachability startNotifier];

    [self netReachabilityChanged:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
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

- (void)viewWillAppear:(BOOL)animated
{
    [self.openURLButton sizeToFit];
    if (self.openURLView.superview)
        [self.openURLView removeFromSuperview];

    [super viewWillAppear:animated];
}

- (void)_hideAnimated:(BOOL)animated
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate.playlistViewController.addMediaPopoverController dismissPopoverAnimated:YES];
    } else
        [self dismissViewControllerAnimated:animated completion:NULL];
}

- (IBAction)dismiss:(id)sender
{
    [self _hideAnimated:YES];
}

- (IBAction)openAboutPanel:(id)sender
{
    UIViewController *aboutController = [[VLCAboutViewController alloc] initWithNibName:nil bundle:nil];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:aboutController];
    navController.navigationBar.barStyle = UIBarStyleBlack;
    [navController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarBackground"] forBarMetrics:UIBarMetricsDefault];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [navController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarBackgroundPhoneLandscape"] forBarMetrics:UIBarMetricsLandscapePhone];

    [self presentModalViewController:navController animated:YES];
}

- (IBAction)openNetworkStream:(id)sender
{
    if (sender == self.openNetworkStreamButton) {
        [self _presentOpenURLViewFromView:self.openNetworkStreamButton forSelector:@selector(openNetworkStream:)];
    } else {
        VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate.playlistViewController openMovieFromURL:[NSURL URLWithString:self.openURLField.text]];
        [self _hideAnimated:YES];
    }
}

- (IBAction)downloadFromHTTPServer:(id)sender
{
    if (_httpDownloader) {
        if (_httpDownloader.downloadInProgress)
            return;
    }

    if (sender == self.downloadFromHTTPServerButton) {
        [self _presentOpenURLViewFromView:self.downloadFromHTTPServerButton forSelector:@selector(downloadFromHTTPServer:)];
    } else {
        NSURL *URLtoSave = [NSURL URLWithString:self.openURLField.text];
        if (([URLtoSave.scheme isEqualToString:@"http"] || [URLtoSave.scheme isEqualToString:@"https"]) && ![URLtoSave.lastPathComponent.pathExtension isEqualToString:@""]) {
            if (!_httpDownloader) {
                _httpDownloader = [[VLCHTTPFileDownloader alloc] init];
                _httpDownloader.mediaViewController = self;
            }
            [_httpDownloader downloadFileFromURL:URLtoSave];
            [self.openURLView removeFromSuperview];
        } else {
            APLog(@"URL is not a file download");
            [self _hideAnimated:YES];
        }
    }
}

- (IBAction)showSettings:(id)sender
{
    if (!self.settingsViewController)
        self.settingsViewController = [[IASKAppSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];

    if (!self.settingsController)
        self.settingsController = [[VLCSettingsController alloc] init];

    self.settingsViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    self.settingsViewController.delegate = self.settingsController;
    self.settingsViewController.showDoneButton = YES;
    self.settingsViewController.showCreditsFooter = NO;

    self.settingsController.viewController = self.settingsViewController;

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.settingsViewController];
    navController.navigationBarHidden = NO;
    navController.navigationBar.barStyle = UIBarStyleBlack;
    [navController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarBackground"] forBarMetrics:UIBarMetricsDefault];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [navController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarBackgroundPhoneLandscape"] forBarMetrics:UIBarMetricsLandscapePhone];
    [self presentModalViewController:navController animated:YES];

    UIBarButtonItem *doneButton = self.settingsViewController.navigationItem.rightBarButtonItem;
    [doneButton setBackgroundImage:[UIImage imageNamed:@"doneButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [doneButton setBackgroundImage:[UIImage imageNamed:@"doneButtonHighlight"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    doneButton.style = UIBarButtonItemStyleBordered;
    [doneButton setTitleTextAttributes:@{UITextAttributeTextShadowColor : [UIColor whiteColor], UITextAttributeTextColor : [UIColor blackColor]} forState:UIControlStateNormal];
}

- (NSString *)_currentIPAddress
{
    NSString *address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([@(temp_addr->ifa_name) isEqualToString:@"en0"])
                    address = @(inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr));
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

- (IBAction)toggleHTTPServer:(UISwitch *)sender
{
    _uploadController = [[VLCHTTPUploaderController alloc] init];
    [_uploadController changeHTTPServerState: sender.on];

    HTTPServer *server = _uploadController.httpServer;
    if (server.isRunning)
        self.httpUploadServerLocationLabel.text = [NSString stringWithFormat:@"http://%@:%i", [self _currentIPAddress], server.listeningPort];
    else
        self.httpUploadServerLocationLabel.text = NSLocalizedString(@"HTTP_UPLOAD_SERVER_OFF", @"");
}

- (IBAction)showDropbox:(id)sender
{
    VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;

    appDelegate.dropboxTableViewController.modalPresentationStyle = UIModalPresentationFormSheet;

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:appDelegate.dropboxTableViewController];
    navController.navigationBarHidden = NO;
    navController.navigationBar.barStyle = UIBarStyleBlack;
    [navController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarBackground"] forBarMetrics:UIBarMetricsDefault];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [navController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarBackgroundPhoneLandscape"] forBarMetrics:UIBarMetricsLandscapePhone];
    [self presentModalViewController:navController animated:YES];
}

#pragma mark - Private methods

- (void)_presentOpenURLViewFromView:(UIView *)view forSelector:(SEL)selector
{
    if ([[UIPasteboard generalPasteboard] containsPasteboardTypes:@[@"public.url", @"public.text"]]) {
        NSURL *pasteURL = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.url"];
        if (!pasteURL || [[pasteURL absoluteString] isEqualToString:@""]) {
            NSString *pasteString = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.text"];
            pasteURL = [NSURL URLWithString:pasteString];
        }

        if (pasteURL && ![[pasteURL scheme] isEqualToString:@""] && ![[pasteURL absoluteString] isEqualToString:@""])
            self.openURLField.text = [pasteURL absoluteString];
    }
    if (self.openURLView.superview)
        [self.openURLView removeFromSuperview];
    [self.openURLButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.openURLButton addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:self.openURLView];
}

@end
