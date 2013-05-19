//
//  VLCAddMediaViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 19.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCAddMediaViewController.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "VLCAboutViewController.h"
#import "VLCMovieViewController.h"

@interface VLCAddMediaViewController ()

@end

@implementation VLCAddMediaViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        self.dismissButton.titleLabel.text = NSLocalizedString(@"BUTTON_DONE", @"");
    self.aboutButton.titleLabel.text = NSLocalizedString(@"ABOUT_APP", @"");
    self.openNetworkStreamButton.titleLabel.text = NSLocalizedString(@"OPEN_NETWORK", @"");
    self.downloadFromHTTPServerButton.titleLabel.text = NSLocalizedString(@"DOWNLOAD_FROM_HTTP", @"");
}

- (void)viewWillAppear:(BOOL)animated
{
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
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;

    if (!appDelegate.playlistViewController.aboutViewController)
        appDelegate.playlistViewController.aboutViewController = [[VLCAboutViewController alloc] initWithNibName:@"VLCAboutViewController" bundle:nil];
    [appDelegate.playlistViewController.navigationController pushViewController:appDelegate.playlistViewController.aboutViewController animated:YES];

    [self _hideAnimated:NO];
}

- (IBAction)openNetworkStream:(id)sender
{
    if ([[UIPasteboard generalPasteboard] containsPasteboardTypes:[NSArray arrayWithObjects:@"public.url", @"public.text", nil]]) {
        _pasteURL = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.url"];
        if (!_pasteURL || [[_pasteURL absoluteString] isEqualToString:@""]) {
            NSString * pasteString = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.text"];
            _pasteURL = [NSURL URLWithString:pasteString];
        }

        if (_pasteURL && ![[_pasteURL scheme] isEqualToString:@""] && ![[_pasteURL absoluteString] isEqualToString:@""]) {
            NSString * messageString = [NSString stringWithFormat:@"Do you want to open %@?", [_pasteURL absoluteString]];
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"OPEN_URL", @"") message:messageString delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:NSLocalizedString(@"BUTTON_OPEN", @""), nil];
            [alert show];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate.playlistViewController openMovieFromURL:_pasteURL];
    }

    [self _hideAnimated:NO];
}

- (IBAction)downloadFromHTTPServer:(id)sender
{
    //TODO
}

- (IBAction)showSettings:(id)sender
{
}

- (IBAction)showInformationOnHTTPServer:(id)sender
{
}

- (IBAction)toggleHTTPServer:(id)sender
{
}

@end
