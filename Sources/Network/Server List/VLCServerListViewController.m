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
 *          Eshan Singh <eeeshan789@gmail.com>
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

#if TARGET_OS_IOS
#import "VLCBoxController.h"
#import <OneDriveSDK.h>
#import "VLCOneDriveConstants.h"
#import "VLCDropboxConstants.h"
#endif

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
    UIDocumentPickerViewController *_documentPicker;
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
        [_scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    _remoteNetworkDataSourceAndDelegate = [VLCRemoteNetworkDataSourceAndDelegate new];
    _remoteNetworkDataSourceAndDelegate.delegate = self;

#if TARGET_OS_VISION
    CGRect screenDimensions = [[[[UIApplication sharedApplication] delegate] window] bounds];
#else
    CGRect screenDimensions = [UIScreen mainScreen].bounds;
#endif

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

#if TARGET_OS_VISION
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _activityIndicator.color = [UIColor whiteColor];
#else
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
#endif
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
    self.title = NSLocalizedString(@"BROWSE", nil);
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle: NSLocalizedString(@"BROWSE", nil)
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
#if TARGET_OS_IOS
    [notificationCenter addObserver:self selector:@selector(boxSessionUpdated) name:VLCBoxControllerSessionUpdated object:nil];
#endif
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

#if TARGET_OS_IOS
    [self configureCloudControllers];
#endif
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
    [super viewDidAppear:animated];
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

#if TARGET_OS_IOS
- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}
#endif

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

#if TARGET_OS_IOS
- (void)configureCloudControllers
{
    VLCBoxController *boxController = [VLCBoxController sharedInstance];
    // Start Box session on init to check whether it is logged in or not as soon as possible
    [boxController startSession];

    // Configure Dropbox
    [DBClientsManager setupWithAppKey:kVLCDropboxAppKey];
    [DBClientsManager authorizedClient];

    // Configure OneDrive
    [ODClient setMicrosoftAccountAppId:kVLCOneDriveClientID scopes:@[@"onedrive.readwrite", @"offline_access"]];

    VLCPCloudController  *controller = [VLCPCloudController pCloudInstance];
    // Start P Cloud session on init to check whether it is logged in or not as soon as possible
    [controller startSession];
}
#endif

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
        VLCNetworkServerBrowserVLCMedia *serverBrowser;
        if (login.rootMedia != nil) {
            serverBrowser = [[VLCNetworkServerBrowserVLCMedia alloc] initWithMedia:login.rootMedia options:login.options];
        } else {
            serverBrowser = [VLCNetworkServerBrowserVLCMedia UPnPNetworkServerBrowserWithLogin:login];
        }
        VLCNetworkServerBrowserViewController *vc = [[VLCNetworkServerBrowserViewController alloc]
                                                     initWithServerBrowser:serverBrowser
                                                     medialibraryService:_medialibraryService];
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }

    NSError *error = nil;
    if (![login loadLoginInformationFromKeychainWithError:&error]) {
        [self showKeychainLoadError:error forLogin:login];
        return;
    }

    VLCNetworkLoginViewController *loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCNetworkLoginViewController" bundle:nil];

    loginViewController.loginInformation = login;
    loginViewController.delegate = self;
#if TARGET_OS_IOS
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
#endif
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
#if TARGET_OS_IOS
    } else {
        [self.navigationController pushViewController:loginViewController animated:YES];
    }
#endif
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

- (void)showKeychainLoadError:(NSError *)error forLogin:(VLCNetworkServerLoginInformation *)login
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                             message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
        [self connectToServer];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showViewController:(UIViewController *)viewController
{
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)showDocumentPickerViewController:(UIDocumentPickerViewController *)viewControllerToPresent
{
    _documentPicker = viewControllerToPresent;
    _documentPicker.delegate = self;

    if (@available(iOS 11.0, *)) {
        _documentPicker.allowsMultipleSelection = YES;
    }

    [self presentViewController:_documentPicker animated:YES completion:nil];
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
#if TARGET_OS_IOS
    [self setNeedsStatusBarAppearanceUpdate];
#endif
}

- (void)_dismissLogin
{
    if ([self.navigationController presentedViewController]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#if TARGET_OS_IOS
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return PresentationTheme.current.colors.statusBarStyle;
}
#endif

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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_localNetworkTableView reloadData];
        [self->_localNetworkTableView layoutIfNeeded];
        self->_localNetworkHeight.constant = self->_localNetworkTableView.contentSize.height;
    });
}

-(void)showEmptyMediaListAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"EMPTY_MEDIA_LIST", "")
                                                                             message:NSLocalizedString(@"EMPTY_MEDIA_LIST_DESCRIPTION", "")
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_DISMISS", "") style:UIAlertActionStyleCancel handler:nil];

    [alertController addAction:dismissAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate

#if TARGET_OS_IOS
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    if (url && [url startAccessingSecurityScopedResource]) {
        VLCMediaList *medialist = [[VLCMediaList alloc] init];
        [medialist addMedia:[VLCMedia mediaWithURL:url]];
        [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
        [[VLCPlaybackService sharedInstance].openedLocalURLs addObject:url];
    }
}
#endif

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    if (urls.count > 0) {
        VLCMediaList *medialist = [[VLCMediaList alloc] init];

        if (urls.count == 1 && [[urls[0] pathExtension] isEqualToString:@""]) {
            [self getFolderData:urls[0] mediaList:medialist];
        } else {
            NSSortDescriptor *urlSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"absoluteString" ascending:YES selector:@selector(localizedStandardCompare:)];
            NSArray<NSURL *> *sortedArray = [urls sortedArrayUsingDescriptors:@[urlSortDescriptor]];
            for (NSURL *url in sortedArray) {
                NSString *pathExtension = [url pathExtension];
                if (![pathExtension isEqualToString:@""]) {
                    if (url && [url startAccessingSecurityScopedResource]) {
                        [medialist addMedia:[VLCMedia mediaWithURL:url]];
                        [[VLCPlaybackService sharedInstance].openedLocalURLs addObject:url];
                    }
                }
            }
        }

        if ([medialist count] > 0) {
            [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
        } else {
            [self showEmptyMediaListAlert];
        }
    }
}

-(void)getFolderData:(NSURL*)url mediaList:(VLCMediaList*) list
{
    NSURL *folderURL = url;
    NSError *error = nil;
    [url startAccessingSecurityScopedResource];
    NSArray<NSURL *> *filesInFolder = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:folderURL
                                                                    includingPropertiesForKeys:@[]
                                                                                       options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                         error:&error];
    if (error) {
        NSLog(@"Error reading directory: %@", error);
        return;
    }

    for (NSURL *fileURL in filesInFolder) {
        if (![fileURL.pathExtension isEqual:@""]) {
            [list addMedia:[VLCMedia mediaWithURL:fileURL]];
            [[VLCPlaybackService sharedInstance].openedLocalURLs addObject:fileURL];
        }
    }
}

@end
