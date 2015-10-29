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
}
@end

@implementation VLCOpenNetworkStreamTVViewController

- (NSString *)title
{
    return NSLocalizedString(@"OPEN_NETWORK", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(ubiquitousKeyValueStoreDidChange:)
                               name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                             object:[NSUbiquitousKeyValueStore defaultStore]];

    /* force store update */
    NSUbiquitousKeyValueStore *ubiquitousKeyValueStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousKeyValueStore synchronize];

    /* fetch data from cloud */
    _recentURLs = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:kVLCRecentURLs]];
    if (_recentURLs.count == 0) {
        [_recentURLs addObject:@"http://streams.videolan.org/streams/mp4/Mr_MrsSmith-h264_aac.mp4"];
        [_recentURLs addObject:@"http://streams.videolan.org/streams/mp4/Mr&MrsSmith.txt"];
    }
    [self.previouslyPlayedStreamsTableView reloadData];
    self.noURLsToShowLabel.hidden = _recentURLs.count != 0;
    self.playURLField.placeholder = NSLocalizedString(@"ENTER_URL", nil);
}

- (void)ubiquitousKeyValueStoreDidChange:(NSNotification *)notification
{
    /* TODO: don't blindly trust that the Cloud knows best */
    _recentURLs = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:kVLCRecentURLs]];
    [self.previouslyPlayedStreamsTableView reloadData];
    self.noURLsToShowLabel.hidden = _recentURLs.count != 0;
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
