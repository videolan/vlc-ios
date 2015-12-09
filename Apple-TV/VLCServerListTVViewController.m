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

#import "VLCServerListTVViewController.h"
#import "VLCServerBrowsingTVViewController.h"
#import "VLCNetworkServerLoginInformation.h"

#import "VLCNetworkServerBrowserPlex.h"
#import "VLCNetworkServerBrowserVLCMedia.h"
#import "VLCNetworkServerBrowserFTP.h"
#import <SSKeychain/SSKeychain.h>

#import "VLCLocalNetworkServiceBrowserManualConnect.h"
#import "VLCLocalNetworkServiceBrowserPlex.h"
#import "VLCLocalNetworkServiceBrowserFTP.h"
#import "VLCLocalNetworkServiceBrowserUPnP.h"
#ifndef NDEBUG
#import "VLCLocalNetworkServiceBrowserSAP.h"
#endif
#import "VLCLocalNetworkServiceBrowserDSM.h"
#import "VLCLocalNetworkServiceBrowserHTTP.h"

#import "VLCRemoteBrowsingTVCell.h"

@interface VLCServerListTVViewController ()
{
    UILabel *_nothingFoundLabel;
}
@property (nonatomic) NSArray <NSIndexPath *> *indexPaths;
@end

@implementation VLCServerListTVViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"VLCRemoteBrowsingCollectionViewController" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeAll ^ UIRectEdgeTop;

    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    flowLayout.itemSize = CGSizeMake(250.0, 300.0);
    flowLayout.minimumInteritemSpacing = 48.0;
    flowLayout.minimumLineSpacing = 100.0;

    self.nothingFoundLabel.text = NSLocalizedString(@"NO_SERVER_FOUND", nil);
    [self.nothingFoundLabel sizeToFit];
    UIView *nothingFoundView = self.nothingFoundView;
    [nothingFoundView sizeToFit];
    [nothingFoundView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:nothingFoundView];

    NSLayoutConstraint *yConstraint = [NSLayoutConstraint constraintWithItem:nothingFoundView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:yConstraint];
    NSLayoutConstraint *xConstraint = [NSLayoutConstraint constraintWithItem:nothingFoundView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:xConstraint];

    NSArray *classes = @[
                         //                         [VLCLocalNetworkServiceBrowserManualConnect class],
                         [VLCLocalNetworkServiceBrowserHTTP class],
                         [VLCLocalNetworkServiceBrowserUPnP class],
                         [VLCLocalNetworkServiceBrowserDSM class],
                         [VLCLocalNetworkServiceBrowserPlex class],
                         [VLCLocalNetworkServiceBrowserFTP class],
#ifndef NDEBUG
                         [VLCLocalNetworkServiceBrowserSAP class],
#endif
                         ];
    self.discoveryController = [[VLCLocalServerDiscoveryController alloc] initWithServiceBrowserClasses:classes];
    self.discoveryController.delegate = self;
}

- (NSString *)title {
    return NSLocalizedString(@"LOCAL_NETWORK", nil);
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

#pragma mark - Collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = self.indexPaths.count;
    self.nothingFoundView.hidden = count > 0;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    VLCRemoteBrowsingTVCell *browsingCell = (VLCRemoteBrowsingTVCell *) [collectionView dequeueReusableCellWithReuseIdentifier:VLCRemoteBrowsingTVCellIdentifier forIndexPath:indexPath];

    NSIndexPath *discoveryIndexPath = self.indexPaths[indexPath.row];
    id<VLCLocalNetworkService> service = [self.discoveryController networkServiceForIndexPath:discoveryIndexPath];
    if (service == nil)
        return browsingCell;

    browsingCell.isDirectory = YES;
    browsingCell.title = service.title;
    browsingCell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    browsingCell.subtitle = [self.discoveryController titleForSection:discoveryIndexPath.section];
    browsingCell.subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    UIImage *serviceIcon = service.icon;
    browsingCell.thumbnailImage = serviceIcon ? serviceIcon : [UIImage imageNamed:@"serverIcon"];

    return browsingCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *discoveryIndexPath = self.indexPaths[indexPath.row];
    id<VLCLocalNetworkService> service = [self.discoveryController networkServiceForIndexPath:discoveryIndexPath];
    [self didSelectService:service];
}

#pragma mark - Service specific stuff

- (void)didSelectService:(id<VLCLocalNetworkService>)service
{
    if ([service respondsToSelector:@selector(serverBrowser)]) {
        id <VLCNetworkServerBrowser> browser = [service serverBrowser];
        if (browser) {
            VLCServerBrowsingTVViewController *browsingViewController = [[VLCServerBrowsingTVViewController alloc] initWithServerBrowser:browser];
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
    } else {
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_ANONYMOUS_LOGIN", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              login.username = nil;
                                                              login.password = nil;
                                                              [self showBrowserWithLogin:login];
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
        VLCServerBrowsingTVViewController *targetViewController = [[VLCServerBrowsingTVViewController alloc] initWithServerBrowser:serverBrowser];
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:targetViewController]
                           animated:YES
                         completion:nil];
    }
}

#pragma mark - VLCLocalServerDiscoveryController
- (void)discoveryFoundSomethingNew
{
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
    VLCLocalServerDiscoveryController *discoveryController = self.discoveryController;
    NSUInteger sectionCount = [discoveryController numberOfSections];
    for (NSUInteger section = 0; section < sectionCount; ++section) {
        NSUInteger itemsCount = [discoveryController numberOfItemsInSection:section];
        for (NSUInteger index = 0; index < itemsCount; ++index) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:section];
            [indexPaths addObject:indexPath];
        }
    }
    self.indexPaths = [indexPaths copy];

    [self.collectionView reloadData];

    _nothingFoundLabel.hidden = self.discoveryController.foundAnythingAtAll;
}

@end
