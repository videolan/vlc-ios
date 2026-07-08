/*****************************************************************************
 * VLCTransferViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCTransferViewController.h"
#import "VLCTransferController.h"
#import "VLCAppCoordinator.h"
#import "VLCActiveDownloadCell.h"
#import "NSString+SupportedMedia.h"
#import "VLC-Swift.h"

@interface VLCTransferViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    VLCTransferController *_transferController;
    NSArray<VLCTransferItem *> *_inProgress;
    NSArray<VLCTransferItem *> *_completed;
    NSArray<VLCTransferItem *> *_failed;
    NSDateFormatter *_dateFormatter;
}
@property (strong, nonatomic) UITextField *urlField;
@property (strong, nonatomic) UIButton *downloadButton;
@property (strong, nonatomic) UIButton *fieldClearButton;
@property (strong, nonatomic) UITableView *downloadsTable;
@end

@implementation VLCTransferViewController

- (void)loadView
{
    self.view = [[UIView alloc] init];

    UIView *fieldsContainer = [[UIView alloc] init];
    fieldsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:fieldsContainer];

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
    urlField.keyboardType = UIKeyboardTypeURL;
    urlField.layer.cornerRadius = 10.0;
    urlField.layer.borderWidth = 1.0;
    urlField.delegate = self;
    urlField.textContentType = UITextContentTypeURL;
    [urlField addTarget:self action:@selector(updateFieldAccessories) forControlEvents:UIControlEventEditingChanged | UIControlEventEditingDidBegin | UIControlEventEditingDidEnd];
    [fieldsContainer addSubview:urlField];
    self.urlField = urlField;

    UIView *leftPadding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 30)];
    urlField.leftView = leftPadding;
    urlField.leftViewMode = UITextFieldViewModeAlways;

    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold];
        [downloadButton setImage:[UIImage systemImageNamed:@"arrow.down.to.line" withConfiguration:cfg] forState:UIControlStateNormal];
    } else {
        [downloadButton setImage:[[UIImage imageNamed:@"download"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    downloadButton.accessibilityLabel = NSLocalizedString(@"BUTTON_DOWNLOAD", nil);
    [downloadButton setAccessibilityIdentifier:@"Download"];
    [downloadButton addTarget:self action:@selector(downloadAction:) forControlEvents:UIControlEventTouchUpInside];
    downloadButton.frame = CGRectMake(0, 0, 38, 38);
    downloadButton.layer.cornerRadius = 8.0;
    self.downloadButton = downloadButton;

    UIButton *fieldClearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [fieldClearButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    }
    fieldClearButton.accessibilityLabel = NSLocalizedString(@"BUTTON_RESET", nil);
    [fieldClearButton addTarget:self action:@selector(clearURLField) forControlEvents:UIControlEventTouchUpInside];
    fieldClearButton.frame = CGRectMake(0, 4, 30, 30);
    fieldClearButton.hidden = YES;
    self.fieldClearButton = fieldClearButton;

    UIView *rightContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 38 + 7, 38)];
    [rightContainer addSubview:fieldClearButton];
    [rightContainer addSubview:downloadButton];
    urlField.rightView = rightContainer;
    urlField.rightViewMode = UITextFieldViewModeAlways;

    UITableView *downloadsTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    downloadsTable.translatesAutoresizingMaskIntoConstraints = NO;
    downloadsTable.alwaysBounceVertical = YES;
    downloadsTable.showsHorizontalScrollIndicator = NO;
    downloadsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    downloadsTable.estimatedSectionHeaderHeight = 44;
    if (@available(iOS 15.0, *)) {
        downloadsTable.sectionHeaderTopPadding = 0;
    }
    downloadsTable.dataSource = self;
    downloadsTable.delegate = self;
    [self.view addSubview:downloadsTable];
    self.downloadsTable = downloadsTable;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

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

        [downloadsTable.topAnchor constraintEqualToAnchor:fieldsContainer.bottomAnchor],
        [downloadsTable.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [downloadsTable.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [downloadsTable.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
    ]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _transferController = [VLCAppCoordinator sharedInstance].transferController;
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.dateStyle = NSDateFormatterShortStyle;
    _dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    _inProgress = @[];
    _completed = @[];
    _failed = @[];

    self.title = NSLocalizedString(@"TRANSFERS", comment:@"");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    if (@available(iOS 26.0, *)) {
    } else {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(updateForTheme) name:kVLCThemeDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(transferStateDidChange:) name:VLCTransferControllerStateDidChangeNotification object:nil];

    [self updateForTheme];
}

- (void)viewWillAppear:(BOOL)animated
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if ([pasteboard containsPasteboardTypes:@[@"public.url"]]) {
        id pasteboardValue = [pasteboard valueForPasteboardType:@"public.url"];
        if ([pasteboardValue respondsToSelector:@selector(absoluteString)]) {
            self.urlField.text = [pasteboardValue absoluteString];
        }
    }
    [self _reloadTransfers];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)updateForTheme
{
    ColorPalette *colors = PresentationTheme.current.colors;
    NSMutableParagraphStyle *placeholderParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    placeholderParagraphStyle.alignment = NSTextAlignmentNatural;
    NSAttributedString *coloredAttributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"http://myserver.com/file.mkv", nil)
                                                                                       attributes:@{NSForegroundColorAttributeName: colors.textfieldPlaceholderColor, NSParagraphStyleAttributeName: placeholderParagraphStyle}];
    self.urlField.attributedPlaceholder = coloredAttributedPlaceholder;
    self.urlField.backgroundColor = colors.cellBackgroundB;
    self.urlField.textColor = colors.cellTextColor;
    self.urlField.layer.borderColor = colors.textfieldBorderColor.CGColor;
    self.downloadButton.backgroundColor = colors.orangeUI;
    self.downloadButton.tintColor = [UIColor whiteColor];
    [self.downloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.fieldClearButton.tintColor = colors.textfieldPlaceholderColor;
    self.downloadsTable.backgroundColor = colors.background;
    self.view.backgroundColor = colors.background;
    [self.downloadsTable reloadData];
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

    const CGFloat downloadSize = 38, clearSize = 30, gap = 6, trailingPad = 7;
    UIView *container = self.downloadButton.superview;
    if (showClear) {
        self.downloadButton.frame = CGRectMake(clearSize + gap, 0, downloadSize, downloadSize);
        container.frame = CGRectMake(0, 0, clearSize + gap + downloadSize + trailingPad, downloadSize);
    } else {
        self.downloadButton.frame = CGRectMake(0, 0, downloadSize, downloadSize);
        container.frame = CGRectMake(0, 0, downloadSize + trailingPad, downloadSize);
    }
    self.urlField.rightView = container;
}

- (void)downloadAction:(id)sender
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

    NSString *urlString = [self.urlField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if ([urlString length] > 0) {
        NSURL *URLtoSave = [NSURL URLWithString:urlString];
        NSString *lastPathComponent = URLtoSave.lastPathComponent;
        NSString *scheme = URLtoSave.scheme;
        if (!([lastPathComponent isSupportedFormat] || [lastPathComponent isSupportedPlaylistFormat]) && ![lastPathComponent.pathExtension isEqualToString:@""]) {
            [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil)
                                                 errorMessage:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), lastPathComponent]
                                               viewController:self];
            return;
        }
        if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"] && ![scheme isEqualToString:@"ftp"]) {
            [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"SCHEME_NOT_SUPPORTED", nil)
                                                 errorMessage:[NSString stringWithFormat:NSLocalizedString(@"SCHEME_NOT_SUPPORTED_LONG", nil), URLtoSave.scheme]
                                               viewController:self];
            return;
        }
        [[ParentalControlCoordinator sharedInstance] authorizeIfParentalControlIsEnabledWithAction:^{
            VLCMedia *media = [VLCMedia mediaWithURL:URLtoSave];
            [self->_transferController addVLCMediaToDownloadList:media fileNameOfMedia:lastPathComponent];
            self.urlField.text = @"";
            [self updateFieldAccessories];
        } fail:nil];
    }
}

- (void)_reloadTransfers
{
    _inProgress = _transferController.inProgressItems;
    _completed = _transferController.completedItems;
    _failed = _transferController.failedItems;
    [self.downloadsTable reloadData];
}

#pragma mark - transfer controller updates
- (void)transferStateDidChange:(NSNotification *)notification
{
    NSArray<VLCTransferItem *> *newInProgress = _transferController.inProgressItems;
    NSArray<VLCTransferItem *> *newCompleted = _transferController.completedItems;
    NSArray<VLCTransferItem *> *newFailed = _transferController.failedItems;

    BOOL structureChanged = newInProgress.count != _inProgress.count
                            || newCompleted.count != _completed.count
                            || newFailed.count != _failed.count;

    _inProgress = newInProgress;
    _completed = newCompleted;
    _failed = newFailed;

    if (structureChanged) {
        [self.downloadsTable reloadData];
        return;
    }

    for (NSInteger row = 0; row < (NSInteger)_inProgress.count; row++) {
        VLCTransferItem *item = _inProgress[row];
        if (!item.active) {
            continue;
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        VLCActiveDownloadCell *cell = (VLCActiveDownloadCell *)[self.downloadsTable cellForRowAtIndexPath:indexPath];
        cell.progressKnown = item.sizeKnown;
        if (item.sizeKnown) {
            cell.progress = item.progress;
        }
        cell.statsText = item.statsText;
    }
}

#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return _inProgress.count;
    } else if (section == 1) {
        return _completed.count;
    }
    return _failed.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ColorPalette *colors = PresentationTheme.current.colors;
    NSInteger row = indexPath.row;

    if (indexPath.section == 0) {
        VLCTransferItem *item = _inProgress[row];

        if (item.active) {
            static NSString *ActiveCellID = @"ActiveDownloadCell";
            VLCActiveDownloadCell *activeCell = (VLCActiveDownloadCell *)[tableView dequeueReusableCellWithIdentifier:ActiveCellID];
            if (activeCell == nil) {
                activeCell = [[VLCActiveDownloadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ActiveCellID];
            }
            [activeCell applyTheme];
            activeCell.name = item.displayName;
            activeCell.progressKnown = item.sizeKnown;
            activeCell.statsText = item.statsText;
            if (item.sizeKnown) {
                activeCell.progress = item.progress;
            }
            return activeCell;
        }

        UITableViewCell *cell = [self _plainCellForTableView:tableView];
        cell.textLabel.text = item.displayName;
        cell.detailTextLabel.text = item.urlString;
        cell.imageView.image = nil;
        cell.textLabel.textColor = colors.cellTextColor;
        cell.detailTextLabel.textColor = colors.cellDetailTextColor;
        cell.detailTextLabel.numberOfLines = 1;
        return cell;
    }

    UITableViewCell *cell = [self _plainCellForTableView:tableView];

    NSString *sfSymbolName;
    NSString *fallbackImageName;
    UIColor *tintColor;
    NSString *name;
    if (indexPath.section == 1) {
        VLCTransferItem *item = _completed[row];
        name = item.displayName;
        sfSymbolName = @"checkmark.circle.fill";
        fallbackImageName = @"checkmark";
        tintColor = [UIColor systemGreenColor];
        cell.detailTextLabel.text = item.date ? [_dateFormatter stringFromDate:item.date] : @"";
        cell.detailTextLabel.numberOfLines = 1;
    } else {
        VLCTransferItem *item = _failed[row];
        name = item.displayName;
        sfSymbolName = @"exclamationmark.triangle.fill";
        fallbackImageName = @"warning";
        tintColor = [UIColor systemRedColor];
        cell.detailTextLabel.text = item.errorDescription;
        cell.detailTextLabel.numberOfLines = 2;
        cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }

    if (@available(iOS 13.0, *)) {
        UIImage *symbol = [UIImage systemImageNamed:sfSymbolName];
        cell.imageView.image = [symbol imageWithTintColor:tintColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    } else {
        cell.imageView.image = [[UIImage imageNamed:fallbackImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.imageView.tintColor = tintColor;
    }
    cell.textLabel.text = name;
    cell.textLabel.textColor = colors.cellTextColor;
    cell.detailTextLabel.textColor = colors.cellDetailTextColor;

    return cell;
}

- (UITableViewCell *)_plainCellForTableView:(UITableView *)tableView
{
    static NSString *CellIdentifier = @"ScheduledDownloadsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.detailTextLabel.numberOfLines = 1;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && _inProgress[indexPath.row].active) {
        return 96;
    }
    return 60;
}

- (NSString *)_titleForSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"TRANSFERS_IN_PROGRESS", nil);
    } else if (section == 1) {
        return NSLocalizedString(@"DOWNLOADS_SECTION_COMPLETED", nil);
    }
    return NSLocalizedString(@"TRANSFER_FAILED", nil);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return nil;
    }

    UIView *header = [[UIView alloc] init];
    header.backgroundColor = PresentationTheme.current.colors.background;

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    UIFontDescriptor *descriptor = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleTitle2]
                                    fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    label.font = [UIFont fontWithDescriptor:descriptor size:0];
    label.adjustsFontForContentSizeCategory = YES;
    label.text = [self _titleForSection:section];
    label.textColor = PresentationTheme.current.colors.lightTextColor;
    [header addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:header.trailingAnchor constant:-20],
        [label.topAnchor constraintEqualToAnchor:header.topAnchor constant:12],
        [label.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-6],
    ]];

    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSInteger count = [self tableView:tableView numberOfRowsInSection:section];
    return count == 0 ? 0. : UITableViewAutomaticDimension;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = PresentationTheme.current.colors.cellBackgroundA;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        VLCTransferItem *item = _inProgress[indexPath.row];
        return !(item.active && item.direction == VLCTransferDirectionUpload);
    }
    return indexPath.section == 2;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    if (indexPath.section == 0) {
        [_transferController cancelInProgressItem:_inProgress[indexPath.row]];
    } else if (indexPath.section == 2) {
        [_transferController removeFailedItem:_failed[indexPath.row]];
    }
    [self _reloadTransfers];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        return;
    }
    if (indexPath.section == 2) {
        VLCTransferItem *item = _failed[indexPath.row];
        NSString *name = item.displayName;
        NSString *err = item.errorDescription;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:(name.length ? name : NSLocalizedString(@"TRANSFER_FAILED", nil))
                                                                       message:(err.length ? err : NSLocalizedString(@"TRANSFER_FAILED", nil))
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    VLCTransferItem *item = _completed[indexPath.row];
    NSString *mediaPath = item.filePath;
    if (mediaPath.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:mediaPath]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:(item.displayName.length ? item.displayName : NSLocalizedString(@"TRANSFERS", nil))
                                                                       message:NSLocalizedString(@"DOWNLOAD_FILE_UNAVAILABLE", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    VLCMedia *media = [VLCMedia mediaWithPath:mediaPath];
    VLCMediaList *mediaList = [[VLCMediaList alloc] initWithArray:@[media]];
    [VLCPlaybackService.sharedInstance playMediaList:mediaList firstIndex:0 subtitlesFilePath:nil];
}

#pragma mark - text view delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.urlField resignFirstResponder];
    return NO;
}

@end
