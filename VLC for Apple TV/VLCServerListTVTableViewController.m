/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCServerListTVTableViewController.h"
#import "VLCLocalNetworkServerTVCell.h"
#import "VLCServerBrowsingTVTableViewController.h"
#import "VLCNetworkServerLoginInformation.h"

#import "VLCNetworkServerBrowserPlex.h"
#import "VLCLocalNetworkServiceBrowserPlex.h"
#import "VLCNetworkServerBrowserVLCMedia.h"
#import "VLCLocalNetworkServiceBrowserDSM.h"
#import "VLCLocalNetworkServiceBrowserFTP.h"
#import "VLCNetworkServerBrowserFTP.h"
#import <SSKeychain/SSKeychain.h>

@interface VLCServerListTVTableViewController ()
{
    UILabel *_nothingFoundLabel;
}
@end

@implementation VLCServerListTVTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeAll ^ UIRectEdgeTop;
    
    UINib *nib = [UINib nibWithNibName:@"VLCLocalNetworkServerTVCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:VLCLocalServerTVCell];
    self.tableView.rowHeight = 150;

    _nothingFoundLabel = [[UILabel alloc] init];
    _nothingFoundLabel.text = NSLocalizedString(@"NO_SERVER_FOUND", nil);
    _nothingFoundLabel.textAlignment = NSTextAlignmentCenter;
    _nothingFoundLabel.textColor = [UIColor VLCLightTextColor];
    _nothingFoundLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    [_nothingFoundLabel sizeToFit];
    [_nothingFoundLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:_nothingFoundLabel];

    NSLayoutConstraint *yConstraint = [NSLayoutConstraint constraintWithItem:_nothingFoundLabel
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:yConstraint];
    NSLayoutConstraint *xConstraint = [NSLayoutConstraint constraintWithItem:_nothingFoundLabel
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:xConstraint];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.discoveryController startDiscovery];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.discoveryController stopDiscovery];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.discoveryController.numberOfSections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    VLCLocalServerDiscoveryController *discoverer = self.discoveryController;
    if (discoverer.numberOfSections > 1 && [discoverer numberOfItemsInSection:section] > 0) {
        return [self.discoveryController titleForSection:section];
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.discoveryController numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:VLCLocalServerTVCell forIndexPath:indexPath];
    id<VLCLocalNetworkService> service = [self.discoveryController networkServiceForIndexPath:indexPath];
    cell.textLabel.text = service.title;
    cell.imageView.image = service.icon ? service.icon : [UIImage imageNamed:@"serverIcon"];
    return cell;
}

- (void)showWIP:(NSString *)todo {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Work in Progress\nFeature not (yet) implemented."
                                                                             message:todo
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Please fix this!"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Nevermind"
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    id<VLCLocalNetworkService> service = [self.discoveryController networkServiceForIndexPath:indexPath];
    if ([service respondsToSelector:@selector(serverBrowser)]) {
        id <VLCNetworkServerBrowser> browser = [service serverBrowser];
        if (browser) {
            VLCServerBrowsingTVTableViewController *browsingViewController = [[VLCServerBrowsingTVTableViewController alloc] initWithServerBrowser:browser];
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:browsingViewController]
                               animated:YES
                             completion:nil];
            return;
        }
    }

    if ([service respondsToSelector:@selector(loginInformation)]) {
        VLCNetworkServerLoginInformation *login = service.loginInformation;
        if (!login) return;
        [self showLoginAlertWithLogin:login];

        return;
    }

    if ([service respondsToSelector:@selector(directPlaybackURL)]) {

        NSURL *url = service.directPlaybackURL;
        if (!url) return;

        VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
        [vpc playURL:url subtitlesFilePath:nil];
        [self presentViewController:[VLCFullscreenMovieTVViewController fullscreenMovieTVViewController]
                           animated:YES
                         completion:nil];
        return;
    }
}

- (void)showLoginAlertWithLogin:(nonnull VLCNetworkServerLoginInformation *)login
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"CONNECT_TO_SERVER", nil)
                                                                             message:login.address preferredStyle:UIAlertControllerStyleAlert];


    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = login.protocolIdentifier;
    components.host = login.address;
    components.port = login.port;
    NSString *serviceIdentifier = components.URL.absoluteString;
    NSString *accountName = [SSKeychain accountsForService:serviceIdentifier].firstObject[kSSKeychainAccountKey];
    NSString *password = [SSKeychain passwordForService:serviceIdentifier account:accountName];


    __block UITextField *usernameField = nil;
    __block UITextField *passwordField = nil;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"USER_LABEL", nil);
        textField.text = accountName;
        usernameField = textField;
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.secureTextEntry = YES;
        textField.placeholder = NSLocalizedString(@"PASSWORD_LABEL", nil);
        textField.text = password;
        passwordField = textField;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"LOGIN", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          login.username = usernameField.text;
                                                          login.password = passwordField.text;
                                                          [self showBrowserWithLogin:login];
                                                      }]];

    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_SAVE", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          NSString *accountName = usernameField.text;
                                                          NSString *password = passwordField.text;
                                                          [SSKeychain setPassword:password forService:serviceIdentifier account:accountName];
                                                          login.username = accountName;
                                                          login.password = password;
                                                          [self showBrowserWithLogin:login];
                                                      }]];
    if (accountName.length && password.length) {
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_DELETE", nil)
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [SSKeychain deletePasswordForService:serviceIdentifier account:accountName];
                                                          }]];
    }

    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showBrowserWithLogin:(nonnull VLCNetworkServerLoginInformation *)login
{
    id<VLCNetworkServerBrowser> serverBrowser = nil;
    NSString *identifier = login.protocolIdentifier;

    if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierFTP]) {
        serverBrowser = [[VLCNetworkServerBrowserFTP alloc] initWithLogin:login];
    } else if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierPlex]) {
        serverBrowser = [[VLCNetworkServerBrowserPlex alloc] initWithLogin:login];
    } else if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierSMB]) {
        serverBrowser = [VLCNetworkServerBrowserVLCMedia SMBNetworkServerBrowserWithLogin:login];
    }

    if (serverBrowser) {
        VLCServerBrowsingTVTableViewController *targetViewController = [[VLCServerBrowsingTVTableViewController alloc] initWithServerBrowser:serverBrowser];
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:targetViewController]
                           animated:YES
                         completion:nil];
    }
}

#pragma mark - VLCLocalServerDiscoveryController
- (void)discoveryFoundSomethingNew
{
    [self.tableView reloadData];
    NSLog(@"%s",__PRETTY_FUNCTION__);

    _nothingFoundLabel.hidden = self.discoveryController.foundAnythingAtAll;
}

@end
