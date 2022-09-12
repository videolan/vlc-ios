/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020 - 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCServerListTVViewController.h"
#import "VLCSearchableServerBrowsingTVViewController.h"
#import "VLCNetworkServerLoginInformation.h"

#import "VLCNetworkServerBrowserPlex.h"
#import "VLCNetworkServerBrowserVLCMedia.h"
#import "VLCNetworkServerBrowserVLCMedia+FTP.h"
#import "VLCNetworkServerBrowserVLCMedia+SFTP.h"

#import "VLCLocalNetworkServiceBrowserManualConnect.h"
#import "VLCLocalNetworkServiceBrowserPlex.h"
#import "VLCLocalNetworkServiceBrowserUPnP.h"
#import "VLCLocalNetworkServiceBrowserNFS.h"
#import "VLCLocalNetworkServiceBrowserDSM.h"
#import "VLCLocalNetworkServiceBrowserBonjour.h"
#import "VLCLocalNetworkServiceBrowserHTTP.h"

#import "VLCNetworkServerLoginInformation+Keychain.h"

#import "VLCRemoteBrowsingTVCell.h"

#import "VLC-Swift.h"

@interface VLCServerListTVViewController ()
@property (nonatomic, copy) NSMutableArray<id<VLCLocalNetworkService>> *networkServices;

@end

@implementation VLCServerListTVViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"VLCRemoteBrowsingCollectionViewController" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(tvOS 13.0, *)) {
        self.navigationController.navigationBarHidden = YES;
    }
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeAll ^ UIRectEdgeTop;

    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    flowLayout.itemSize = CGSizeMake(250.0, 340.0);
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
                         [VLCLocalNetworkServiceBrowserManualConnect class],
                         [VLCLocalNetworkServiceBrowserHTTP class],
                         [VLCLocalNetworkServiceBrowserUPnP class],
                         [VLCLocalNetworkServiceBrowserDSM class],
                         [VLCLocalNetworkServiceBrowserPlex class],
                         [VLCLocalNetworkServiceBrowserNFS class],
                         [VLCLocalNetworkServiceBrowserBonjour class],
                         ];
    self.discoveryController = [[VLCLocalServerDiscoveryController alloc] initWithServiceBrowserClasses:classes];
    self.discoveryController.delegate = self;
    [self discoveryFoundSomethingNew];
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
    self.networkServices = nil;
    [self.collectionView reloadData];
}

#pragma mark - Collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = self.networkServices.count;
    if (self.networkServices != nil) {
        self.nothingFoundView.hidden = count > 0;
    }
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    VLCRemoteBrowsingTVCell *browsingCell = (VLCRemoteBrowsingTVCell *) [collectionView dequeueReusableCellWithReuseIdentifier:VLCRemoteBrowsingTVCellIdentifier forIndexPath:indexPath];

    id<VLCLocalNetworkService> service = self.networkServices[indexPath.row];
    if (service == nil)
        return browsingCell;

    browsingCell.isDirectory = YES;
    browsingCell.title = service.title;
    browsingCell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    browsingCell.subtitle = service.serviceName;
    browsingCell.subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];

    NSURL *thumbnailURL;
    if ([service respondsToSelector:@selector(iconURL)]) {
        thumbnailURL = service.iconURL;
    }
    if (thumbnailURL == nil) {
        UIImage *serviceIcon = service.icon;
        browsingCell.thumbnailImage = serviceIcon ? serviceIcon : [UIImage imageNamed:@"serverIcon"];
        [browsingCell setThumbnailImage:serviceIcon];
    } else {
        [browsingCell setThumbnailURL:thumbnailURL];
    }

    return browsingCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<VLCLocalNetworkService> service = self.networkServices[indexPath.row];
    [self didSelectService:service];
}

#pragma mark - Service specific stuff

- (void)didSelectService:(id<VLCLocalNetworkService>)service
{
    if ([service respondsToSelector:@selector(serverBrowser)]) {
        id <VLCNetworkServerBrowser> browser = [service serverBrowser];
        if (browser) {
            VLCServerBrowsingTVViewController *browsingViewController = [[VLCSearchableServerBrowsingTVViewController alloc] initWithServerBrowser:browser];
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:browsingViewController]
                               animated:YES
                             completion:nil];
            return;
        }
    }

    if ([service respondsToSelector:@selector(loginInformation)]) {
        VLCNetworkServerLoginInformation *login = service.loginInformation;
        if (!login) return;

        /* UPnP does not support authentication, so skip this step */
        if ([login.protocolIdentifier isEqualToString:VLCNetworkServerProtocolIdentifierUPnP]) {
            VLCNetworkServerBrowserVLCMedia *serverBrowser = [VLCNetworkServerBrowserVLCMedia UPnPNetworkServerBrowserWithLogin:login];
                        VLCServerBrowsingTVViewController *browsingViewController = [[VLCSearchableServerBrowsingTVViewController alloc] initWithServerBrowser:serverBrowser];
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:browsingViewController]
                               animated:YES
                             completion:nil];
            return;
        }

        NSError *error = nil;
        if ([login loadLoginInformationFromKeychainWithError:&error])
        {
            if (login.protocolIdentifier)
                [self showLoginAlertWithLogin:login];
            else {
                VLCNetworkLoginTVViewController *targetViewController = [VLCNetworkLoginTVViewController alloc];
                [self presentViewController:targetViewController animated:YES completion:nil];
            }
        } else {
            [self showKeychainLoadError:error forLogin:login];
        }
        return;
    }

    if ([service respondsToSelector:@selector(directPlaybackURL)]) {

        NSURL *url = service.directPlaybackURL;
        if (!url) return;

        VLCMediaList *medialist = [[VLCMediaList alloc] init];
        [medialist addMedia:[VLCMedia mediaWithURL:url]];

        [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];

        [self presentViewController:[VLCFullscreenMovieTVViewController fullscreenMovieTVViewController]
                           animated:YES
                         completion:nil];
    }
}

- (void)showKeychainLoadError:(NSError *)error forLogin:(VLCNetworkServerLoginInformation *)login
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                             message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          [self showLoginAlertWithLogin:login];
                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showKeychainSaveError:(NSError *)error forLogin:(VLCNetworkServerLoginInformation *)login
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                             message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)showKeychainDeleteError:(NSError *)error
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                             message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)showLoginAlertWithLogin:(nonnull VLCNetworkServerLoginInformation *)login
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"CONNECT_TO_SERVER", nil)
                                                                             message:login.address preferredStyle:UIAlertControllerStyleAlert];

    __block UITextField *usernameField = nil;
    __block UITextField *passwordField = nil;
    __block UITextField *portField = nil;

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"USER_LABEL", nil);
        textField.text = login.username;
        usernameField = textField;
        if (@available(tvOS 11.0, *)) {
            usernameField.textContentType = UITextContentTypeUsername;
        }
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.secureTextEntry = YES;
        textField.placeholder = NSLocalizedString(@"PASSWORD_LABEL", nil);
        textField.text = login.password;
        passwordField = textField;
        if (@available(tvOS 11.0, *)) {
            passwordField.textContentType = UITextContentTypePassword;
        }
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"SERVER_PORT", nil);
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.text = login.port.stringValue;
        portField = textField;
    }];

    NSMutableDictionary *additionalFieldsDict = [NSMutableDictionary dictionaryWithCapacity:login.additionalFields.count];
    for (VLCNetworkServerLoginInformationField *fieldInfo in login.additionalFields) {
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            switch (fieldInfo.type) {
                case VLCNetworkServerLoginInformationFieldTypeNumber:
                    textField.keyboardType = UIKeyboardTypeNumberPad;
                    break;
                case VLCNetworkServerLoginInformationFieldTypeText:
                default:
                    textField.keyboardType = UIKeyboardTypeDefault;
                    break;
            }
            textField.placeholder = fieldInfo.localizedLabel;
            textField.text = fieldInfo.textValue;
            additionalFieldsDict[fieldInfo.identifier] = textField;
        }];
    }

    void(^loginBlock)(BOOL) = ^(BOOL save) {
        login.username = usernameField.text.length > 0 ? usernameField.text : nil;
        login.password = passwordField.text.length > 0 ? passwordField.text : nil;
        login.port = portField.text.intValue > 0 ? [NSNumber numberWithInt:portField.text.intValue] : nil;
        for (VLCNetworkServerLoginInformationField *fieldInfo in login.additionalFields) {
            UITextField *textField = additionalFieldsDict[fieldInfo.identifier];
            fieldInfo.textValue = textField.text;
        }
        if (save) {
            NSError *error = nil;
            if (![login saveLoginInformationToKeychainWithError:&error]) {
                [self showKeychainSaveError:error forLogin:login];
            }
        }
        [self showBrowserWithLogin:login];
    };

    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"LOGIN", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          loginBlock(NO);
                                                      }]];

    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_SAVE", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          loginBlock(YES);
                                                      }]];
    if (login.username.length || login.password.length) {
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_DELETE", nil)
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              NSError *error = nil;
                                                              if (![login deleteFromKeychainWithError:&error]){
                                                                  [self showKeychainDeleteError:error];
                                                              }
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

    if (!login.address || login.address.length == 0) {
        return;
    }

    if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierFTP]) {
        serverBrowser = [VLCNetworkServerBrowserVLCMedia FTPNetworkServerBrowserWithLogin:login];
    } else if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierPlex]) {
        serverBrowser = [[VLCNetworkServerBrowserPlex alloc] initWithLogin:login];
    } else if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierSMB]) {
        serverBrowser = [VLCNetworkServerBrowserVLCMedia SMBNetworkServerBrowserWithLogin:login];
    } else if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierSFTP]) {
        serverBrowser = [VLCNetworkServerBrowserVLCMedia SFTPNetworkServerBrowserWithLogin:login];
    }

    if (serverBrowser) {
        VLCServerBrowsingTVViewController *targetViewController = [[VLCSearchableServerBrowsingTVViewController alloc] initWithServerBrowser:serverBrowser];
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:targetViewController]
                           animated:YES
                         completion:nil];
    }
}

#pragma mark - VLCLocalServerDiscoveryController
- (void)discoveryFoundSomethingNew
{
    NSMutableArray<id<VLCLocalNetworkService>> *newNetworkServices = [NSMutableArray array];
    VLCLocalServerDiscoveryController *discoveryController = self.discoveryController;
    NSUInteger sectionCount = [discoveryController numberOfSections];
    for (NSUInteger section = 0; section < sectionCount; ++section) {
        NSUInteger itemsCount = [discoveryController numberOfItemsInSection:section];
        for (NSUInteger index = 0; index < itemsCount; ++index) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:section];
            id<VLCLocalNetworkService> service = [discoveryController networkServiceForIndexPath:indexPath];
            if (service != nil) {
                [newNetworkServices addObject:service];
            }
        }
    }

    self.networkServices = newNetworkServices;
    [self.collectionView reloadData];
}

@end
