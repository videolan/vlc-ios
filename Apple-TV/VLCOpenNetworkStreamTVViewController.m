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
#import "CAAnimation+VLCWiggle.h"

@interface VLCOpenNetworkStreamTVViewController ()
{
    NSMutableArray *_recentURLs;
}
@property (nonatomic) NSIndexPath *currentlyFocusedIndexPath;
@end

@implementation VLCOpenNetworkStreamTVViewController

- (NSString *)title
{
    return NSLocalizedString(@"NETWORK_TITLE", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.nothingFoundLabel.text = NSLocalizedString(@"NO_RECENT_STREAMS", nil);

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(ubiquitousKeyValueStoreDidChange:)
                               name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                             object:[NSUbiquitousKeyValueStore defaultStore]];

    self.playURLField.placeholder = NSLocalizedString(@"ENTER_URL", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
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
}

- (void)ubiquitousKeyValueStoreDidChange:(NSNotification *)notification
{
    /* TODO: don't blindly trust that the Cloud knows best */
    _recentURLs = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:kVLCRecentURLs]];
    [self.previouslyPlayedStreamsTableView reloadData];
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
    NSInteger count = _recentURLs.count;
    self.nothingFoundView.hidden = count > 0;
    return count;
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentlyFocusedIndexPath = indexPath;
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

#pragma mark - editing

- (NSIndexPath *)indexPathToDelete
{
    NSIndexPath *indexPathToDelete = self.currentlyFocusedIndexPath;
    return indexPathToDelete;
}

- (NSString *)itemToDelete
{
    NSIndexPath *indexPathToDelete = self.indexPathToDelete;
    if (!indexPathToDelete) {
        return nil;
    }

    NSString *ret;
    @synchronized(_recentURLs) {
        ret = _recentURLs[indexPathToDelete.item];
    }
    return ret;
}

- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];

    UITableViewCell *focusedCell = [self.previouslyPlayedStreamsTableView cellForRowAtIndexPath:self.currentlyFocusedIndexPath];
    if (editing) {
        [focusedCell.layer addAnimation:[CAAnimation vlc_wiggleAnimation]
                                 forKey:VLCWiggleAnimationKey];
    } else {
        [focusedCell.layer removeAnimationForKey:VLCWiggleAnimationKey];
    }
}

- (void)deleteFileAtIndex:(NSIndexPath *)indexPathToDelete
{
    if (!indexPathToDelete) {
        return;
    }
    @synchronized(_recentURLs) {
        [_recentURLs removeObjectAtIndex:indexPathToDelete.row];
    }
    [[NSUbiquitousKeyValueStore defaultStore] setArray:_recentURLs forKey:kVLCRecentURLs];

    [self.previouslyPlayedStreamsTableView reloadData];
}

@end
