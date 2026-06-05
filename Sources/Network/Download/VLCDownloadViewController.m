/*****************************************************************************
 * VLCDownloadViewController.m
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

#import "VLCDownloadViewController.h"
#import "VLCTransferController.h"
#import "VLCAppCoordinator.h"
#import "VLCActiveDownloadCell.h"
#import "NSString+SupportedMedia.h"
#import "VLC-Swift.h"

@interface VLCDownloadViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    NSLayoutConstraint *_contentViewHeight;
    VLCTransferController *_transferController;
    NSArray<VLCTransferItem *> *_inProgress;
    NSArray<VLCTransferItem *> *_completed;
    NSArray<VLCTransferItem *> *_failed;
    NSDateFormatter *_dateFormatter;
}
@end

@implementation VLCDownloadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForTheme) name:kVLCThemeDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transferStateDidChange:) name:VLCTransferControllerStateDidChangeNotification object:nil];
        self.title = NSLocalizedString(@"TRANSFERS", comment:@"");
        _transferController = [VLCAppCoordinator sharedInstance].transferController;
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterMediumStyle;
        _inProgress = @[];
        _completed = @[];
        _failed = @[];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.downloadButton setTitle:NSLocalizedString(@"BUTTON_DOWNLOAD", nil) forState:UIControlStateNormal];
    [self.downloadButton setAccessibilityIdentifier:@"Download"];
    self.downloadButton.layer.cornerRadius = 4.0;
    self.urlField.delegate = self;
    self.urlField.keyboardType = UIKeyboardTypeURL;
    if (@available(iOS 10.0, *)) {
        self.urlField.textContentType = UITextContentTypeURL;
    }
    self.progressContainer.hidden = YES;
    self.progressContainer.alpha = 0;
    for (NSLayoutConstraint *constraint in self.progressContainer.constraints) {
        if (constraint.firstItem == self.progressContainer && constraint.secondItem == nil && constraint.firstAttribute == NSLayoutAttributeHeight) {
            constraint.constant = 0;
            break;
        }
    }
    self.downloadsTable.hidden = NO;
    self.downloadsTable.separatorStyle = UITableViewCellSeparatorStyleNone;

    _contentViewHeight = [_contentView.heightAnchor constraintGreaterThanOrEqualToConstant:0];
    _contentViewHeight.active = YES;
    [self updateContentViewHeightConstraint];

    self.edgesForExtendedLayout = UIRectEdgeNone;
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

- (void)updateForTheme
{
    ColorPalette *colors = PresentationTheme.current.colors;
    NSMutableParagraphStyle *placeholderParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    placeholderParagraphStyle.alignment = NSTextAlignmentCenter;
    NSAttributedString *coloredAttributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"http://myserver.com/file.mkv", nil)
                                                                                       attributes:@{NSForegroundColorAttributeName: colors.lightTextColor, NSParagraphStyleAttributeName: placeholderParagraphStyle}];
    self.urlField.attributedPlaceholder = coloredAttributedPlaceholder;
    self.urlField.backgroundColor = colors.background;
    self.urlField.textColor = colors.cellTextColor;
    self.urlBorder.backgroundColor = colors.mediaCategorySeparatorColor;
    self.downloadsTable.backgroundColor = colors.background;
    self.view.backgroundColor = colors.background;
    self.downloadButton.backgroundColor = colors.orangeUI;
    self.progressContainer.backgroundColor = colors.background;
    self.currentDownloadLabel.textColor = colors.cellTextColor;
    self.progressPercent.textColor = colors.cellDetailTextColor;
    self.speedRate.textColor = colors.cellDetailTextColor;
    self.timeDL.textColor = colors.cellDetailTextColor;
    self.activityIndicator.color = colors.cellDetailTextColor;
    self.progressView.progressTintColor = colors.orangeUI;
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
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

- (IBAction)downloadAction:(id)sender
{
    if (self.urlField.text.length == 0 && ![self.urlField isFirstResponder]) {
        [self.urlField becomeFirstResponder];

        if (UIAccessibilityIsReduceMotionEnabled()) {
            return;
        }

        UIView *highlightView = self.urlBorder ?: self.urlField;
        UIColor *originalColor = highlightView.backgroundColor;
        UIColor *highlightColor = PresentationTheme.current.colors.orangeUI;

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

    if ([self.urlField.text length] > 0) {
        NSURL *URLtoSave = [NSURL URLWithString:self.urlField.text];
        NSString *lastPathComponent = URLtoSave.lastPathComponent;
        NSString *scheme = URLtoSave.scheme;
        if (!([lastPathComponent isSupportedFormat] || [lastPathComponent isSupportedPlaylistFormat]) && ![lastPathComponent.pathExtension isEqualToString:@""]) {
            [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil)
                                                 errorMessage:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), lastPathComponent]
                                               viewController:self];
            return;
        }
        if (![scheme isEqualToString:@"http"] & ![scheme isEqualToString:@"https"] && ![scheme isEqualToString:@"ftp"]) {
            [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"SCHEME_NOT_SUPPORTED", nil)
                                                 errorMessage:[NSString stringWithFormat:NSLocalizedString(@"SCHEME_NOT_SUPPORTED_LONG", nil), URLtoSave.scheme]
                                               viewController:self];
            return;
        }
        [[ParentalControlCoordinator sharedInstance] authorizeIfParentalControlIsEnabledWithAction:^{
            VLCMedia *media = [VLCMedia mediaWithURL:URLtoSave];
            [self->_transferController addVLCMediaToDownloadList:media fileNameOfMedia:lastPathComponent];
            self.urlField.text = @"";
        } fail:nil];
    }
}

- (void)_reloadTransfers
{
    _inProgress = _transferController.inProgressItems;
    _completed = _transferController.completedItems;
    _failed = _transferController.failedItems;
    [self.downloadsTable reloadData];
    [self updateContentViewHeightConstraint];
}

- (void)updateContentViewHeightConstraint
{
    [_downloadsTable layoutIfNeeded];
    CGFloat progressHeight = _progressContainer.hidden ? 0 : _progressContainer.frame.size.height;
    _contentViewHeight.constant = _downloadFieldContainer.frame.size.height
                                    + progressHeight
                                    + _downloadsTable.contentSize.height;
}

- (IBAction)cancelDownload:(id)sender
{
    [_transferController cancelCurrentDownload];
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
        [self updateContentViewHeightConstraint];
        return;
    }

    // Patch active rows in place: mutating the table while a swipe-to-cancel is
    // in flight triggers an invalid-row-count crash.
    for (NSInteger row = 0; row < (NSInteger)_inProgress.count; row++) {
        VLCTransferItem *item = _inProgress[row];
        if (!item.active) {
            continue;
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        UITableViewCell *cell = [self.downloadsTable cellForRowAtIndexPath:indexPath];
        if (![cell isKindOfClass:[VLCActiveDownloadCell class]]) {
            continue;
        }
        VLCActiveDownloadCell *activeCell = (VLCActiveDownloadCell *)cell;
        activeCell.progressKnown = item.sizeKnown;
        if (item.sizeKnown) {
            activeCell.progress = item.progress;
        }
        activeCell.statsText = item.statsText;
    }
}

#pragma mark - helpers
- (NSAttributedString *)_prefixedTextWithSymbol:(NSString *)symbol color:(UIColor *)symbolColor text:(NSString *)text textColor:(UIColor *)textColor
{
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[symbol stringByAppendingString:@" "]
                                                                               attributes:@{NSForegroundColorAttributeName: symbolColor}];
    [result appendAttributedString:[[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName: textColor}]];
    return result;
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
        cell.textLabel.attributedText = nil;
        cell.textLabel.text = item.displayName;
        cell.detailTextLabel.text = item.urlString;
        cell.imageView.image = nil;
        cell.textLabel.textColor = colors.cellTextColor;
        cell.detailTextLabel.textColor = colors.cellDetailTextColor;
        cell.detailTextLabel.numberOfLines = 1;
        return cell;
    }

    UITableViewCell *cell = [self _plainCellForTableView:tableView];
    cell.imageView.image = nil;

    if (indexPath.section == 1) {
        VLCTransferItem *item = _completed[row];
        NSString *name = item.displayName;
        cell.detailTextLabel.text = item.date ? [_dateFormatter stringFromDate:item.date] : @"";
        cell.detailTextLabel.numberOfLines = 1;
        if (@available(iOS 13.0, *)) {
            UIImage *check = [UIImage systemImageNamed:@"checkmark.circle.fill"];
            cell.imageView.image = [check imageWithTintColor:[UIColor systemGreenColor] renderingMode:UIImageRenderingModeAlwaysOriginal];
            cell.textLabel.attributedText = nil;
            cell.textLabel.text = name;
            cell.textLabel.textColor = colors.cellTextColor;
        } else {
            cell.textLabel.attributedText = [self _prefixedTextWithSymbol:@"✔" color:[UIColor systemGreenColor] text:(name ?: @"") textColor:colors.cellTextColor];
        }
        cell.detailTextLabel.textColor = colors.cellDetailTextColor;
    } else {
        VLCTransferItem *item = _failed[row];
        NSString *name = item.displayName;
        cell.detailTextLabel.text = item.errorDescription;
        if (@available(iOS 13.0, *)) {
            UIImage *warn = [UIImage systemImageNamed:@"exclamationmark.triangle.fill"];
            cell.imageView.image = [warn imageWithTintColor:[UIColor systemRedColor] renderingMode:UIImageRenderingModeAlwaysOriginal];
            cell.textLabel.attributedText = nil;
            cell.textLabel.text = name;
            cell.textLabel.textColor = colors.cellTextColor;
        } else {
            cell.textLabel.attributedText = [self _prefixedTextWithSymbol:@"⚠" color:[UIColor systemRedColor] text:(name ?: @"") textColor:colors.cellTextColor];
        }
        cell.detailTextLabel.textColor = colors.cellDetailTextColor;
        cell.detailTextLabel.numberOfLines = 2;
        cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }

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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"TRANSFERS_IN_PROGRESS", nil);
    } else if (section == 1) {
        return NSLocalizedString(@"DOWNLOADS_SECTION_COMPLETED", nil);
    }
    return NSLocalizedString(@"TRANSFER_FAILED", nil);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSInteger count = [self tableView:tableView numberOfRowsInSection:section];
    return count == 0 ? 0. : 14.;
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
    // Playing a stale path crashes deep in VLCKit, so warn the user.
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
