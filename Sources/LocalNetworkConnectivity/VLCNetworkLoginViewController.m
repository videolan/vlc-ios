/*****************************************************************************
 * VLCNetworkLoginViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkLoginViewController.h"
#import "VLCPlexWebAPI.h"
#import "SSKeychain.h"

@interface VLCNetworkLoginViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    NSString *_hostname;
    NSString *_username;
    NSString *_password;
    UIActivityIndicatorView *_activityIndicator;
    UIView *_activityBackgroundView;
    NSMutableArray *_serverList;
}
@end

@implementation VLCNetworkLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.modalPresentationStyle = UIModalPresentationFormSheet;

    self.title = NSLocalizedString(@"CONNECT_TO_SERVER", nil);
    [self.connectButton setTitle:NSLocalizedString(@"BUTTON_CONNECT", nil) forState:UIControlStateNormal];
    self.serverLabel.text = NSLocalizedString(@"SERVER", nil);
    self.portLabel.text = NSLocalizedString(@"SERVER_PORT", nil);
    self.loginHelpLabel.text = NSLocalizedString(@"ENTER_SERVER_CREDS_HELP", nil);
    [self.saveButton setTitle:NSLocalizedString(@"BUTTON_SAVE", nil) forState:UIControlStateNormal];

    self.serverField.delegate = self;
    self.serverField.returnKeyType = UIReturnKeyNext;
    self.serverField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.portField.delegate = self;
    self.portField.returnKeyType = UIReturnKeyNext;
    self.portField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.portField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    self.usernameField.delegate = self;
    self.usernameField.returnKeyType = UIReturnKeyNext;
    self.usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordField.delegate = self;
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.storedServersTableView.backgroundColor = [UIColor VLCDarkBackgroundColor];

    _activityBackgroundView = [[UIView alloc] initWithFrame:self.view.frame];
    _activityBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _activityBackgroundView.hidden = YES;
    _activityBackgroundView.backgroundColor = [UIColor VLCDarkBackgroundColor];
    [self.view addSubview:_activityBackgroundView];

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.hidesWhenStopped = YES;
    _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

    [_activityBackgroundView addSubview:_activityIndicator];
    [_activityIndicator setCenter:_activityBackgroundView.center];

    UIColor *color = [UIColor VLCLightTextColor];
    self.serverField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"yourserver.local" attributes:@{NSForegroundColorAttributeName: color}];
    self.usernameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"USER_LABEL", nil) attributes:@{NSForegroundColorAttributeName: color}];
    self.passwordField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"PASSWORD_LABEL", nil) attributes:@{NSForegroundColorAttributeName: color}];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_hostname.length > 0)
        self.serverField.text = _hostname;
    if (_port.length > 0)
        self.portField.text = _port;
    if (_username.length > 0)
        self.usernameField.text = _username;
    if (_password.length > 0)
        self.passwordField.text = _password;
    if (self.serverProtocol != VLCServerProtocolUndefined) {
        self.protocolSegmentedControl.selectedSegmentIndex = self.serverProtocol;
        self.protocolSegmentedControl.enabled = NO;
    } else {
        self.protocolSegmentedControl.selectedSegmentIndex = VLCServerProtocolSMB;
        self.protocolSegmentedControl.enabled = YES;
        [self protocolSelectionChanged:nil];
    }

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(ubiquitousKeyValueStoreDidChange:)
                               name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                             object:[NSUbiquitousKeyValueStore defaultStore]];

    NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
    [ukvStore synchronize];
    _serverList = [NSMutableArray arrayWithArray:[ukvStore arrayForKey:kVLCStoredServerList]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (![defaults boolForKey:kVLCMigratedToUbiquitousStoredServerList]) {
        /* we need to migrate from previous, insecure storage fields */
        NSArray *ftpServerList = [defaults objectForKey:kVLCFTPServer];
        NSArray *ftpLoginList = [defaults objectForKey:kVLCFTPLogin];
        NSArray *ftpPasswordList = [defaults objectForKey:kVLCFTPPassword];
        NSUInteger count = ftpServerList.count;

        if (count > 0) {
            for (NSUInteger i = 0; i < count; i++) {
                [SSKeychain setPassword:ftpPasswordList[i] forService:ftpServerList[i] account:ftpLoginList[i]];
                [_serverList addObject:ftpServerList[i]];
            }
        }

        NSArray *plexServerList = [defaults objectForKey:kVLCPLEXServer];
        NSArray *plexPortList = [defaults objectForKey:kVLCPLEXPort];
        count = plexServerList.count;
        if (count > 0) {
            for (NSUInteger i = 0; i < count; i++) {
                [_serverList addObject:[NSString stringWithFormat:@"plex://%@:%@", plexServerList[i], plexPortList[i]]];
            }
        }
        [ukvStore setArray:_serverList forKey:kVLCStoredServerList];
        [ukvStore synchronize];
        [defaults setBool:YES forKey:kVLCMigratedToUbiquitousStoredServerList];
        [defaults synchronize];
    }

    [self.storedServersTableView reloadData];
    [self protocolSelectionChanged:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
    [ukvStore setArray:_serverList forKey:kVLCStoredServerList];
    [ukvStore synchronize];
}

- (void)ubiquitousKeyValueStoreDidChange:(NSNotification *)notification
{
    /* TODO: don't blindly trust that the Cloud knows best */
    _serverList = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:kVLCStoredServerList]];
    [self.storedServersTableView reloadData];
}

- (IBAction)connectToServer:(id)sender
{
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(loginToServer:port:protocol:confirmedWithUsername:andPassword:)]) {

            VLCServerProtocol protocol = self.protocolSegmentedControl.selectedSegmentIndex;
            NSString *username = self.usernameField.text;
            NSString *password = self.passwordField.text;

            if ((username.length > 0 || password.length > 0) && protocol == VLCServerProtocolPLEX) {
                _activityBackgroundView.hidden = NO;
                [_activityIndicator startAnimating];
                [self performSelectorInBackground:@selector(_plexLogin)
                                       withObject:nil];
                return;
            }

            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
                [self.navigationController popViewControllerAnimated:YES];
            else
                [self dismissViewControllerAnimated:YES completion:nil];
            [self.delegate loginToServer:self.serverField.text
                                    port:self.portField.text
                                protocol:protocol
                   confirmedWithUsername:username
                             andPassword:password];
        }
    }
}

- (void)_plexLogin
{
    VLCPlexWebAPI *PlexWebAPI = [[VLCPlexWebAPI alloc] init];
    NSString *auth = [PlexWebAPI PlexAuthentification:self.usernameField.text password:self.passwordField.text];

    if ([auth isEqualToString:@""]) {
        [self performSelectorOnMainThread:@selector(_stopActivity) withObject:nil waitUntilDone:YES];
        VLCAlertView *alertView = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"PLEX_ERROR_ACCOUNT", nil)
                                                              message:NSLocalizedString(@"PLEX_CHECK_ACCOUNT", nil)
                                                    cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                    otherButtonTitles:nil];
        [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
        return;
    }

    [self performSelectorOnMainThread:@selector(_dismiss) withObject:nil waitUntilDone:YES];

    [self.delegate loginToServer:self.serverField.text
                            port:self.portField.text
                        protocol:VLCServerProtocolPLEX
           confirmedWithUsername:auth
                     andPassword:nil];
}

- (void)_stopActivity
{
    _activityBackgroundView.hidden = YES;
    [_activityIndicator stopAnimating];
}

- (void)_dismiss
{
    _activityBackgroundView.hidden = YES;
    [_activityIndicator stopAnimating];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveServer:(id)sender
{
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];

    NSString *server = self.serverField.text;
    if (!server)
        return;

    VLCServerProtocol protocol = self.protocolSegmentedControl.selectedSegmentIndex;
    NSString *scheme;
    switch (protocol) {
        case VLCServerProtocolFTP:
            scheme = @"ftp";
            break;

        case VLCServerProtocolSMB:
            scheme = @"smb";
            break;

        case VLCServerProtocolPLEX:
            scheme = @"plex";
            break;

        default:
            break;
    }

    NSString *port = self.portField.text;
    NSString *service;
    if (port.length > 0)
        service = [NSString stringWithFormat:@"%@://%@:%@",
                   scheme, server, port];
    else
        service = [NSString stringWithFormat:@"%@://%@",
                   scheme, server];

    if ([scheme isEqualToString:@"plex"]) {
        if ([server isEqualToString:@""])
            service = [service stringByAppendingString:@"Account"];
        else
            if ([port isEqualToString:@""])
                service = [service stringByAppendingString:@":32400"];
    }

    [_serverList addObject:service];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_serverList forKey:kVLCStoredServerList];
    [defaults synchronize];

    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;

    if (username || password)
        [SSKeychain setPassword:password forService:service account:username];

    [self.storedServersTableView reloadData];
}

- (IBAction)protocolSelectionChanged:(id)sender
{
    UIColor *color = [UIColor VLCLightTextColor];

    switch (self.protocolSegmentedControl.selectedSegmentIndex) {
        case VLCServerProtocolFTP:
        {
            self.portField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"21" attributes:@{NSForegroundColorAttributeName: color}];
            self.portField.enabled = YES;
            break;
        }
        case VLCServerProtocolPLEX:
        {
            self.portField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"32400" attributes:@{NSForegroundColorAttributeName: color}];
            self.portField.enabled = YES;
            break;
        }
        case VLCServerProtocolSMB:
        {
            self.portField.placeholder = @"";
            self.portField.text = @"";
            self.portField.enabled = NO;
        }

        default:
            break;
    }

}

#pragma mark - text view delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.serverField isFirstResponder]) {
        [self.serverField resignFirstResponder];
        [self.usernameField becomeFirstResponder];
    } else if ([self.portField isFirstResponder]) {
        [self.portField resignFirstResponder];
        [self.usernameField becomeFirstResponder];
    } else if ([self.usernameField isFirstResponder]) {
        [self.usernameField resignFirstResponder];
        [self.passwordField becomeFirstResponder];
    } else if ([self.passwordField isFirstResponder]) {
        [self.passwordField resignFirstResponder];
    }
    return NO;
}

#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _serverList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StoredServerListCell";

    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor VLCLightTextColor];
    }

    NSInteger row = indexPath.row;
    NSString *serviceString = _serverList[row];
    NSURL *service = [NSURL URLWithString:serviceString];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ [%@]", service.host, [service.scheme uppercaseString]];
    NSArray *accounts = [SSKeychain accountsForService:serviceString];
    if (accounts.count > 0) {
        NSDictionary *account = [accounts firstObject];
        cell.detailTextLabel.text = [account objectForKey:@"acct"];
    } else
        cell.detailTextLabel.text = @"";

    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor VLCDarkBackgroundColor];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *serviceString = _serverList[indexPath.row];
        NSArray *accounts = [SSKeychain accountsForService:serviceString];
        NSUInteger count = accounts.count;
        for (NSUInteger i = 0; i < count; i++) {
            NSString *username = [accounts[i] objectForKey:@"acct"];
            [SSKeychain deletePasswordForService:serviceString account:username];
        }
        [_serverList removeObject:serviceString];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:serviceString];

        [tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    NSString *serviceString = _serverList[indexPath.row];
    NSURL *service = [NSURL URLWithString:serviceString];
    NSString *scheme = service.scheme;

    if ([scheme isEqualToString:@"smb"])
        self.serverProtocol = VLCServerProtocolSMB;
    else if ([scheme isEqualToString:@"ftp"])
        self.serverProtocol = VLCServerProtocolFTP;
    else if ([scheme isEqualToString:@"plex"])
        self.serverProtocol = VLCServerProtocolPLEX;
    self.protocolSegmentedControl.selectedSegmentIndex = self.serverProtocol;
    [self protocolSelectionChanged:nil];

    if ([service.host isEqualToString:@"Account"])
        self.serverField.text = @"";
    else
        self.serverField.text = service.host;
    self.portField.text = [service.port stringValue];

    NSArray *accounts = [SSKeychain accountsForService:serviceString];
    if (!accounts) {
        self.usernameField.text = self.passwordField.text = @"";
        return;
    }

    NSDictionary *account = [accounts firstObject];

    NSString *username = [account objectForKey:@"acct"];
    self.usernameField.text = username;
    self.passwordField.text = [SSKeychain passwordForService:serviceString account:username];
}

- (void)setHostname:(NSString *)theHostname
{
    _hostname = theHostname;
    self.serverField.text = theHostname;
}

- (NSString *)hostname
{
    return self.serverField.text;
}

- (void)setUsername:(NSString *)theUsername
{
    _username = theUsername;
    self.usernameField.text = theUsername;
}

- (NSString *)username
{
    return self.usernameField.text;
}

- (void)setPassword:(NSString *)thePassword
{
    _password = thePassword;
    self.passwordField.text = thePassword;
}

- (NSString *)password
{
    return self.passwordField.text;
}


@end
