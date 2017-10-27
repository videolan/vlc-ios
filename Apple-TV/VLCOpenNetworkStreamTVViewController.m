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
    NSMutableDictionary *_recentURLTitles;
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

    self.previouslyPlayedStreamsTableView.backgroundColor = [UIColor clearColor];

    /* After day 354 of the year, the usual VLC cone is replaced by another cone
     * wearing a Father Xmas hat.
     * Note: this icon doesn't represent an endorsement of The Coca-Cola Company
     * and should not be confused with the idea of religious statements or propagation there off
     */
    NSCalendar *gregorian =
    [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSUInteger dayOfYear = [gregorian ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitYear forDate:[NSDate date]];
    if (dayOfYear >= 354)
        self.nothingFoundConeImageView.image = [UIImage imageNamed:@"xmas-cone"];
}

- (void)viewWillAppear:(BOOL)animated
{
    /* force store update */
    NSUbiquitousKeyValueStore *ubiquitousKeyValueStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousKeyValueStore synchronize];

    /* fetch data from cloud */
    _recentURLs = [NSMutableArray arrayWithArray:[ubiquitousKeyValueStore arrayForKey:kVLCRecentURLs]];
    _recentURLTitles = [NSMutableDictionary dictionaryWithDictionary:[ubiquitousKeyValueStore dictionaryForKey:kVLCRecentURLTitles]];

    [self.previouslyPlayedStreamsTableView reloadData];
    [super viewWillAppear:animated];
}

- (void)ubiquitousKeyValueStoreDidChange:(NSNotification *)notification
{
    /* TODO: don't blindly trust that the Cloud knows best */
    _recentURLs = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:kVLCRecentURLs]];
    _recentURLTitles = [NSMutableDictionary dictionaryWithDictionary:[[NSUbiquitousKeyValueStore defaultStore] dictionaryForKey:kVLCRecentURLTitles]];
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

    NSString *content = [_recentURLs[indexPath.row] stringByRemovingPercentEncoding];
    NSString *possibleTitle = _recentURLTitles[[@(indexPath.row) stringValue]];

    cell.detailTextLabel.text = content;
    cell.textLabel.text = (possibleTitle != nil) ? possibleTitle : [content lastPathComponent];

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
    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:urlString]];
    VLCMediaList *medialist = [[VLCMediaList alloc] init];
    [medialist addMedia:media];

    [vpc playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
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

    NSString *ret = nil;
    @synchronized(_recentURLs) {
        NSInteger index = indexPathToDelete.item;
        if (index < _recentURLs.count) {
            ret = _recentURLs[index];
        }
    }
    return ret;
}

- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];

    UITableViewCell *focusedCell = [self.previouslyPlayedStreamsTableView cellForRowAtIndexPath:self.currentlyFocusedIndexPath];
    if (editing) {
        [focusedCell.layer addAnimation:[CAAnimation vlc_wiggleAnimationwithSoftMode:YES]
                                 forKey:VLCWiggleAnimationKey];
    } else {
        [focusedCell.layer removeAnimationForKey:VLCWiggleAnimationKey];
    }
}

- (void)deleteFileAtIndex:(NSIndexPath *)indexPathToDelete
{
    [super deleteFileAtIndex:indexPathToDelete];
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
