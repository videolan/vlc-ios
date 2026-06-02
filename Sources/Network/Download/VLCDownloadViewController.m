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
#import "VLCDownloadController.h"
#import "VLCActiveDownloadCell.h"
#import "NSString+SupportedMedia.h"
#import "VLC-Swift.h"

@interface VLCDownloadViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, VLCDownloadControllerDelegate>
{
    NSLayoutConstraint *_contentViewHeight;
    VLCDownloadController *_downloadController;
}
@end

@implementation VLCDownloadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForTheme) name:kVLCThemeDidChangeNotification object:nil];
        self.title = NSLocalizedString(@"DOWNLOAD_FROM_HTTP", comment:@"");
        _downloadController = [VLCDownloadController sharedInstance];
        _downloadController.delegate = self;
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
    [self _updateUI];
    [super viewWillAppear:animated];
    [_downloadController bringDelegateUpToDate];
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
            [self->_downloadController addVLCMediaToDownloadList:media fileNameOfMedia:lastPathComponent expectedDownloadSize:0];
            self.urlField.text = @"";
        } fail:nil];
    }
}

- (void)_updateUI
{
    [self.downloadsTable reloadData];
    [self updateContentViewHeightConstraint];
}

- (void)updateContentViewHeightConstraint
{
    CGFloat progressHeight = _progressContainer.hidden ? 0 : _progressContainer.frame.size.height;
    _contentViewHeight.constant = _downloadFieldContainer.frame.size.height
                                    + progressHeight
                                    + _downloadsTable.contentSize.height;
}

- (IBAction)cancelDownload:(id)sender
{
    [_downloadController cancelCurrentDownload];
}

#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        NSInteger n = (NSInteger)_downloadController.numberOfScheduledDownloads;
        if (_downloadController.hasActiveDownload) {
            n += 1;
        }
        return n;
    } else if (section == 1) {
        return _downloadController.numberOfCompletedDownloads;
    }
    return _downloadController.numberOfFailedDownloads;
}

- (BOOL)_isActiveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 0
        && indexPath.row == 0
        && _downloadController.hasActiveDownload;
}

- (NSUInteger)_scheduledIndexForRow:(NSInteger)row
{
    if (_downloadController.hasActiveDownload) {
        return (NSUInteger)(row - 1);
    }
    return (NSUInteger)row;
}

- (NSAttributedString *)_prefixedTextWithSymbol:(NSString *)symbol color:(UIColor *)symbolColor text:(NSString *)text textColor:(UIColor *)textColor
{
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[symbol stringByAppendingString:@" "]
                                                                               attributes:@{NSForegroundColorAttributeName: symbolColor}];
    [result appendAttributedString:[[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName: textColor}]];
    return result;
}

- (NSString *)_statsTextForActiveDownload
{
    if (!_downloadController.activeDownloadSizeKnown) {
        NSString *bytes = _downloadController.activeDownloadBytesString;
        return bytes.length > 0 ? bytes : NSLocalizedString(@"DOWNLOADING", nil);
    }
    NSString *bytes = _downloadController.activeDownloadBytesString ?: @"";
    NSString *speed = _downloadController.activeDownloadSpeedString ?: @"";
    NSString *time = _downloadController.activeDownloadTimeString ?: @"";
    return [NSString stringWithFormat:@"%@\n%@ • %@", bytes, speed, time];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ColorPalette *colors = PresentationTheme.current.colors;

    if ([self _isActiveRowAtIndexPath:indexPath]) {
        static NSString *ActiveCellID = @"ActiveDownloadCell";
        VLCActiveDownloadCell *activeCell = (VLCActiveDownloadCell *)[tableView dequeueReusableCellWithIdentifier:ActiveCellID];
        if (activeCell == nil) {
            activeCell = [[VLCActiveDownloadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ActiveCellID];
        }
        [activeCell applyTheme];
        activeCell.name = _downloadController.activeDownloadDisplayName ?: @"";
        activeCell.progressKnown = _downloadController.activeDownloadSizeKnown;
        activeCell.statsText = [self _statsTextForActiveDownload];
        if (_downloadController.activeDownloadSizeKnown) {
            activeCell.progress = _downloadController.activeDownloadPercentage;
        }
        return activeCell;
    }

    static NSString *CellIdentifier = @"ScheduledDownloadsCell";

    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.detailTextLabel.numberOfLines = 1;

    NSInteger row = indexPath.row;
    if (indexPath.section == 0) {
        NSUInteger scheduledIdx = [self _scheduledIndexForRow:row];
        cell.textLabel.attributedText = nil;
        cell.textLabel.text = [_downloadController displayNameForDownloadAtIndex:scheduledIdx];
        cell.detailTextLabel.text = [_downloadController urlStringForDownloadAtIndex:scheduledIdx];
        cell.imageView.image = nil;
        cell.textLabel.textColor = colors.cellTextColor;
        cell.detailTextLabel.textColor = colors.cellDetailTextColor;
    } else if (indexPath.section == 1) {
        NSString *name = [_downloadController displayNameForCompletedDownloadAtIndex:row];
        cell.detailTextLabel.text = [_downloadController metadataForCompletedDownloadAtIndex:row];
        cell.imageView.image = nil;
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
        NSString *name = [_downloadController displayNameForFailedDownloadAtIndex:row];
        cell.detailTextLabel.text = [_downloadController errorDescriptionForFailedDownloadAtIndex:row];
        cell.imageView.image = nil;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self _isActiveRowAtIndexPath:indexPath]) {
        return 96;
    }
    return 60;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"DOWNLOADING", nil);
    } else if (section == 1) {
        return NSLocalizedString(@"DOWNLOADS_SECTION_COMPLETED", nil);
    }
    return NSLocalizedString(@"DOWNLOAD_FAILED", nil);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        if (_downloadController.numberOfScheduledDownloads == 0 && !_downloadController.hasActiveDownload) {
            return 0.;
        }
    } else if (section == 1) {
        if (_downloadController.numberOfCompletedDownloads == 0) {
            return 0.;
        }
    } else {
        if (_downloadController.numberOfFailedDownloads == 0) {
            return 0.;
        }
    }
    return 14.;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = PresentationTheme.current.colors.cellBackgroundA;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 || indexPath.section == 2) {
        return YES;
    }

    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.section == 0) {
            if ([self _isActiveRowAtIndexPath:indexPath]) {
                [_downloadController cancelCurrentDownload];
            } else {
                NSUInteger scheduledIdx = [self _scheduledIndexForRow:indexPath.row];
                [_downloadController removeScheduledDownloadAtIndex:scheduledIdx];
            }
        } else if (indexPath.section == 2) {
            [_downloadController removeFailedDownloadAtIndex:indexPath.row];
        }
        [tableView reloadData];
        [self updateContentViewHeightConstraint];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        return;
    }
    if (indexPath.section == 2) {
        NSString *name = [_downloadController displayNameForFailedDownloadAtIndex:indexPath.row];
        NSString *err = [_downloadController errorDescriptionForFailedDownloadAtIndex:indexPath.row];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:(name.length ? name : NSLocalizedString(@"DOWNLOAD_FAILED", nil))
                                                                       message:(err.length ? err : NSLocalizedString(@"DOWNLOAD_FAILED", nil))
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    VLCMedia *media = [_downloadController mediaForCompletedDownloadAtIndex:indexPath.row];
    NSString *mediaPath = media.url.path;
    // Playing a stale path crashes deep in VLCKit, so warn the user.
    if (media == nil || mediaPath.length == 0
        || ![[NSFileManager defaultManager] fileExistsAtPath:mediaPath]) {
        NSString *name = [_downloadController displayNameForCompletedDownloadAtIndex:indexPath.row];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:(name.length ? name : NSLocalizedString(@"DOWNLOAD_FROM_HTTP", nil))
                                                                       message:NSLocalizedString(@"DOWNLOAD_FILE_UNAVAILABLE", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    VLCMediaList *mediaList = [[VLCMediaList alloc] initWithArray:@[media]];
    [VLCPlaybackService.sharedInstance playMediaList:mediaList firstIndex:0 subtitlesFilePath:nil];
}

#pragma mark - text view delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.urlField resignFirstResponder];
    return NO;
}

#pragma mark - download controller delegation

- (void)downloadStartedWithDisplayName:(NSString *)displayName
{
    // Container is kept hidden; the active download is rendered as an inline cell.
    self.progressContainer.hidden = YES;
    [self _updateUI];
}

- (void)downloadEnded
{
    self.progressContainer.hidden = YES;
    [self _updateUI];
}

- (void)downloadFailedWithDescription:(NSString *)description
{
    [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"DOWNLOAD_FAILED", nil)
                                         errorMessage:description
                                       viewController:self];
}

- (void)downloadProgressUpdatedWithPercentage:(CGFloat)percentage
                                         time:(NSString *)time
                                        speed:(NSString *)speed
                               totalSizeKnown:(BOOL)totalSizeKnown
{
    if (!_downloadController.hasActiveDownload) {
        return;
    }
    // Patch the active cell in place: mutating the table while a swipe-to-cancel
    // is in flight triggers an invalid-row-count crash.
    if ([self.downloadsTable numberOfRowsInSection:0] == 0) {
        return;
    }
    NSIndexPath *activeIP = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewCell *cell = [self.downloadsTable cellForRowAtIndexPath:activeIP];
    if (![cell isKindOfClass:[VLCActiveDownloadCell class]]) {
        return;
    }
    VLCActiveDownloadCell *activeCell = (VLCActiveDownloadCell *)cell;
    activeCell.progressKnown = totalSizeKnown;
    if (totalSizeKnown) {
        activeCell.progress = percentage;
    }
    activeCell.statsText = [self _statsTextForActiveDownload];
}

- (void)listOfScheduledDownloadsChanged
{
    [self _updateUI];
}

@end
