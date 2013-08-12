//
//  VLCNetworkLoginViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 11.08.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCNetworkLoginViewController.h"
#import "UIBarButtonItem+Theme.h"

@interface VLCNetworkLoginViewController ()

@end

@implementation VLCNetworkLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.modalPresentationStyle = UIModalPresentationFormSheet;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *dismissButton = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(dismissWithAnimation:)];
        self.title = @"Connect to Server";
        self.navigationItem.leftBarButtonItem = dismissButton;
    }
}

- (IBAction)dismissWithAnimation:(id)sender
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)dismiss:(id)sender
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [self.navigationController popViewControllerAnimated:NO];
    else
        [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)connectToServer:(id)sender
{
    [self dismiss:nil];

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(loginToURL:confirmedWithUsername:andPassword:)]) {
            NSString *string = self.serverAddressField.text;
            if (![string hasPrefix:@"ftp://"])
                string = [NSString stringWithFormat:@"ftp://%@", string];
            [self.delegate loginToURL:[NSURL URLWithString:string] confirmedWithUsername:self.usernameField.text andPassword:self.passwordField.text];
        }
    }
}

@end
