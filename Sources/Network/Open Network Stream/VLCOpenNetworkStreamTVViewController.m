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
#import "VLCPlaybackService.h"
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

    if (@available(tvOS 13.0, *)) {
        self.navigationController.navigationBarHidden = YES;
    }

    self.nothingFoundLabel.text = NSLocalizedString(@"NO_RECENT_STREAMS", nil);

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(ubiquitousKeyValueStoreDidChange:)
                               name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                             object:[NSUbiquitousKeyValueStore defaultStore]];

    self.playURLField.placeholder = NSLocalizedString(@"ENTER_URL", nil);
    if (@available(tvOS 10.0, *)) {
        self.playURLField.textContentType = UITextContentTypeURL;
    }
    self.emptyListButton.accessibilityLabel = NSLocalizedString(@"BUTTON_RESET", nil);

    self.previouslyPlayedStreamsTableView.backgroundColor = [UIColor clearColor];
    self.previouslyPlayedStreamsTableView.rowHeight = UITableViewAutomaticDimension;

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

    if ([self ubiquitousKeyStoreAvailable]) {
        APLog(@"%s: ubiquitous key store is available", __func__);
        /* force store update */
        NSUbiquitousKeyValueStore *ubiquitousKeyValueStore = [NSUbiquitousKeyValueStore defaultStore];
        [ubiquitousKeyValueStore synchronize];

        /* fetch data from cloud */
        _recentURLs = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:kVLCRecentURLs]];
        _recentURLTitles = [NSMutableDictionary dictionaryWithDictionary:[[NSUbiquitousKeyValueStore defaultStore] dictionaryForKey:kVLCRecentURLTitles]];

        /* merge data from local storage (aka legacy VLC versions) */
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *localRecentUrls = [defaults objectForKey:kVLCRecentURLs];
        if (localRecentUrls != nil) {
            if (localRecentUrls.count != 0) {
                [_recentURLs addObjectsFromArray:localRecentUrls];
                [defaults setObject:nil forKey:kVLCRecentURLs];
                [ubiquitousKeyValueStore setArray:_recentURLs forKey:kVLCRecentURLs];
                [ubiquitousKeyValueStore synchronize];
            }
        }
    } else {
        APLog(@"%s: ubiquitous key store is not available", __func__);
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _recentURLs = [NSMutableArray arrayWithArray:[defaults objectForKey:kVLCRecentURLs]];
        _recentURLTitles = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:kVLCRecentURLTitles]];
    }
}

- (BOOL)ubiquitousKeyStoreAvailable
{
    return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
}

- (void)ubiquitousKeyValueStoreDidChange:(NSNotification *)notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(ubiquitousKeyValueStoreDidChange:) withObject:notification waitUntilDone:NO];
        return;
    }

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
    if (count > 0) {
        self.nothingFoundView.hidden = YES;
        self.emptyListButton.hidden = NO;
    }
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
    NSURL *url = [NSURL URLWithString:urlString];

    if (url && url.scheme && url.host) {
        if ([_recentURLs indexOfObject:urlString] != NSNotFound)
            [_recentURLs removeObject:urlString];

        if (_recentURLs.count >= 100)
            [_recentURLs removeLastObject];
        [_recentURLs addObject:urlString];
        if ([self ubiquitousKeyStoreAvailable]) {
            [[NSUbiquitousKeyValueStore defaultStore] setArray:_recentURLs forKey:kVLCRecentURLs];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:_recentURLs forKey:kVLCRecentURLs];
        }

        [self _openURLStringAndDismiss:urlString];

        [_previouslyPlayedStreamsTableView reloadData];
    }
}

- (void)_openURLStringAndDismiss:(NSString *)urlString
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:urlString]];
    VLCMediaList *medialist = [[VLCMediaList alloc] init];
    [medialist addMedia:media];

    [vpc playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
    [self presentViewController:[VLCFullscreenMovieTVViewController fullscreenMovieTVViewController]
                       animated:YES
                     completion:nil];
}

- (void)emptyListAction:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"RESET_NETWORK_STREAM_LIST_TITLE", nil)
                                                                             message:NSLocalizedString(@"RESET_NETWORK_STREAM_LIST_TEXT", nil)
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_RESET", nil)
                                                     style:UIAlertActionStyleDestructive
                                                   handler:^(UIAlertAction *action){
        @synchronized(self->_recentURLs) {
            self->_recentURLs = [NSMutableArray array];
            self->_recentURLTitles = [NSMutableDictionary dictionary];
            [self.previouslyPlayedStreamsTableView reloadData];

            if ([self ubiquitousKeyStoreAvailable]) {
                NSUbiquitousKeyValueStore *ubiquitousKeyValueStore = [NSUbiquitousKeyValueStore defaultStore];
                [ubiquitousKeyValueStore setArray:@[] forKey:kVLCRecentURLs];
                [ubiquitousKeyValueStore setDictionary:@{} forKey:kVLCRecentURLTitles];
                [[NSUbiquitousKeyValueStore defaultStore] synchronize];
            } else {
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:self->_recentURLs forKey:kVLCRecentURLs];
                [userDefaults setObject:self->_recentURLTitles forKey:kVLCRecentURLTitles];
            }
        }
    }];
    [alertController addAction:deleteAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [alertController addAction:cancelAction];
    if ([alertController respondsToSelector:@selector(setPreferredAction:)]) {
        [alertController setPreferredAction:deleteAction];
    }
    [self presentViewController:alertController animated:YES completion:nil];
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

- (void)handlePlayPausePress
{
    if (!self.editing) {
        return;
    }

    NSString *fileToDelete = self.itemToDelete;
    if (fileToDelete == nil) {
        return;
    }

    NSIndexPath *indexPathToDelete = self.indexPathToDelete;

    NSString *title = _recentURLTitles[[@(indexPathToDelete.row) stringValue]];
    if (!title) {
        title = fileToDelete.lastPathComponent;
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *renameAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_RENAME", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
        [self renameCellAtIndex:indexPathToDelete withCurrentTitle:title];
    }];

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_DELETE", nil)
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
        [self deleteFileAtIndex:indexPathToDelete];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
        self.editing = NO;
    }];

    [alertController addAction:renameAction];
    [alertController addAction:deleteAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteFileAtIndex:(NSIndexPath *)indexPathToDelete
{
    [super deleteFileAtIndex:indexPathToDelete];
    if (!indexPathToDelete) {
        return;
    }

    [_recentURLs removeObjectAtIndex:indexPathToDelete.row];
    [_recentURLTitles removeObjectForKey:[@(indexPathToDelete.row) stringValue]];

    if ([self ubiquitousKeyStoreAvailable]) {
        NSUbiquitousKeyValueStore *keyValueStore = [NSUbiquitousKeyValueStore defaultStore];
        [keyValueStore setArray:_recentURLs forKey:kVLCRecentURLs];
        [keyValueStore setDictionary:_recentURLTitles forKey:kVLCRecentURLTitles];
    } else {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:_recentURLs forKey:kVLCRecentURLs];
        [userDefaults setObject:_recentURLTitles forKey:kVLCRecentURLTitles];
    }

    [self.previouslyPlayedStreamsTableView reloadData];
}

- (void)renameCellAtIndex:(NSIndexPath *)indexPath withCurrentTitle:(NSString *)title
{
    NSString *renameTitle = NSLocalizedString(@"BUTTON_RENAME", nil);
    NSString *cancelTitle = NSLocalizedString(@"BUTTON_CANCEL", nil);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:renameTitle
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
        NSString *streamTitle = alertController.textFields.firstObject.text;
        [self renameStreamWithTitle:streamTitle atIndex:indexPath.row];
    }];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = title;

        [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification
                                                          object:textField
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            okAction.enabled = (textField.text.length != 0);
        }];
    }];

    [alertController addAction:cancelAction];
    [alertController addAction:okAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)renameStreamWithTitle:(NSString *)title atIndex:(NSInteger)index
{
    [_recentURLTitles setObject:title forKey:[@(index) stringValue]];
    if ([self ubiquitousKeyStoreAvailable]) {
        [[NSUbiquitousKeyValueStore defaultStore] setDictionary:_recentURLTitles forKey:kVLCRecentURLTitles];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:_recentURLTitles forKey:kVLCRecentURLTitles];
    }

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.previouslyPlayedStreamsTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                             withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

@end
