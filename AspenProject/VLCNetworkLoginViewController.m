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

@interface VLCNetworkLoginViewController () <UITextFieldDelegate>

@end

@implementation VLCNetworkLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.modalPresentationStyle = UIModalPresentationFormSheet;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *dismissButton = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(dismissWithAnimation:)];
        self.navigationItem.leftBarButtonItem = dismissButton;
    }

    self.title = NSLocalizedString(@"CONNECT_TO_SERVER", nil);
    [self.connectButton setTitle:NSLocalizedString(@"BUTTON_CONNECT",@"") forState:UIControlStateNormal];
    self.serverAddressHelpLabel.text = NSLocalizedString(@"ENTER_SERVER_ADDRESS_HELP",@"");
    self.loginHelpLabel.text = NSLocalizedString(@"ENTER_SERVER_CREDS_HELP",@"");
    self.usernameLabel.text = NSLocalizedString(@"USER_LABEL", @"");
    self.passwordLabel.text = NSLocalizedString(@"PASSWORD_LABEL", @"");

    self.serverAddressField.delegate = self;
    self.serverAddressField.returnKeyType = UIReturnKeyNext;
    self.serverAddressField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.usernameField.delegate = self;
    self.usernameField.returnKeyType = UIReturnKeyNext;
    self.usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordField.delegate = self;
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
    [super viewWillAppear:animated];
}

- (IBAction)dismissWithAnimation:(id)sender
{
    if (SYSTEM_RUNS_IN_THE_FUTURE)
        self.navigationController.navigationBar.translucent = YES;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)dismiss:(id)sender
{
    if (SYSTEM_RUNS_IN_THE_FUTURE)
        self.navigationController.navigationBar.translucent = YES;

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

#pragma mark - text view delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if ([self.serverAddressField isFirstResponder])
    {
        [self.serverAddressField resignFirstResponder];
        [self.usernameField becomeFirstResponder];
    }
    else if ([self.usernameField isFirstResponder])
    {
        [self.usernameField resignFirstResponder];
        [self.passwordField becomeFirstResponder];
    }
    else if ([self.passwordField isFirstResponder])
    {
        [self.passwordField resignFirstResponder];
        //[self connectToServer:nil];
    }

    return NO;
}

@end
