/*****************************************************************************
 * VLCServerListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2020 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Vincent L. Cone <vincent.l.cone # tuta.io>
 *          Carola Nitz <caro # videolan.org>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCServerListViewController.h"
#import "VLCLocalServerDiscoveryController.h"

#import "VLCPlaybackService.h"
#import "VLCNetworkListCell.h"
#import "VLCNetworkLoginViewController.h"
#import "VLCNetworkServerBrowserViewController.h"

#import "VLCNetworkServerLoginInformation+Keychain.h"

#import "VLCNetworkServerBrowserVLCMedia.h"
#import "VLCNetworkServerBrowserPlex.h"

#import "VLCLocalNetworkServiceBrowserUPnP.h"
#import "VLCLocalNetworkServiceBrowserPlex.h"
#import "VLCLocalNetworkServiceBrowserHTTP.h"
#import "VLCLocalNetworkServiceBrowserDSM.h"
#import "VLCNetworkServerBrowserVLCMedia+FTP.h"
#import "VLCNetworkServerBrowserVLCMedia+SFTP.h"
#import "VLCLocalNetworkServiceBrowserNFS.h"
#import "VLCLocalNetworkServiceBrowserBonjour.h"

#import "VLCWiFiUploadTableViewCell.h"

#import "VLCBoxController.h"
#import <OneDriveSDK.h>
#import "VLCOneDriveConstants.h"
#import "VLCDropboxConstants.h"

#import "VLC-Swift.h"

@interface VLCServerListViewController () <UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate, VLCLocalServerDiscoveryControllerDelegate, VLCNetworkLoginViewControllerDelegate, VLCRemoteNetworkDataSourceDelegate, VLCFileServerViewDelegate>
{
    VLCLocalServerDiscoveryController *_discoveryController;

    UIRefreshControl *_refreshControl;
    UIActivityIndicatorView *_activityIndicator;
    UITableView *_localNetworkTableView;
    UITableView *_remoteNetworkTableView;
    UIScrollView *_scrollView;
    VLCRemoteNetworkDataSourceAndDelegate *_remoteNetworkDataSourceAndDelegate;
    NSLayoutConstraint* _localNetworkHeight;
    NSLayoutConstraint* _remoteNetworkHeight;
    MediaLibraryService *_medialibraryService;
}

@end

@implementation VLCServerListViewController

#if TARGET_OS_IOS
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    /* the event handler in TabBarCoordinator cannot listen to the system because the movie view controller blocks the event
     * Therefore, we need to check the current theme ourselves */
    if (@available(iOS 13.0, *)) {
        if (previousTraitCollection.userInterfaceStyle == self.traitCollection.userInterfaceStyle) {
            return;
        }

        if ([[NSUserDefaults standardUserDefaults] integerForKey:kVLCSettingAppTheme] == kVLCSettingAppThemeSystem) {
            [PresentationTheme themeDidUpdate];
        }
        [self themeDidChange];
    }
}

#endif

- (instancetype)initWithMedialibraryService:(MediaLibraryService *)medialibraryService
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _medialibraryService = medialibraryService;
        [self setupUI];
    }
    return self;
}

- (void)loadView
{
    [super loadView];

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_scrollView];

    [NSLayoutConstraint activateConstraints:@[
                                              [_scrollView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
                                              [_scrollView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
                                              [_scrollView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor],
                                              [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
                                              ]];

    _remoteNetworkDataSourceAndDelegate = [VLCRemoteNetworkDataSourceAndDelegate new];
    _remoteNetworkDataSourceAndDelegate.delegate = self;

    CGRect screenDimensions = [UIScreen mainScreen].bounds;

    _localNetworkTableView = [[UITableView alloc] initWithFrame:screenDimensions style:UITableViewStylePlain];
    _localNetworkTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _localNetworkTableView.delegate = self;
    _localNetworkTableView.dataSource = self;
    _localNetworkTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _localNetworkTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _localNetworkTableView.rowHeight = [VLCNetworkListCell heightOfCell];
    _localNetworkTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _localNetworkTableView.estimatedRowHeight = [VLCNetworkListCell heightOfCell];

    [self.navigationController.navigationBar setTranslucent:NO];

    _remoteNetworkTableView = [[UITableView alloc] initWithFrame:screenDimensions style:UITableViewStylePlain];
    _remoteNetworkTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _remoteNetworkTableView.delegate = _remoteNetworkDataSourceAndDelegate;
    _remoteNetworkTableView.dataSource = _remoteNetworkDataSourceAndDelegate;
    _remoteNetworkTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _remoteNetworkTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _remoteNetworkTableView.bounces = NO;
    _remoteNetworkTableView.scrollEnabled = NO;
    _remoteNetworkTableView.rowHeight = UITableViewAutomaticDimension;
    _remoteNetworkTableView.estimatedRowHeight = 80.0;

    VLCFileServerView *fileServerView = [VLCFileServerView new];
    fileServerView.translatesAutoresizingMaskIntoConstraints = NO;
    fileServerView.delegate = self;

    [_remoteNetworkTableView registerClass:[VLCWiFiUploadTableViewCell class] forCellReuseIdentifier:[VLCWiFiUploadTableViewCell cellIdentifier]];
    [_remoteNetworkTableView registerClass:[VLCRemoteNetworkCell class] forCellReuseIdentifier:VLCRemoteNetworkCell.cellIdentifier];
    [_remoteNetworkTableView registerClass:[VLCExternalMediaProviderCell class] forCellReuseIdentifier:VLCExternalMediaProviderCell.cellIdentifier];

    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.tintColor = [UIColor whiteColor];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [_localNetworkTableView addSubview:_refreshControl];

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.center = _localNetworkTableView.center;
    _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _activityIndicator.hidesWhenStopped = YES;
    [_localNetworkTableView addSubview:_activityIndicator];

    [_scrollView addSubview:_localNetworkTableView];
    [_scrollView addSubview:fileServerView];
    [_scrollView addSubview:_remoteNetworkTableView];

    _localNetworkHeight = [_localNetworkTableView.heightAnchor constraintEqualToConstant:_localNetworkTableView.contentSize.height];
    _remoteNetworkHeight = [_remoteNetworkTableView.heightAnchor constraintEqualToConstant:_remoteNetworkTableView.contentSize.height];

    [NSLayoutConstraint activateConstraints:@[
                                              [_remoteNetworkTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
                                              [_remoteNetworkTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
                                              [_remoteNetworkTableView.topAnchor constraintEqualToAnchor:_scrollView.topAnchor],
                                              [fileServerView.topAnchor constraintEqualToAnchor:_remoteNetworkTableView.bottomAnchor],
                                              [fileServerView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
                                              [fileServerView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
                                              [_localNetworkTableView.topAnchor constraintEqualToAnchor:fileServerView.bottomAnchor],
                                              [_localNetworkTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
                                              [_localNetworkTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
                                              [_localNetworkTableView.bottomAnchor constraintEqualToAnchor:_scrollView.bottomAnchor],
                                              _localNetworkHeight,
                                              _remoteNetworkHeight
                                              ]];
}

- (void)setupUI
{
    self.title = NSLocalizedString(@"NETWORK", nil);
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle: NSLocalizedString(@"NETWORK", nil)
                                                    image: [UIImage imageNamed:@"Network"]
                                            selectedImage: [UIImage imageNamed:@"Network"]];
    self.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.localNetwork;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    _remoteNetworkHeight.constant = _remoteNetworkTableView.contentSize.height;
    _localNetworkHeight.constant = _localNetworkTableView.contentSize.height;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = NO;
    }
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(themeDidChange) name:kVLCThemeDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(contentSizeDidChange) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(boxSessionUpdated) name:VLCBoxControllerSessionUpdated object:nil];
    [notificationCenter addObserver:self selector:@selector(miniPlayerIsShown)
                               name:VLCPlayerDisplayControllerDisplayMiniPlayer object:nil];
    [notificationCenter addObserver:self selector:@selector(miniPlayerIsHidden)
                               name:VLCPlayerDisplayControllerHideMiniPlayer object:nil];

    [self themeDidChange];
    NSArray *browserClasses = @[
                                [VLCLocalNetworkServiceBrowserUPnP class],
                                [VLCLocalNetworkServiceBrowserPlex class],
                                [VLCLocalNetworkServiceBrowserHTTP class],
                                [VLCLocalNetworkServiceBrowserDSM class],
                                [VLCLocalNetworkServiceBrowserBonjour class],
                                [VLCLocalNetworkServiceBrowserNFS class],
                                ];

    _discoveryController = [[VLCLocalServerDiscoveryController alloc] initWithServiceBrowserClasses:browserClasses];
    _discoveryController.delegate = self;

    [self configureCloudControllers];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_activityIndicator stopAnimating];

    [_discoveryController stopDiscovery];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    VLCPlaybackService.sharedInstance.playerDisplayController.isMiniPlayerVisible
    ? [self miniPlayerIsShown] : [self miniPlayerIsHidden];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_remoteNetworkTableView reloadData];
        [self->_discoveryController startDiscovery];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    _remoteNetworkHeight.constant = _remoteNetworkTableView.contentSize.height;
    _localNetworkHeight.constant = _localNetworkTableView.contentSize.height;
}

- (void)miniPlayerIsShown
{
    _localNetworkTableView.contentInset = UIEdgeInsetsMake(0, 0,
                                                           VLCAudioMiniPlayer.height, 0);
}

- (void)miniPlayerIsHidden
{
    _localNetworkTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

- (void)contentSizeDidChange
{
    [_localNetworkTableView layoutIfNeeded];
    _localNetworkHeight.constant = _localNetworkTableView.contentSize.height;
    [_remoteNetworkTableView layoutIfNeeded];
    _remoteNetworkHeight.constant = _remoteNetworkTableView.contentSize.height;
}

- (void)connectToServer
{
    VLCNetworkLoginViewController *loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCNetworkLoginViewController" bundle:nil];

    loginViewController.loginInformation = [[VLCNetworkServerLoginInformation alloc] init];;
    loginViewController.delegate = self;
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    navCon.modalPresentationStyle = UIModalPresentationFormSheet;
    [navCon.navigationBar setTranslucent:NO];
    [self presentViewController:navCon animated:YES completion:nil];

    if (loginViewController.navigationItem.leftBarButtonItem == nil)
        loginViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_dismissLogin)];
}

- (void)configureCloudControllers
{
    VLCBoxController *boxController = [VLCBoxController sharedInstance];
    // Start Box session on init to check whether it is logged in or not as soon as possible
    [boxController startSession];

    // Configure Dropbox
    [DBClientsManager setupWithAppKey:kVLCDropboxAppKey];

    // Configure OneDrive
    [ODClient setMicrosoftAccountAppId:kVLCOneDriveClientID scopes:@[@"onedrive.readwrite", @"offline_access"]];
}

- (void)boxSessionUpdated
{
    __weak typeof(self) weakSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf->_remoteNetworkTableView reloadData];
    });
}

#pragma mark - table view handling

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _discoveryController.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_discoveryController numberOfItemsInSection:section];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    ColorPalette *themeColors = PresentationTheme.current.colors;
    cell.titleLabel.textColor = cell.folderTitleLabel.textColor = cell.thumbnailView.tintColor = themeColors.cellTextColor;
    cell.subtitleLabel.textColor = themeColors.cellDetailTextColor;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalNetworkCell";

    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    id<VLCLocalNetworkService> service = [_discoveryController networkServiceForIndexPath:indexPath];

    [cell setIsDirectory:YES];
    if ([service respondsToSelector:@selector(iconURL)]) {
        [cell setIconURL:service.iconURL];
    }
    if (cell.iconURL == nil)
        [cell setIcon:service.icon];
    [cell setTitle:service.title];
    [cell setTitleLabelCentered:NO];
    [cell setSubtitle:service.serviceName];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    id<VLCLocalNetworkService> service = [_discoveryController networkServiceForIndexPath:indexPath];

    if ([service respondsToSelector:@selector(serverBrowser)]) {
        id<VLCNetworkServerBrowser> serverBrowser = [service serverBrowser];
        if (serverBrowser) {
            VLCNetworkServerBrowserViewController *vc = [[VLCNetworkServerBrowserViewController alloc]
                                                         initWithServerBrowser:serverBrowser
                                                         medialibraryService:_medialibraryService];
            [self.navigationController pushViewController:vc animated:YES];
            return;
        }
    }

    if ([service respondsToSelector:@selector(directPlaybackURL)]) {
        NSURL *playbackURL = [service directPlaybackURL];
        if (playbackURL) {
            VLCMediaList *medialist = [[VLCMediaList alloc] init];
            [medialist addMedia:[VLCMedia mediaWithURL:playbackURL]];
            [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
            return;
        }
    }

    VLCNetworkServerLoginInformation *login;
    if ([service respondsToSelector:@selector(loginInformation)]) {
        login = [service loginInformation];
    } else {
        APLog(@"%s: no login information, class %@", __func__, NSStringFromClass([service class]));
    }

    /* UPnP does not support authentication, so skip this step */
    if ([login.protocolIdentifier isEqualToString:VLCNetworkServerProtocolIdentifierUPnP]) {
        VLCNetworkServerBrowserVLCMedia *serverBrowser = [VLCNetworkServerBrowserVLCMedia UPnPNetworkServerBrowserWithLogin:login];
        VLCNetworkServerBrowserViewController *vc = [[VLCNetworkServerBrowserViewController alloc]
                                                     initWithServerBrowser:serverBrowser
                                                     medialibraryService:_medialibraryService];
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }

    [login loadLoginInformationFromKeychainWithError:nil];

    VLCNetworkLoginViewController *loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCNetworkLoginViewController" bundle:nil];

    loginViewController.loginInformation = login;
    loginViewController.delegate = self;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:loginViewController];
        navCon.navigationBarHidden = NO;
        navCon.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navCon animated:YES completion:nil];

        if (loginViewController.navigationItem.leftBarButtonItem == nil) {
            loginViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                                    initWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                                    style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(_dismissLogin)];
        }
    } else {
        [self.navigationController pushViewController:loginViewController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalNetworkCell";

    VLCNetworkListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        return UITableViewAutomaticDimension;
    }

    CGFloat size = 0.0;

    size += cell.titleLabel.font.lineHeight;
    size += cell.subtitleLabel.font.lineHeight;
    size += cell.folderTitleLabel.font.lineHeight;

    if (size != 0) {
        return size + cell.edgePadding + (cell.interItemPadding * 2);
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (void)showViewController:(UIViewController *)viewController
{
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)showDocumentPickerViewController:(UIDocumentPickerViewController *)viewControllerToPresent
{
    viewControllerToPresent.delegate = self;
    [self presentViewController:viewControllerToPresent animated:YES completion:nil];
}

- (void)reloadRemoteTableView
{
    [_remoteNetworkTableView reloadData];
    [_remoteNetworkTableView layoutIfNeeded];
    _remoteNetworkHeight.constant = _remoteNetworkTableView.contentSize.height;
}

#pragma mark -
- (void)themeDidChange
{
    ColorPalette *colors = PresentationTheme.current.colors;
    _localNetworkTableView.backgroundColor = colors.background;
    _remoteNetworkTableView.backgroundColor = colors.background;
    _scrollView.backgroundColor = colors.background;
    _localNetworkTableView.separatorColor = colors.background;
    _refreshControl.backgroundColor = colors.background;
    self.navigationController.view.backgroundColor = colors.background;
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *navigationBarAppearance = [VLCAppearanceManager navigationbarAppearance];
        self.navigationController.navigationBar.standardAppearance = navigationBarAppearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance;
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)_dismissLogin
{
    if ([self.navigationController presentedViewController]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return PresentationTheme.current.colors.statusBarStyle;
}

#pragma mark - Refresh

- (void)handleRefresh
{
    //set the title while refreshing
    _refreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:NSLocalizedString(@"LOCAL_SERVER_REFRESH",nil)];
    //set the date and time of refreshing
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc]init];
    [formattedDate setDateFormat:@"MMM d, h:mm a"];
    NSString *lastupdated = [NSString stringWithFormat:NSLocalizedString(@"LOCAL_SERVER_LAST_UPDATE",nil),[formattedDate stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastupdated attributes:attrsDictionary];
    //end the refreshing

    if ([_discoveryController refreshDiscoveredData])
        [_localNetworkTableView reloadData];

    [_refreshControl endRefreshing];
}

#pragma mark - VLCNetworkLoginViewControllerDelegate

- (void)loginWithLoginViewController:(VLCNetworkLoginViewController *)loginViewController loginInfo:(VLCNetworkServerLoginInformation *)loginInformation
{
    id<VLCNetworkServerBrowser> serverBrowser = nil;
    NSString *identifier = loginInformation.protocolIdentifier;

    if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierFTP]) {
        serverBrowser = [VLCNetworkServerBrowserVLCMedia FTPNetworkServerBrowserWithLogin:loginInformation];
    } else if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierPlex]) {
        serverBrowser = [[VLCNetworkServerBrowserPlex alloc] initWithLogin:loginInformation];
    } else if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierSMB]) {
        serverBrowser = [VLCNetworkServerBrowserVLCMedia SMBNetworkServerBrowserWithLogin:loginInformation];
    } else if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierNFS]) {
        serverBrowser = [VLCNetworkServerBrowserVLCMedia NFSNetworkServerBrowserWithLogin:loginInformation];
    } else if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierSFTP]) {
        serverBrowser = [VLCNetworkServerBrowserVLCMedia SFTPNetworkServerBrowserWithLogin:loginInformation];
    } else {
        APLog(@"Unsupported URL Scheme requested %@", identifier);
    }

    if (serverBrowser) {
        VLCNetworkServerBrowserViewController *targetViewController = [[VLCNetworkServerBrowserViewController alloc]
                                                                       initWithServerBrowser:serverBrowser
                                                                       medialibraryService:_medialibraryService];
        [self.navigationController pushViewController:targetViewController animated:YES];
    }
}

- (void)discoveryFoundSomethingNew
{
    [_localNetworkTableView reloadData];
    [_localNetworkTableView layoutIfNeeded];
    _localNetworkHeight.constant = _localNetworkTableView.contentSize.height;
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    if (url && [url startAccessingSecurityScopedResource]) {
        VLCMediaList *medialist = [[VLCMediaList alloc] init];
        [medialist addMedia:[VLCMedia mediaWithURL:url]];
        [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
        [[VLCPlaybackService sharedInstance].openedLocalURLs addObject:url];
    }
}

@end
