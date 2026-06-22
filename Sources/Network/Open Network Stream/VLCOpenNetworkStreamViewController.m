/*****************************************************************************
 * VLCOpenNetworkStreamViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2026 VideoLAN. All rights reserved.
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
#import "VLCMediaList+M3U.h"

@interface VLCOpenNetworkStreamViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, VLCStreamingHistoryCellMenuItemProtocol>
{
    NSMutableArray *_recentURLs;
    NSMutableDictionary *_recentURLTitles;
}

@property (strong, nonatomic) UITextField *urlField;
@property (strong, nonatomic) UIButton *openButton;
@property (strong, nonatomic) UIButton *fieldClearButton;
@property (strong, nonatomic) UIButton *privateToggleButton;
@property (strong, nonatomic) UITableView *historyTableView;
@property (strong, nonatomic) UILabel *recentsHeaderLabel;
@property (strong, nonatomic) UIButton *clearButton;
@property (strong, nonatomic) UIButton *shareButton;

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
    /* Only paste while we are actually the front-most UI */
    UIWindow *window = self.viewIfLoaded.window;
    if (window == nil || window.rootViewController.presentedViewController != nil)
        return;

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

- (void)loadView
{
    UIView *root = [[UIView alloc] init];
    root.backgroundColor = [UIColor clearColor];
    self.view = root;

    UIView *fieldsContainer = [[UIView alloc] init];
    fieldsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:fieldsContainer];

    UILayoutGuide *contentGuide = [[UILayoutGuide alloc] init];
    [fieldsContainer addLayoutGuide:contentGuide];

    UITextField *urlField = [[UITextField alloc] init];
    urlField.translatesAutoresizingMaskIntoConstraints = NO;
    urlField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    urlField.adjustsFontForContentSizeCategory = YES;
    urlField.textAlignment = NSTextAlignmentNatural;
    urlField.clearButtonMode = UITextFieldViewModeNever;
    urlField.autocorrectionType = UITextAutocorrectionTypeNo;
    urlField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    urlField.keyboardAppearance = UIKeyboardAppearanceAlert;
    urlField.layer.cornerRadius = 10.0;
    urlField.layer.borderWidth = 1.0;
    [urlField addTarget:self action:@selector(updateFieldAccessories) forControlEvents:UIControlEventEditingChanged | UIControlEventEditingDidBegin | UIControlEventEditingDidEnd];
    [fieldsContainer addSubview:urlField];
    self.urlField = urlField;

    UIButton *privateToggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightMedium];
        [privateToggleButton setImage:[UIImage systemImageNamed:@"eye.slash" withConfiguration:cfg] forState:UIControlStateNormal];
    }
    privateToggleButton.accessibilityLabel = NSLocalizedString(@"PRIVATE_PLAYBACK_TOGGLE", nil);
    [privateToggleButton addTarget:self action:@selector(privatePlaybackToggled:) forControlEvents:UIControlEventTouchUpInside];
    privateToggleButton.frame = CGRectMake(10, 0, 30, 30);
    self.privateToggleButton = privateToggleButton;

    UIView *leftContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10 + 30 + 4, 30)];
    [leftContainer addSubview:privateToggleButton];
    urlField.leftView = leftContainer;
    urlField.leftViewMode = UITextFieldViewModeAlways;

    UIButton *openButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold];
        [openButton setImage:[UIImage systemImageNamed:@"arrow.right" withConfiguration:cfg] forState:UIControlStateNormal];
    }
    [openButton addTarget:self action:@selector(openButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    openButton.frame = CGRectMake(0, 0, 38, 38);
    openButton.layer.cornerRadius = 8.0;
    self.openButton = openButton;

    UIButton *fieldClearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [fieldClearButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    }
    fieldClearButton.accessibilityLabel = NSLocalizedString(@"BUTTON_RESET", nil);
    [fieldClearButton addTarget:self action:@selector(clearURLField) forControlEvents:UIControlEventTouchUpInside];
    fieldClearButton.frame = CGRectMake(0, 4, 30, 30);
    fieldClearButton.hidden = YES;
    self.fieldClearButton = fieldClearButton;

    UIView *openContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 38 + 7, 38)];
    [openContainer addSubview:fieldClearButton];
    [openContainer addSubview:openButton];
    urlField.rightView = openContainer;
    urlField.rightViewMode = UITextFieldViewModeAlways;

    UILabel *recentsHeaderLabel = [[UILabel alloc] init];
    recentsHeaderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    UIFontDescriptor *headerDescriptor = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleTitle2]
                                          fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    recentsHeaderLabel.font = [UIFont fontWithDescriptor:headerDescriptor size:0];
    recentsHeaderLabel.adjustsFontForContentSizeCategory = YES;
    recentsHeaderLabel.text = NSLocalizedString(@"RECENT_STREAMS", nil);
    [root addSubview:recentsHeaderLabel];
    self.recentsHeaderLabel = recentsHeaderLabel;

    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        UIImage *icon = [UIImage systemImageNamed:@"xmark.bin"] ?: [UIImage systemImageNamed:@"trash"];
        [clearButton setImage:icon forState:UIControlStateNormal];
    } else {
        [clearButton setImage:[UIImage imageNamed:@"trash"] forState:UIControlStateNormal];
    }
    clearButton.accessibilityLabel = NSLocalizedString(@"BUTTON_RESET", nil);
    [clearButton addTarget:self action:@selector(emptyListAction:) forControlEvents:UIControlEventTouchUpInside];
    [root addSubview:clearButton];
    self.clearButton = clearButton;

    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
    shareButton.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        [shareButton setImage:[UIImage systemImageNamed:@"square.and.arrow.up"] forState:UIControlStateNormal];
    } else {
        [shareButton setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
    }
    shareButton.accessibilityLabel = NSLocalizedString(@"SHARE_LABEL", nil);
    [shareButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
    [root addSubview:shareButton];
    self.shareButton = shareButton;

    UITableView *historyTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    historyTableView.translatesAutoresizingMaskIntoConstraints = NO;
    historyTableView.alwaysBounceVertical = YES;
    historyTableView.showsHorizontalScrollIndicator = NO;
    historyTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    historyTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    historyTableView.dataSource = self;
    historyTableView.delegate = self;
    [root addSubview:historyTableView];
    self.historyTableView = historyTableView;

    UILayoutGuide *safe = root.safeAreaLayoutGuide;

    NSLayoutConstraint *contentGuidePreferredWidth = [contentGuide.widthAnchor constraintEqualToConstant:480];
    contentGuidePreferredWidth.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [fieldsContainer.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [fieldsContainer.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [fieldsContainer.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],

        [contentGuide.centerXAnchor constraintEqualToAnchor:fieldsContainer.centerXAnchor],
        [contentGuide.leadingAnchor constraintGreaterThanOrEqualToAnchor:fieldsContainer.leadingAnchor constant:20],
        [contentGuide.trailingAnchor constraintLessThanOrEqualToAnchor:fieldsContainer.trailingAnchor constant:-20],
        contentGuidePreferredWidth,

        [urlField.topAnchor constraintEqualToAnchor:fieldsContainer.topAnchor constant:14],
        [urlField.leadingAnchor constraintEqualToAnchor:contentGuide.leadingAnchor],
        [urlField.trailingAnchor constraintEqualToAnchor:contentGuide.trailingAnchor],
        [urlField.heightAnchor constraintGreaterThanOrEqualToConstant:50],
        [fieldsContainer.bottomAnchor constraintEqualToAnchor:urlField.bottomAnchor constant:14],

        [recentsHeaderLabel.topAnchor constraintEqualToAnchor:fieldsContainer.bottomAnchor constant:20],
        [recentsHeaderLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:20],
        [recentsHeaderLabel.trailingAnchor constraintLessThanOrEqualToAnchor:clearButton.leadingAnchor constant:-8],

        [shareButton.lastBaselineAnchor constraintEqualToAnchor:recentsHeaderLabel.lastBaselineAnchor],
        [shareButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-20],
        [shareButton.widthAnchor constraintGreaterThanOrEqualToConstant:44],
        [shareButton.heightAnchor constraintGreaterThanOrEqualToConstant:44],

        [clearButton.lastBaselineAnchor constraintEqualToAnchor:shareButton.lastBaselineAnchor],
        [clearButton.heightAnchor constraintEqualToAnchor:shareButton.heightAnchor],
        [clearButton.trailingAnchor constraintEqualToAnchor:shareButton.leadingAnchor constant:-24],
        [clearButton.widthAnchor constraintGreaterThanOrEqualToConstant:44],

        [historyTableView.topAnchor constraintEqualToAnchor:shareButton.bottomAnchor constant:10],
        [historyTableView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [historyTableView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [historyTableView.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
    ]];
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

    self.openButton.accessibilityLabel = NSLocalizedString(@"BUTTON_OPEN", nil);
    [self.openButton setAccessibilityIdentifier:@"Open Network Stream"];
    self.title = NSLocalizedString(@"OPEN_NETWORK", comment: "");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

    self.urlField.delegate = self;
    self.urlField.keyboardType = UIKeyboardTypeURL;
    if (@available(iOS 10.0, *)) {
        self.urlField.textContentType = UITextContentTypeURL;
    }

    if (@available(iOS 26.0, *)) {
    } else {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

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

    [self _setRightBarButtonItemsEditing:NO];
}

- (void)updateForTheme
{
    ColorPalette *colors = PresentationTheme.current.colors;
    self.historyTableView.backgroundColor = colors.background;
    self.view.backgroundColor = colors.background;
    NSMutableParagraphStyle *placeholderParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    placeholderParagraphStyle.alignment = NSTextAlignmentNatural;
    NSAttributedString *coloredAttributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"http://myserver.com/file.mkv", nil)
                                                                                       attributes:@{NSForegroundColorAttributeName: colors.textfieldPlaceholderColor, NSParagraphStyleAttributeName: placeholderParagraphStyle}];
    self.urlField.attributedPlaceholder = coloredAttributedPlaceholder;
    self.urlField.backgroundColor = colors.cellBackgroundB;
    self.urlField.textColor = colors.cellTextColor;
    self.urlField.layer.borderColor = colors.textfieldBorderColor.CGColor;
    self.recentsHeaderLabel.textColor = colors.lightTextColor;
    self.openButton.backgroundColor = colors.orangeUI;
    self.openButton.tintColor = [UIColor whiteColor];
    self.fieldClearButton.tintColor = colors.textfieldPlaceholderColor;
    [self updatePrivateToggleColor];
    self.shareButton.tintColor = colors.orangeUI;
    self.clearButton.tintColor = colors.orangeUI;
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
    [self updatePrivateToggleColor];

    self.historyTableView.editing = NO;
    [self _setRightBarButtonItemsEditing:NO];

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

- (void)privatePlaybackToggled:(UIButton *)sender
{
    sender.selected = !sender.selected;
    [self updatePrivateToggleColor];
}

- (void)updatePrivateToggleColor
{
    ColorPalette *colors = PresentationTheme.current.colors;
    self.privateToggleButton.tintColor = self.privateToggleButton.selected ? colors.orangeUI : colors.lightTextColor;
}

- (void)clearURLField
{
    self.urlField.text = @"";
    [self updateFieldAccessories];
}

- (void)updateFieldAccessories
{
    BOOL showClear = self.urlField.isEditing && self.urlField.text.length > 0;
    if (showClear == !self.fieldClearButton.hidden) {
        return;
    }
    self.fieldClearButton.hidden = !showClear;

    const CGFloat openSize = 38, clearSize = 30, gap = 6, trailingPad = 7;
    UIView *container = self.openButton.superview;
    if (showClear) {
        self.openButton.frame = CGRectMake(clearSize + gap, 0, openSize, openSize);
        container.frame = CGRectMake(0, 0, clearSize + gap + openSize + trailingPad, openSize);
    } else {
        self.openButton.frame = CGRectMake(0, 0, openSize, openSize);
        container.frame = CGRectMake(0, 0, openSize + trailingPad, openSize);
    }
    self.urlField.rightView = container;
}

- (void)openButtonAction:(id)sender
{
    if (self.urlField.text.length == 0 && ![self.urlField isFirstResponder]) {
        [self.urlField becomeFirstResponder];

        if (UIAccessibilityIsReduceMotionEnabled()) {
            return;
        }

        ColorPalette *colors = PresentationTheme.current.colors;
        self.urlField.layer.borderColor = colors.orangeUI.CGColor;

        [UIView animateWithDuration:0.12 animations:^{
            self.urlField.transform = CGAffineTransformMakeScale(1.02, 1.02);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.20 delay:0.05 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.urlField.transform = CGAffineTransformIdentity;
            } completion:^(BOOL done) {
                self.urlField.layer.borderColor = colors.textfieldBorderColor.CGColor;
            }];
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
            NSUInteger oldIndex = [_recentURLs indexOfObject:urlString];
            if (oldIndex != NSNotFound) {
                [_recentURLs removeObjectAtIndex:oldIndex];
                [_recentURLs addObject:urlString];
                [self _shiftTitleKeysForMoveFrom:oldIndex to:_recentURLs.count - 1];
            } else {
                [_recentURLs addObject:urlString];
            }
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
    BOOL wasEditing = self.historyTableView.editing;
    [self.historyTableView setEditing:!wasEditing animated:YES];
    [self _setRightBarButtonItemsEditing:!wasEditing];
}

- (void)emptyListAction:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"RESET_NETWORK_STREAM_LIST_TITLE", nil)
                                                                             message:NSLocalizedString(@"RESET_NETWORK_STREAM_LIST_TEXT", nil)
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_RESET", nil)
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action){
        self->_recentURLs = [NSMutableArray array];
        self->_recentURLTitles = [NSMutableDictionary dictionary];
        [self _saveData];
        [self.historyTableView reloadData];
        [self updateEditButtonState];
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
        NSInteger deletedRow = indexPath.row;
        [_recentURLs removeObjectAtIndex:deletedRow];

        NSMutableDictionary *shiftedTitles = [NSMutableDictionary dictionaryWithCapacity:_recentURLTitles.count];
        [_recentURLTitles enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *title, BOOL *stop) {
            NSInteger row = key.integerValue;
            if (row < deletedRow) {
                shiftedTitles[key] = title;
            } else if (row > deletedRow) {
                shiftedTitles[@(row - 1).stringValue] = title;
            }
        }];
        _recentURLTitles = shiftedTitles;

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

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                               title:NSLocalizedString(@"BUTTON_DELETE", nil)
                                                                             handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
        completionHandler(YES);
    }];
    if (@available(iOS 13.0, *)) {
        deleteAction.image = [UIImage systemImageNamed:@"trash"];
    }

    UIContextualAction *renameAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                               title:NSLocalizedString(@"BUTTON_RENAME", nil)
                                                                             handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell != nil) {
            [self renameStreamFromCell:cell];
        }
        completionHandler(YES);
    }];
    renameAction.backgroundColor = PresentationTheme.current.colors.lightTextColor;
    if (@available(iOS 13.0, *)) {
        renameAction.image = [UIImage systemImageNamed:@"pencil"];
    }

    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, renameAction]];
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView
contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
                                    point:(CGPoint)point API_AVAILABLE(ios(13.0))
{
    return [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                    previewProvider:nil
                                                     actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
        UIAction *copy = [UIAction actionWithTitle:NSLocalizedString(@"BUTTON_COPY", nil)
                                              image:[UIImage systemImageNamed:@"doc.on.doc"]
                                         identifier:nil
                                            handler:^(__kindof UIAction *action) {
            [UIPasteboard generalPasteboard].string = self->_recentURLs[indexPath.row];
        }];
        UIAction *rename = [UIAction actionWithTitle:NSLocalizedString(@"BUTTON_RENAME", nil)
                                                image:[UIImage systemImageNamed:@"pencil"]
                                           identifier:nil
                                              handler:^(__kindof UIAction *action) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if (cell != nil) {
                [self renameStreamFromCell:cell];
            }
        }];
        UIAction *editURL = [UIAction actionWithTitle:NSLocalizedString(@"BUTTON_EDIT", nil)
                                                 image:[UIImage systemImageNamed:@"link"]
                                            identifier:nil
                                               handler:^(__kindof UIAction *action) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if (cell != nil) {
                [self editURLFromCell:cell];
            }
        }];
        UIAction *del = [UIAction actionWithTitle:NSLocalizedString(@"BUTTON_DELETE", nil)
                                              image:[UIImage systemImageNamed:@"trash"]
                                         identifier:nil
                                            handler:^(__kindof UIAction *action) {
            [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
        }];
        del.attributes = UIMenuElementAttributesDestructive;
        return [UIMenu menuWithTitle:@"" children:@[copy, rename, editURL, del]];
    }];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSString *stringURL = _recentURLs[sourceIndexPath.row];
    [_recentURLs removeObjectAtIndex:sourceIndexPath.row];
    [_recentURLs insertObject:stringURL atIndex:destinationIndexPath.row];
    [self _shiftTitleKeysForMoveFrom:sourceIndexPath.row to:destinationIndexPath.row];
    [self _saveData];
}

- (void)_shiftTitleKeysForMoveFrom:(NSInteger)source to:(NSInteger)destination
{
    if (source == destination) return;
    NSInteger delta = source < destination ? -1 : 1;
    NSInteger lo = MIN(source, destination);
    NSInteger hi = MAX(source, destination);
    NSMutableDictionary *shifted = [NSMutableDictionary dictionaryWithCapacity:_recentURLTitles.count];
    [_recentURLTitles enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *title, BOOL *stop) {
        NSInteger row = key.integerValue;
        if (row == source) {
            row = destination;
        } else if (row >= lo && row <= hi) {
            row += delta;
        }
        shifted[@(row).stringValue] = title;
    }];
    _recentURLTitles = shifted;
}

#pragma mark - internals

- (void)_setRightBarButtonItemsEditing:(BOOL)editing
{
    NSString *title = editing ? NSLocalizedString(@"BUTTON_DONE", nil) : NSLocalizedString(@"BUTTON_EDIT", nil);
    UIBarButtonItemStyle style = editing ? UIBarButtonItemStyleDone : UIBarButtonItemStylePlain;
    UIBarButtonItem *toggleItem = [[UIBarButtonItem alloc] initWithTitle:title
                                                                   style:style
                                                                  target:self
                                                                  action:@selector(editTableView:)];
    toggleItem.tintColor = PresentationTheme.current.colors.orangeUI;
    self.navigationItem.rightBarButtonItems = @[toggleItem];
    self.shareButton.hidden = editing;
    self.clearButton.hidden = editing;
}

- (void)shareAction:(id)sender
{
    if (_recentURLs.count == 0) {
        return;
    }

    VLCMediaList *mediaList = [[VLCMediaList alloc] init];
    NSInteger count = _recentURLs.count;
    for (NSInteger i = 0; i < count; i++) {
        NSString *urlString = _recentURLs[i];
        NSURL *url = [NSURL URLWithString:urlString];
        if (url == nil) {
            continue;
        }
        VLCMedia *media = [VLCMedia mediaWithURL:url];
        NSString *renamedTitle = _recentURLTitles[@(i).stringValue];
        if (renamedTitle.length > 0) {
            media.metaData.title = renamedTitle;
        }
        [mediaList addMedia:media];
    }

    NSString *fileName = [NSLocalizedString(@"RECENT_STREAMS", nil) stringByAppendingPathExtension:@"m3u"];
    NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:fileName];
    // we might have crashed in the past and left a file over, remove it
    [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];

    NSError *error = nil;
    if (![mediaList writeM3UToURL:tempURL error:&error]) {
        APLog(@"Failed to write M3U for sharing: %@", error);
        return;
    }

    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[tempURL]
                                                                             applicationActivities:nil];
    UIView *anchor = self.shareButton;
    activityVC.popoverPresentationController.sourceView = anchor;
    activityVC.popoverPresentationController.sourceRect = anchor.bounds;
    activityVC.completionWithItemsHandler = ^(UIActivityType activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
    };
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)updateEditButtonState
{
    BOOL hasItems = _recentURLs.count > 0;
    if (!hasItems && self.historyTableView.editing) {
        [self.historyTableView setEditing:NO animated:YES];
        [self _setRightBarButtonItemsEditing:NO];
    }
    for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems) {
        item.enabled = hasItems;
    }
    self.shareButton.enabled = hasItems;
    self.clearButton.enabled = hasItems;
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
