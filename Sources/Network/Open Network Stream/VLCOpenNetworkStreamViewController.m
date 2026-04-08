/*****************************************************************************
 * VLCOpenNetworkStreamViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *          Adam Viaud <mcnight # mcnight.fr>
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOpenNetworkStreamViewController.h"
#import "VLCPlaybackService.h"
#import "VLCStreamingHistoryCell.h"
#import "VLC-Swift.h"
#import "VLCOpenNetworkSubtitlesFinder.h"

@interface VLCOpenNetworkStreamViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, VLCStreamingHistoryCellMenuItemProtocol>
{
    NSMutableArray *_recentURLs;
    NSMutableDictionary *_recentURLTitles;
}
@end

@implementation VLCOpenNetworkStreamViewController

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{kVLCRecentURLs : @[], kVLCRecentURLTitles : @{}, kVLCPrivateWebStreaming : @(NO)};
    [defaults registerDefaults:appDefaults];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self updatePasteboardTextInURLField];
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
    [self.historyTableView reloadData];
    [self updateEditButtonState];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(ubiquitousKeyValueStoreDidChange:)
                               name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                             object:[NSUbiquitousKeyValueStore defaultStore]];

    [notificationCenter addObserver:self
                           selector:@selector(updateForTheme)
                               name:kVLCThemeDidChangeNotification
                             object:nil];

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

    /*
     * Observe changes to the pasteboard so we can automatically paste it into the URL field.
     * Do not use UIPasteboardChangedNotification because we have copy actions that will trigger it on this screen.
     * Instead when the user comes back to the application from the background (or the inactive state by pulling down notification center), update the URL field.
     * Using the 'active' rather than 'foreground' notification for future proofing if iOS ever allows running multiple apps on the same screen (which would allow the pasteboard to be changed without truly backgrounding the app).
     */
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:[UIApplication sharedApplication]];

    self.whatToOpenHelpLabel.backgroundColor = [UIColor clearColor];
    [self.openButton setTitle:NSLocalizedString(@"OPEN_NETWORK", nil) forState:UIControlStateNormal];
    [self.openButton setAccessibilityIdentifier:@"Open Network Stream"];
    self.openButton.layer.cornerRadius = 4.0;
    [self.privateModeLabel setText:NSLocalizedString(@"PRIVATE_PLAYBACK_TOGGLE", nil)];
    [self.scanSubModeLabel setText:NSLocalizedString(@"SCAN_SUBTITLE_TOGGLE", nil)];
    self.title = NSLocalizedString(@"OPEN_NETWORK", comment: "");

    [self.privateToggleButton setImage:[UIImage imageNamed:@"iconCheckbox-checked"] forState:UIControlStateSelected];
    [self.privateToggleButton setImage:[UIImage imageNamed:@"iconCheckbox-empty"] forState:UIControlStateNormal];
    [self.scanSubToggleButton setImage:[UIImage imageNamed:@"iconCheckbox-checked"] forState:UIControlStateSelected];
    [self.scanSubToggleButton setImage:[UIImage imageNamed:@"iconCheckbox-empty"] forState:UIControlStateNormal];

    [self.whatToOpenHelpLabel setText:NSLocalizedString(@"OPEN_NETWORK_HELP", nil)];
    self.urlField.delegate = self;
    self.urlField.keyboardType = UIKeyboardTypeURL;
    if (@available(iOS 10.0, *)) {
        self.urlField.textContentType = UITextContentTypeURL;
    }

    self.edgesForExtendedLayout = UIRectEdgeNone;

    // This will be called every time this VC is opened by the side menu controller
    [self updatePasteboardTextInURLField];

    // Registering a custom menu items for renaming streams and editing their URLs
    UIMenuItem *renameItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_RENAME", nil)
                                                        action:@selector(renameStream:)];
    UIMenuItem *editURLItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_EDIT", nil)
                                                         action:@selector(editURL:)];
    UIMenuController *sharedMenuController = [UIMenuController sharedMenuController];
    [sharedMenuController setMenuItems:@[renameItem,editURLItem]];
    [sharedMenuController update];
    [self updateForTheme];

    self.historyTableView.rowHeight = [VLCStreamingHistoryCell heightOfCell];

    UIBarButtonItem *editButton = [[UIBarButtonItem alloc]
                                   initWithTitle:NSLocalizedString(@"BUTTON_EDIT", nil)
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(editTableView:)];

    self.navigationItem.rightBarButtonItems = @[editButton];
}

- (void)updateForTheme
{
    ColorPalette *colors = PresentationTheme.current.colors;
    self.historyTableView.backgroundColor = colors.background;
    self.view.backgroundColor = colors.background;
    NSMutableParagraphStyle *placeholderParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    placeholderParagraphStyle.alignment = NSTextAlignmentCenter;
    NSAttributedString *coloredAttributedPlaceholder = [[NSAttributedString alloc] initWithString:@"http://myserver.com/file.mkv" attributes:@{NSForegroundColorAttributeName: colors.textfieldPlaceholderColor, NSParagraphStyleAttributeName: placeholderParagraphStyle}];
    self.urlField.attributedPlaceholder = coloredAttributedPlaceholder;
    self.urlField.backgroundColor = colors.mediaCategorySeparatorColor;
    self.urlField.textColor = colors.cellTextColor;
    self.urlBorder.backgroundColor = colors.textfieldBorderColor;
    self.privateModeLabel.textColor = colors.lightTextColor;
    self.scanSubModeLabel.textColor = colors.lightTextColor;
    self.whatToOpenHelpLabel.textColor = colors.lightTextColor;
    self.openButton.backgroundColor = colors.orangeUI;
    self.privateToggleButton.tintColor = colors.orangeUI;
    self.scanSubToggleButton.tintColor = colors.orangeUI;
    for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems) {
        item.tintColor = colors.orangeUI;
    }
#if TARGET_OS_IOS
    [self setNeedsStatusBarAppearanceUpdate];
#endif
}

#if TARGET_OS_IOS
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return PresentationTheme.current.colors.statusBarStyle;
}
#endif

- (void)updatePasteboardTextInURLField
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if ([pasteboard containsPasteboardTypes:@[@"public.url"]])
        self.urlField.text = [[pasteboard valueForPasteboardType:@"public.url"] absoluteString];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.privateToggleButton.selected = [defaults boolForKey:kVLCPrivateWebStreaming];
    self.scanSubToggleButton.selected = [defaults boolForKey:kVLChttpScanSubtitle];

    self.historyTableView.editing = NO;
    UIBarButtonItem *editButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    editButtonItem.title = NSLocalizedString(@"BUTTON_EDIT", nil);
    editButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.rightBarButtonItems = @[editButtonItem];

    [self updateEditButtonState];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:[UIApplication sharedApplication]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.privateToggleButton.selected forKey:kVLCPrivateWebStreaming];
    [defaults setBool:self.scanSubToggleButton.selected forKey:kVLChttpScanSubtitle];
    [self.view endEditing:YES];

    /* force update before we leave */
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];

    [super viewWillDisappear:animated];
}

- (CGSize)preferredContentSize {
    return [self.view sizeThatFits:CGSizeMake(320, 800)];
}

#pragma mark - UI interaction
#if TARGET_OS_IOS
- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}
#endif

- (IBAction)toggleButtonAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
}

- (IBAction)openButtonAction:(id)sender
{
    if (self.urlField.text.length == 0 && ![self.urlField isFirstResponder]) {
        [self.urlField becomeFirstResponder];

        if (UIAccessibilityIsReduceMotionEnabled()) {
            return;
        }

        UIView *highlightView = self.urlBorder ?: self.urlField;
        ColorPalette *colors = PresentationTheme.current.colors;
        UIColor *originalColor = colors.mediaCategorySeparatorColor;
        UIColor *highlightColor = colors.orangeUI;

        [UIView animateWithDuration:0.12 animations:^{
            highlightView.backgroundColor = highlightColor;
            self.urlField.transform = CGAffineTransformMakeScale(1.02, 1.02);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.20 delay:0.05 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                highlightView.backgroundColor = originalColor;
                self.urlField.transform = CGAffineTransformIdentity;
            } completion:nil];
        }];

        return;
    }

    if ([self.urlField.text length] <= 0 || [NSURL URLWithString:self.urlField.text] == nil) {
        [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"URL_NOT_SUPPORTED", nil)
                                             errorMessage:NSLocalizedString(@"PROTOCOL_NOT_SELECTED", nil)
                                           viewController:self];
        return;
    }
    if (!self.privateToggleButton.selected) {
        NSString *urlString = self.urlField.text;
        NSURL *url = [NSURL URLWithString:urlString];

        if (url && url.scheme && url.host) {
            if ([_recentURLs indexOfObject:urlString] != NSNotFound)
                [_recentURLs removeObject:urlString];

            [_recentURLs addObject:urlString];
            [self _saveData];

            [self.historyTableView reloadData];
            [self updateEditButtonState];
        }
    }
    [self.urlField resignFirstResponder];
    [self _openURLStringAndDismiss:self.urlField.text];
}

- (void)editTableView:(id)sender
{
    BOOL editing = self.historyTableView.editing;
    [self.historyTableView setEditing:!editing animated:YES];

    // Find current edit button and construct/reset right buttons
    UIBarButtonItem *editButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    if (!editButtonItem) { return; }

    if (editing) {
        // Leaving editing: set title back to Edit and remove trash button
        editButtonItem.title = NSLocalizedString(@"BUTTON_EDIT", nil);
        editButtonItem.style = UIBarButtonItemStylePlain;
        self.navigationItem.rightBarButtonItems = @[editButtonItem];
    } else {
        // Entering editing: set title to Done and add trash button
        editButtonItem.title = NSLocalizedString(@"BUTTON_DONE", nil);
        editButtonItem.style = UIBarButtonItemStyleDone;

        UIBarButtonItem *resetButton = [self _resetBarButtonItem];

        self.navigationItem.rightBarButtonItems = @[editButtonItem, resetButton];
    }
}

- (void)emptyListAction:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"RESET_NETWORK_STREAM_LIST_TITLE", nil)
                                                                             message:NSLocalizedString(@"RESET_NETWORK_STREAM_LIST_TEXT", nil)
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_RESET", nil)
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action){
        @synchronized (self->_recentURLs) {
            self->_recentURLs = [NSMutableArray array];
            self->_recentURLTitles = [NSMutableDictionary dictionary];
            [self _saveData];
            [self.historyTableView reloadData];
            [self updateEditButtonState];
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

#pragma mark - table view cell delegation

- (void)renameStreamFromCell:(UITableViewCell *)cell {
    NSIndexPath *cellIndexPath = [self.historyTableView indexPathForCell:cell];
    NSInteger row = cellIndexPath.row;
    NSString *streamName = [_recentURLTitles objectForKey:[@(row) stringValue]];
    if (streamName == nil) {
        streamName = [[_recentURLs[row] stringByRemovingPercentEncoding] lastPathComponent];
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"BUTTON_RENAME", nil)
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_RENAME", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
        [self renameStreamWithTitle:alertController.textFields.firstObject.text atIndex:cellIndexPath.row];
    }];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = streamName;
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
    [self _saveData];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.historyTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (void)editURLFromCell:(UITableViewCell *)cell
{
    NSIndexPath *cellIndexPath = [self.historyTableView indexPathForCell:cell];
    NSString *urlString = _recentURLs[cellIndexPath.row];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"BUTTON_EDIT", nil)
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_SAVE", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
        [self updateURL:alertController.textFields.firstObject.text atIndex:cellIndexPath.row];
    }];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = urlString;
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

- (void)updateURL:(NSString *)urlString atIndex:(NSInteger)index
{
    [_recentURLs replaceObjectAtIndex:index withObject:urlString];
    [self _saveData];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.historyTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}


#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _recentURLs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StreamingHistoryCell";

    VLCStreamingHistoryCell *cell = (VLCStreamingHistoryCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = (VLCStreamingHistoryCell *)[VLCStreamingHistoryCell cellWithReuseIdentifier:CellIdentifier];

    NSString *content = [_recentURLs[indexPath.row] stringByRemovingPercentEncoding];
    NSString *possibleTitle = _recentURLTitles[[@(indexPath.row) stringValue]];

    cell.titleLabel.text = possibleTitle ?: [content lastPathComponent];
    cell.subtitleLabel.text = content;
    cell.thumbnailView.image = [UIImage imageNamed:@"serverIcon"];
    cell.delegate = self;
    cell.showsReorderControl = YES;

    return cell;
}

#pragma mark - table view delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_recentURLs removeObjectAtIndex:indexPath.row];
        [_recentURLTitles removeObjectForKey:[@(indexPath.row) stringValue]];

        [self _saveData];

        [tableView endEditing:NO];
        [tableView reloadData];
        [self updateEditButtonState];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.historyTableView deselectRowAtIndexPath:indexPath animated:NO];
    [self _openURLStringAndDismiss:_recentURLs[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView
    performAction:(SEL)action
forRowAtIndexPath:(NSIndexPath *)indexPath
       withSender:(id)sender
{
    NSString *actionText = NSStringFromSelector(action);

    if ([actionText isEqualToString:@"copy:"])
        [UIPasteboard generalPasteboard].string = _recentURLs[indexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView
 canPerformAction:(SEL)action
forRowAtIndexPath:(NSIndexPath *)indexPath
       withSender:(id)sender
{
    NSString *actionText = NSStringFromSelector(action);

    if ([actionText isEqualToString:@"copy:"])
        return YES;

    return NO;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSString *stringURL = _recentURLs[sourceIndexPath.row];
    NSString *titleKey = [@(sourceIndexPath.row) stringValue];
    NSString *title = _recentURLTitles[titleKey];
    [_recentURLs removeObjectAtIndex:sourceIndexPath.row];
    [_recentURLs insertObject:stringURL atIndex:destinationIndexPath.row];
    if (title) {
        [_recentURLTitles removeObjectForKey:titleKey];
        [_recentURLTitles setObject:title forKey:[@(destinationIndexPath.row) stringValue]];
    }
    [self _saveData];
}

#pragma mark - internals

- (UIBarButtonItem *)_resetBarButtonItem
{
    UIImage *resetImage = nil;
    if (@available(iOS 13.0, *)) {
        resetImage = [UIImage systemImageNamed:@"trash"];
    }
    if (!resetImage) {
        resetImage = [UIImage imageNamed:@"trash"];
    }
    UIBarButtonItem *resetButton = [[UIBarButtonItem alloc] initWithImage:resetImage
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(emptyListAction:)];
    resetButton.accessibilityLabel = NSLocalizedString(@"BUTTON_RESET", nil);
    return resetButton;
}

- (void)updateEditButtonState
{
    BOOL hasItems = _recentURLs.count > 0;
    for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems) {
        item.enabled = hasItems;
    }
    if (!hasItems && self.historyTableView.editing) {
        [self.historyTableView setEditing:NO animated:YES];
        UIBarButtonItem *editButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
        editButtonItem.title = NSLocalizedString(@"BUTTON_EDIT", nil);
        editButtonItem.style = UIBarButtonItemStylePlain;
        self.navigationItem.rightBarButtonItems = @[editButtonItem];
    }
}
	
- (void)_openURLStringAndDismiss:(NSString *)url
{
    [[ParentalControlCoordinator sharedInstance] authorizeIfParentalControlIsEnabledWithAction:^{
        NSURL *playbackURL = [NSURL URLWithString:url];

        VLCMedia *media = [VLCMedia mediaWithURL:playbackURL];

        NSUInteger i = [self->_recentURLs indexOfObject: url];
        if (i != NSNotFound) {
            NSString *renamedTitle = self->_recentURLTitles[[@(i) stringValue]];
            if (renamedTitle != nil) {
                media.metaData.title = renamedTitle;
            }
        }

        VLCMediaList *medialist = [[VLCMediaList alloc] init];
        [medialist addMedia:media];
        [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];

        if (self.scanSubToggleButton.selected) {
            [VLCOpenNetworkSubtitlesFinder tryToFindSubtitleOnServerForURL:playbackURL];
        }
    } fail:nil];
}

- (void)_saveData
{
    if ([self ubiquitousKeyStoreAvailable]) {
        NSUbiquitousKeyValueStore *keyValueStore = [NSUbiquitousKeyValueStore defaultStore];
        [keyValueStore setArray:_recentURLs forKey:kVLCRecentURLs];
        [keyValueStore setDictionary:_recentURLTitles forKey:kVLCRecentURLTitles];
        [keyValueStore synchronize];
    } else {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:_recentURLs forKey:kVLCRecentURLs];
        [userDefaults setObject:_recentURLTitles forKey:kVLCRecentURLTitles];
    }
}

#pragma mark - text view delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.urlField resignFirstResponder];
    return NO;
}

@end
