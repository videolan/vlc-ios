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

@interface VLCNetworkLoginViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    NSString *_hostname;
    NSString *_username;
    NSString *_password;
    UIActivityIndicatorView *_activityIndicator;
    UIView *_activityBackgroundView;
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

    self.serverField.delegate = self;
    self.serverField.returnKeyType = UIReturnKeyNext;
    self.serverField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.portField.delegate = self;
    self.portField.returnKeyType = UIReturnKeyNext;
    self.portField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.usernameField.delegate = self;
    self.usernameField.returnKeyType = UIReturnKeyNext;
    self.usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordField.delegate = self;
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.historyLogin.backgroundColor = [UIColor VLCDarkBackgroundColor];

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

    // FIXME: persistent state
    /* 
     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
     _bookmarkServer = [NSMutableArray arrayWithArray:[defaults objectForKey:kVLCPLEXServer]];
     _bookmarkPort = [NSMutableArray arrayWithArray:[defaults objectForKey:kVLCPLEXPort]];

     [super viewWillAppear:animated];

     if ([defaults stringForKey:kVLCLastPLEXServer])
     self.serverAddressField.text = [defaults stringForKey:kVLCLastPLEXServer];
     if ([defaults stringForKey:kVLCLastPLEXPort])
     self.portField.text = [defaults stringForKey:kVLCLastPLEXPort];

     if (self.portField.text.length < 1)
     self.portField.text = kPlexMediaServerPortDefault;
     */
}

- (void)viewWillDisappear:(BOOL)animated
{
    // FIXME: persistent state?!
    [super viewWillDisappear:animated];
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

            [self.navigationController popViewControllerAnimated:YES];
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
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveServer:(id)sender
{
    // FIXME:
    /*
    NSString *serverAddress = self.serverAddressField.text;
    if (!serverAddress)
        return;
    if (serverAddress.length < 1)
        return;

    [_saveServer addObject:serverAddress];
    [_saveLogin addObject:self.usernameField.text];
    [_savePass  addObject:self.passwordField.text];

     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
     [defaults setObject:[NSArray arrayWithArray:_bookmarkServer] forKey:kVLCPLEXServer];
     [defaults setObject:[NSArray arrayWithArray:_bookmarkPort] forKey:kVLCPLEXPort];

     [self.historyLogin reloadData];*/
}

- (IBAction)protocolSelectionChanged:(id)sender
{
    UIColor *color = [UIColor VLCLightTextColor];

    switch (self.protocolSegmentedControl.selectedSegmentIndex) {
        case VLCServerProtocolFTP:
        {
            self.portField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"21" attributes:@{NSForegroundColorAttributeName: color}];
            break;
        }
        case VLCServerProtocolPLEX:
        {
            self.portField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"32400" attributes:@{NSForegroundColorAttributeName: color}];
            break;
        }
        case VLCServerProtocolSMB:
        {
            self.portField.placeholder = @"";
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
    return 0; // FIXME: _saveServer.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FTPHistoryCell";

    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor VLCLightTextColor];
    }

    NSInteger row = indexPath.row;
/*  FIXME: fetch from storage
    cell.textLabel.text = [_saveServer[row] lastPathComponent];
    cell.detailTextLabel.text = _saveLogin[row];*/

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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // FIXME: remove from storage
        [tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // FIXME: fetch from storage

    [self.historyLogin deselectRowAtIndexPath:indexPath animated:NO];
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
