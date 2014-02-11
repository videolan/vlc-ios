/*****************************************************************************
 * VLCNetworkLoginViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkLoginViewController.h"
#import "UIBarButtonItem+Theme.h"

@interface VLCNetworkLoginViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    NSMutableArray *_saveServer;
    NSMutableArray *_saveLogin;
    NSMutableArray *_savePass;
    NSString *_hostname;
    NSString *_username;
    NSString *_password;
}
@end

@implementation VLCNetworkLoginViewController

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *loginDefaults = @{kVLCFTPServer : @[], kVLCFTPLogin : @[],kVLCFTPServer : @[]};

    [defaults registerDefaults:loginDefaults];
}

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

    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        UIColor *color = [UIColor colorWithWhite:0.47 alpha:1.0];
        self.serverAddressField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"ftp://yourserver.local" attributes:@{NSForegroundColorAttributeName: color}];
        self.usernameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"USER_LABEL", @"") attributes:@{NSForegroundColorAttributeName: color}];
        self.passwordField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"PASSWORD_LABEL", @"") attributes:@{NSForegroundColorAttributeName: color}];
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _saveServer = [NSMutableArray arrayWithArray:[defaults objectForKey:kVLCFTPServer]];
    _saveLogin = [NSMutableArray arrayWithArray:[defaults objectForKey:kVLCFTPLogin]];
    _savePass = [NSMutableArray arrayWithArray:[defaults objectForKey:kVLCFTPPassword]];

    [super viewWillAppear:animated];

    if ([defaults stringForKey:kVLCLastFTPServer])
        self.serverAddressField.text = [defaults stringForKey:kVLCLastFTPServer];
    if ([defaults stringForKey:kVLCLastFTPLogin])
        self.usernameField.text = [defaults stringForKey:kVLCLastFTPLogin];
    if ([defaults stringForKey:kVLCLastFTPPassword])
        self.passwordField.text = [defaults stringForKey:kVLCLastFTPPassword];

    if (_hostname.length > 0)
        self.serverAddressField.text = _hostname;
    if (_username.length > 0)
        self.usernameField.text = _username;
    if (_password.length > 0)
        self.passwordField.text = _password;
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.serverAddressField.text forKey:kVLCLastFTPServer];
    [defaults setObject:self.usernameField.text forKey:kVLCLastFTPLogin];
    [defaults setObject:self.passwordField.text forKey:kVLCLastFTPPassword];

    [super viewWillDisappear:animated];
}

- (IBAction)dismissWithAnimation:(id)sender
{
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        self.navigationController.navigationBar.translucent = YES;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)dismiss:(id)sender
{
    if (SYSTEM_RUNS_IOS7_OR_LATER)
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

- (IBAction)saveFTP:(id)sender {
    [_saveServer addObject:self.serverAddressField.text];
    [_saveLogin addObject:self.usernameField.text];
    [_savePass  addObject:self.passwordField.text];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSArray arrayWithArray:_saveServer] forKey:kVLCFTPServer];
    [defaults setObject:[NSArray arrayWithArray:_saveLogin] forKey:kVLCFTPLogin];
    [defaults setObject:[NSArray arrayWithArray:_savePass] forKey:kVLCFTPPassword];
    [defaults synchronize];
    [self.historyLogin reloadData];
}

#pragma mark - text view delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.serverAddressField isFirstResponder]) {
        [self.serverAddressField resignFirstResponder];
        [self.usernameField becomeFirstResponder];
    } else if ([self.usernameField isFirstResponder]) {
        [self.usernameField resignFirstResponder];
        [self.passwordField becomeFirstResponder];
    } else if ([self.passwordField isFirstResponder]) {
        [self.passwordField resignFirstResponder];
        //[self connectToServer:nil];
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
    return _saveServer.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FTPHistoryCell";

    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:.72 alpha:1.];
    }

    NSInteger row = indexPath.row;
    cell.textLabel.text = [_saveServer[row] lastPathComponent];
    cell.detailTextLabel.text = _saveLogin[row];

    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor colorWithWhite:.122 alpha:1.];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_saveServer removeObjectAtIndex:indexPath.row];
        [_saveLogin removeObjectAtIndex:indexPath.row];
        [_savePass removeObjectAtIndex:indexPath.row];
        [tableView reloadData];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSArray arrayWithArray:_saveServer] forKey:kVLCFTPServer];
        [defaults setObject:[NSArray arrayWithArray:_saveLogin] forKey:kVLCFTPLogin];
        [defaults setObject:[NSArray arrayWithArray:_savePass] forKey:kVLCFTPPassword];
        [defaults synchronize];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.serverAddressField setText:_saveServer[indexPath.row]];
    [self.usernameField setText:_saveLogin[indexPath.row]];
    [self.passwordField setText:_savePass[indexPath.row]];

    [self.historyLogin deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)setHostname:(NSString *)theHostname
{
    _hostname = theHostname;
    self.serverAddressField.text = theHostname;
}

- (NSString *)hostname
{
    return self.serverAddressField.text;
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
