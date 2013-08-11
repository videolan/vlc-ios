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
        UIBarButtonItem *dismissButton = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(dismiss:)];
        self.title = @"Connect to Server";
        self.navigationItem.leftBarButtonItem = dismissButton;
    }
}

- (IBAction)dismiss:(id)sender
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)connectToServer:(id)sender
{
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(loginToServer:confirmedWithUsername:andPassword:)])
            [self.delegate loginToServer:self.serverAddressField.text confirmedWithUsername:self.usernameField.text andPassword:self.passwordField.text];
    }

    [self dismiss:nil];
}

@end
