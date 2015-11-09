/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOpenNetworkStreamTVViewController.h"
#import "VLCPlaybackController.h"
#import "VLCPlayerDisplayController.h"
#import "VLCFullscreenMovieTVViewController.h"
#import "Reachability.h"
#import "VLCHTTPUploaderController.h"

@interface VLCOpenNetworkStreamTVViewController ()
{
    NSMutableArray *_recentURLs;
    UILabel *_noURLsToShowLabel;
    Reachability *_reachability;
}
@end

@implementation VLCOpenNetworkStreamTVViewController

- (NSString *)title
{
    return NSLocalizedString(@"OPEN_NETWORK", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _reachability = [Reachability reachabilityForLocalWiFi];
    self.httpServerLabel.textColor = [UIColor VLCDarkBackgroundColor];

    _noURLsToShowLabel = [[UILabel alloc] init];
    _noURLsToShowLabel.text = NSLocalizedString(@"NO_RECENT_STREAMS", nil);
    _noURLsToShowLabel.textAlignment = NSTextAlignmentCenter;
    _noURLsToShowLabel.textColor = [UIColor VLCLightTextColor];
    _noURLsToShowLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    [_noURLsToShowLabel sizeToFit];
    [_noURLsToShowLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:_noURLsToShowLabel];

    NSLayoutConstraint *yConstraint = [NSLayoutConstraint constraintWithItem:_noURLsToShowLabel
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:yConstraint];
    NSLayoutConstraint *xConstraint = [NSLayoutConstraint constraintWithItem:_noURLsToShowLabel
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:xConstraint];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(ubiquitousKeyValueStoreDidChange:)
                               name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                             object:[NSUbiquitousKeyValueStore defaultStore]];
    [notificationCenter addObserver:self
                           selector:@selector(reachabilityChanged)
                               name:kReachabilityChangedNotification
                             object:nil];

    /* force store update */
    NSUbiquitousKeyValueStore *ubiquitousKeyValueStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousKeyValueStore synchronize];

    /* fetch data from cloud */
    _recentURLs = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:kVLCRecentURLs]];
#ifndef NDEBUG
    if (_recentURLs.count == 0) {
        [_recentURLs addObject:@"http://streams.videolan.org/streams/mp4/Mr_MrsSmith-h264_aac.mp4"];
        [_recentURLs addObject:@"http://streams.videolan.org/streams/mp4/Mr&MrsSmith.txt"];
    }
#endif
    [self.previouslyPlayedStreamsTableView reloadData];
    _noURLsToShowLabel.hidden = _recentURLs.count != 0;
    self.playURLField.placeholder = NSLocalizedString(@"ENTER_URL", nil);
}

- (void)ubiquitousKeyValueStoreDidChange:(NSNotification *)notification
{
    /* TODO: don't blindly trust that the Cloud knows best */
    _recentURLs = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:kVLCRecentURLs]];
    [self.previouslyPlayedStreamsTableView reloadData];
    _noURLsToShowLabel.hidden = _recentURLs.count != 0;
}

- (void)reachabilityChanged
{
    [self updateHTTPServerAddress];
}

- (void)updateHTTPServerAddress
{
    BOOL connectedViaWifi = _reachability.currentReachabilityStatus == ReachableViaWiFi;
    self.toggleHTTPServerButton.enabled = connectedViaWifi;
    NSString *uploadText = connectedViaWifi ? [[VLCHTTPUploaderController sharedInstance] httpStatus] : NSLocalizedString(@"HTTP_UPLOAD_NO_CONNECTIVITY", nil);
    self.httpServerLabel.text = uploadText;
    if (connectedViaWifi && [VLCHTTPUploaderController sharedInstance].isServerRunning)
        [self.toggleHTTPServerButton setTitle:NSLocalizedString(@"HTTP_SERVER_ON", nil) forState:UIControlStateNormal];
    else
        [self.toggleHTTPServerButton setTitle:NSLocalizedString(@"HTTP_SERVER_OFF", nil) forState:UIControlStateNormal];
}

- (void)toggleHTTPServer:(id)sender
{
    BOOL futureHTTPServerState = ![VLCHTTPUploaderController sharedInstance].isServerRunning ;
    [[NSUserDefaults standardUserDefaults] setBool:futureHTTPServerState forKey:kVLCSettingSaveHTTPUploadServerStatus];
    [[VLCHTTPUploaderController sharedInstance] changeHTTPServerState:futureHTTPServerState];
    [self updateHTTPServerAddress];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_reachability startNotifier];
    [self updateHTTPServerAddress];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_reachability stopNotifier];

    /* force update before we leave */
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecentlyPlayedURLsTableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"RecentlyPlayedURLsTableViewCell"];
    }

    NSString *content = _recentURLs[indexPath.row];
    cell.textLabel.text = [content lastPathComponent];
    cell.detailTextLabel.text = content;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.previouslyPlayedStreamsTableView deselectRowAtIndexPath:indexPath animated:NO];
    [self _openURLStringAndDismiss:_recentURLs[indexPath.row]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _recentURLs.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)URLEnteredInField:(id)sender
{
    [self _openURLStringAndDismiss:self.playURLField.text];
}

- (void)_openURLStringAndDismiss:(NSString *)url
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    [vpc playURL:[NSURL URLWithString:url] subtitlesFilePath:nil];
    [self presentViewController:[VLCFullscreenMovieTVViewController fullscreenMovieTVViewController]
                       animated:YES
                     completion:nil];
}

@end
