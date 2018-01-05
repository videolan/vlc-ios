/*****************************************************************************
 * VLCBoxTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCBoxTableViewController.h"
#import "VLCCloudStorageTableViewCell.h"
#import "VLCBoxController.h"
#import <XKKeychain/XKKeychainGenericPasswordItem.h>
#import "UIDevice+VLC.h"
#import "VLCPlaybackController.h"

#if TARGET_OS_IOS
@interface VLCBoxTableViewController () <VLCCloudStorageTableViewCell, BoxAuthorizationViewControllerDelegate, VLCCloudStorageDelegate, NSURLConnectionDataDelegate>
#else
@interface VLCBoxTableViewController () <VLCCloudStorageTableViewCell, VLCCloudStorageDelegate, NSURLConnectionDataDelegate>
#endif
{
    BoxFile *_selectedFile;
    VLCBoxController *_boxController;
    NSArray *_listOfFiles;
}

@end

@implementation VLCBoxTableViewController

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        self.currentPath = path;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _boxController = [VLCBoxController sharedInstance];
    self.controller = _boxController;
    self.controller.delegate = self;

#if TARGET_OS_IOS
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Box"]];

    [self.cloudStorageLogo setImage:[UIImage imageNamed:@"Box"]];

    [self.cloudStorageLogo sizeToFit];
    self.cloudStorageLogo.center = self.view.center;
#else
    self.title = @"Box";
#endif

    // Handle logged in
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(boxApiTokenDidRefresh)
                          name:BoxOAuth2SessionDidRefreshTokensNotification
                        object:[BoxSDK sharedSDK].OAuth2Session];

    [defaultCenter addObserver:self
                      selector:@selector(boxApiTokenDidRefresh)
                          name:BoxOAuth2SessionDidBecomeAuthenticatedNotification
                        object:[BoxSDK sharedSDK].OAuth2Session];

#if TARGET_OS_IOS
    // Handle logout
    [defaultCenter addObserver:self
                      selector:@selector(boxDidGetLoggedOut)
                          name:BoxOAuth2SessionDidReceiveAuthenticationErrorNotification
                        object:[BoxSDK sharedSDK].OAuth2Session];
    [defaultCenter addObserver:self
                      selector:@selector(boxDidGetLoggedOut)
                          name:BoxOAuth2SessionDidReceiveRefreshErrorNotification
                        object:[BoxSDK sharedSDK].OAuth2Session];

    [defaultCenter addObserver:self
                      selector:@selector(boxAPIAuthenticationDidFail)
                          name:BoxOAuth2SessionDidReceiveAuthenticationErrorNotification
                        object:[BoxSDK sharedSDK].OAuth2Session];
    [defaultCenter addObserver:self
                      selector:@selector(boxAPIInitiateLogin)
                          name:BoxOAuth2SessionDidReceiveRefreshErrorNotification
                        object:[BoxSDK sharedSDK].OAuth2Session];
#endif
}

#if TARGET_OS_IOS
- (UIViewController *)createAuthController
{
    NSURL *authorizationURL = [[BoxSDK sharedSDK].OAuth2Session authorizeURL];
    NSString *redirectURLString = [[BoxSDK sharedSDK].OAuth2Session redirectURIString];
    BoxAuthorizationViewController *authorizationController = [[BoxAuthorizationViewController alloc] initWithAuthorizationURL:authorizationURL redirectURI:redirectURLString];
    authorizationController.delegate = self;
    return authorizationController;
}
#endif

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _boxController = [VLCBoxController sharedInstance];
    self.controller = _boxController;
    self.controller.delegate = self;

    if (!_listOfFiles || _listOfFiles.count == 0)
        [self requestInformationForCurrentPath];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController == nil) {
        [_boxController stopSession];
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (void)mediaListUpdated
{
    _listOfFiles = [[VLCBoxController sharedInstance].currentListFiles copy];
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (VLCCloudStorageTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"BoxCell";

    VLCCloudStorageTableViewCell *cell = (VLCCloudStorageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCCloudStorageTableViewCell cellWithReuseIdentifier:CellIdentifier];

    NSUInteger index = indexPath.row;
    if (_listOfFiles) {
        if (index < _listOfFiles.count) {
            cell.boxFile = _listOfFiles[index];
            cell.delegate = self;
        }
    }

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _listOfFiles.count;
}

#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row >= _listOfFiles.count)
        return;

    _selectedFile = _listOfFiles[indexPath.row];
    if (![_selectedFile.type isEqualToString:@"folder"])
        [self streamFile:(BoxFile *)_selectedFile];
    else {
        /* dive into subdirectory */
        NSString *path = self.currentPath;
        if (![path isEqualToString:@""])
            path = [path stringByAppendingString:@"/"];
        path = [path stringByAppendingString:_selectedFile.modelID];

        self.currentPath = path;
        [self requestInformationForCurrentPath];
    }
}

- (void)streamFile:(BoxFile *)file
{
    /* the Box API requires us to set an HTTP header to get the actual URL:
     * curl -L https://api.box.com/2.0/files/FILE_ID/content -H "Authorization: Bearer ACCESS_TOKEN"
     *
     * ... however, libvlc does not support setting custom HTTP headers, so we are resolving the redirect ourselves with a NSURLConnection
     * and pass the final location to libvlc, which does not require a custom HTTP header */

    NSURL *baseURL = [[[BoxSDK sharedSDK] filesManager] URLWithResource:@"files"
                                                                     ID:file.modelID
                                                            subresource:@"content"
                                                                  subID:nil];

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:baseURL
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                          timeoutInterval:60];

    [urlRequest setValue:[NSString stringWithFormat:@"Bearer %@", [BoxSDK sharedSDK].OAuth2Session.accessToken] forHTTPHeaderField:@"Authorization"];

    NSURLConnection *theTestConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    [theTestConnection start];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if (response != nil) {
        /* we have 1 redirect from the original URL, so as soon as we'd do that,
         * we grab the URL and cancel the connection */
        NSURL *theActualURL = request.URL;

        [connection cancel];

        /* now ask VLC to stream the URL we were just passed */
        VLCMedia *media = [VLCMedia mediaWithURL:theActualURL];
        VLCMediaList *medialist = [[VLCMediaList alloc] init];
        [medialist addMedia:media];
        [[VLCPlaybackController sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
    }

    return request;
}

#if TARGET_OS_IOS
- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell
{
    _selectedFile = _listOfFiles[[self.tableView indexPathForCell:cell].row];

    if (_selectedFile.size.longLongValue < [[UIDevice currentDevice] VLCFreeDiskSpace].longLongValue) {
        /* selected item is a proper file, ask the user if s/he wants to download it */
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DROPBOX_DOWNLOAD", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DROPBOX_DL_LONG", nil), _selectedFile.name, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:NSLocalizedString(@"BUTTON_DOWNLOAD", nil), nil];
        [alert show];
    } else {
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), _selectedFile.name, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [_boxController downloadFileToDocumentFolder:_selectedFile];
    _selectedFile = nil;
}
#endif

#pragma mark - box controller delegate

#pragma mark - BoxAuthorizationViewControllerDelegate

- (void)boxApiTokenDidRefresh
{
    NSString *token = [BoxSDK sharedSDK].OAuth2Session.refreshToken;

    XKKeychainGenericPasswordItem *keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
    keychainItem.service = kVLCBoxService;
    keychainItem.account = kVLCBoxAccount;
    keychainItem.secret.stringValue = token;
    [keychainItem saveWithError:nil];

    NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousStore setString:token forKey:kVLCStoreBoxCredentials];
    [ubiquitousStore synchronize];
    self.authorizationInProgress = YES;
    [self updateViewAfterSessionChange];
    self.authorizationInProgress = NO;
}

#if TARGET_OS_IOS
- (BOOL)authorizationViewController:(BoxAuthorizationViewController *)authorizationViewController shouldLoadReceivedOAuth2RedirectRequest:(NSURLRequest *)request
{
    [[BoxSDK sharedSDK].OAuth2Session performAuthorizationCodeGrantWithReceivedURL:request.URL];
    [self.navigationController popViewControllerAnimated:YES];
    return NO;
}

- (void)authorizationViewControllerDidStartLoading:(BoxAuthorizationViewController *)authorizationViewController
{
    //needs to be implemented
}

- (void)authorizationViewControllerDidFinishLoading:(BoxAuthorizationViewController *)authorizationViewController
{
    //needs to be implemented
}

- (void)boxDidGetLoggedOut
{
    [self performSelectorOnMainThread:@selector(showLoginPanel) withObject:nil waitUntilDone:NO];
}

- (void)boxAPIAuthenticationDidFail
{
    //needs to be implemented
}

- (void)boxAPIInitiateLogin
{
    [self performSelectorOnMainThread:@selector(showLoginPanel) withObject:nil waitUntilDone:NO];
}

- (void)authorizationViewControllerDidCancel:(BoxAuthorizationViewController *)authorizationViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}
#endif

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger currentOffset = scrollView.contentOffset.y;
    NSInteger maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;

    if (maximumOffset - currentOffset <= - self.tableView.rowHeight) {
        if (_boxController.hasMoreFiles && !self.activityIndicator.isAnimating) {
            [self requestInformationForCurrentPath];
        }
    }
}
#pragma mark - login dialog

#if TARGET_OS_IOS
- (IBAction)loginAction:(id)sender
{
    if (![_boxController isAuthorized]) {
        self.authorizationInProgress = YES;
        [self.navigationController pushViewController:[self createAuthController] animated:YES];
    } else {
        [_boxController logout];
    }
}
#endif

@end
