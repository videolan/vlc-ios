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

@interface VLCOpenNetworkStreamTVViewController ()
{
    NSMutableArray *_recentURLs;
    UILabel *_noURLsToShowLabel;
}
@end

@implementation VLCOpenNetworkStreamTVViewController

- (NSString *)title
{
    return NSLocalizedString(@"NETWORK_TITLE", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];

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

    /* force store update */
    NSUbiquitousKeyValueStore *ubiquitousKeyValueStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousKeyValueStore synchronize];

    /* fetch data from cloud */
    _recentURLs = [NSMutableArray arrayWithArray:[ubiquitousKeyValueStore arrayForKey:kVLCRecentURLs]];
#ifndef NDEBUG
    if (_recentURLs.count == 0) {
        [_recentURLs addObject:@"https://www.youtube.com/watch?v=13e2GxpqGPY"];
        [_recentURLs addObject:@"https://vimeo.com/74370512"];
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

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
    NSString *urlString = self.playURLField.text;
    if (urlString.length) {
        if ([_recentURLs indexOfObject:urlString] != NSNotFound)
            [_recentURLs removeObject:urlString];

        if (_recentURLs.count >= 100)
            [_recentURLs removeLastObject];
        [_recentURLs addObject:urlString];
        [[NSUbiquitousKeyValueStore defaultStore] setArray:_recentURLs forKey:kVLCRecentURLs];

        [self _openURLStringAndDismiss:urlString];
    }
}

- (void)_openURLStringAndDismiss:(NSString *)urlString
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    [vpc playURL:[NSURL URLWithString:urlString] subtitlesFilePath:nil];
    [self presentViewController:[VLCFullscreenMovieTVViewController fullscreenMovieTVViewController]
                       animated:YES
                     completion:nil];
}

@end
