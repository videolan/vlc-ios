/*****************************************************************************
 * VLCDownloadViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2020 VideoLAN. All rights reserved.
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
    self.whatToDownloadHelpLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DOWNLOAD_FROM_HTTP_HELP", nil), [[UIDevice currentDevice] model]];
    self.urlField.delegate = self;
    self.urlField.keyboardType = UIKeyboardTypeURL;
    if (@available(iOS 10.0, *)) {
        self.urlField.textContentType = UITextContentTypeURL;
    }
    self.progressContainer.hidden = YES;
    self.downloadsTable.hidden = YES;
    self.downloadsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.whatToDownloadHelpLabel.backgroundColor = [UIColor clearColor];

    _contentViewHeight = [_contentView.heightAnchor constraintEqualToConstant:0];
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
    NSAttributedString *coloredAttributedPlaceholder = [[NSAttributedString alloc] initWithString:@"http://myserver.com/file.mkv" attributes:@{NSForegroundColorAttributeName: colors.lightTextColor}];
    self.urlField.attributedPlaceholder = coloredAttributedPlaceholder;
    self.urlField.backgroundColor = colors.background;
    self.urlField.textColor = colors.cellTextColor;
    self.urlBorder.backgroundColor = colors.mediaCategorySeparatorColor;
    self.downloadsTable.backgroundColor = colors.background;
    self.view.backgroundColor = colors.background;
    self.downloadButton.backgroundColor = colors.orangeUI;
    self.whatToDownloadHelpLabel.textColor = colors.lightTextColor;
    self.progressContainer.backgroundColor = colors.background;
    self.currentDownloadLabel.textColor = colors.cellTextColor;
    self.progressPercent.textColor = colors.cellDetailTextColor;
    self.speedRate.textColor = colors.cellDetailTextColor;
    self.timeDL.textColor = colors.cellDetailTextColor;
    self.activityIndicator.color = colors.cellDetailTextColor;
    self.progressView.progressTintColor = colors.orangeUI;
    [self.downloadsTable reloadData];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return PresentationTheme.current.colors.statusBarStyle;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

#pragma mark - UI interaction

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

- (IBAction)downloadAction:(id)sender
{
    if ([self.urlField.text length] > 0) {
        NSURL *URLtoSave = [NSURL URLWithString:self.urlField.text];
        NSString *lastPathComponent = URLtoSave.lastPathComponent;
        NSString *scheme = URLtoSave.scheme;
        if (![lastPathComponent isSupportedFormat] && ![lastPathComponent.pathExtension isEqualToString:@""]) {
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

        VLCMedia *media = [VLCMedia mediaWithURL:URLtoSave];
        [_downloadController addVLCMediaToDownloadList:media fileNameOfMedia:lastPathComponent expectedDownloadSize:0];
        self.urlField.text = @"";
    }
}

- (void)_updateUI
{
    [self.downloadsTable reloadData];
    [self updateContentViewHeightConstraint];
}

- (void)updateContentViewHeightConstraint
{
    _contentViewHeight.constant = _downloadFieldContainer.frame.size.height
                                    + _progressContainer.frame.size.height
                                    + _downloadsTable.contentSize.height;
}

- (NSString *)detailText
{
    return NSLocalizedString(@"DOWNLOADVC_DETAILTEXT", nil);
}

- (UIImage *)cellImage
{
    return [UIImage imageNamed:@"Downloads"];
}

- (IBAction)cancelDownload:(id)sender
{
    [_downloadController cancelCurrentDownload];
}

#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = _downloadController.numberOfScheduledDownloads;
    self.downloadsTable.hidden = !(count > 0);
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ScheduledDownloadsCell";

    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    NSInteger row = indexPath.row;
    cell.textLabel.text = [_downloadController displayNameForDownloadAtIndex:row];
    cell.detailTextLabel.text = [_downloadController urlStringForDownloadAtIndex:row];

    ColorPalette *colors = PresentationTheme.current.colors;
    cell.textLabel.textColor = colors.cellTextColor;
    cell.detailTextLabel.textColor = colors.cellDetailTextColor;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = PresentationTheme.current.colors.cellBackgroundA;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_downloadController removeScheduledDownloadAtIndex:indexPath.row];
        [tableView reloadData];
        [self updateContentViewHeightConstraint];
    }
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
    self.currentDownloadLabel.text = displayName;
    self.progressView.progress = 0.;
    [self.progressPercent setText:@"0%"];
    self.activityIndicator.hidden = YES;
    [self.speedRate setText:@"0 Kb/s"];
    [self.timeDL setText:@"00:00:00"];
    self.progressContainer.hidden = NO;
}

- (void)downloadEnded
{
    self.progressPercent.hidden = NO;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
    self.progressContainer.hidden = YES;
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
    if (!totalSizeKnown) {
        if (self.activityIndicator.hidden) {
            self.progressPercent.hidden = YES;
            self.activityIndicator.hidden = NO;
            [self.activityIndicator startAnimating];
        }
    } else {
        [self.progressPercent setText:[NSString stringWithFormat:@"%.1f%%", percentage*100]];
    }
    [self.timeDL setText:time];
    [self.speedRate setText:speed];
    [self.progressView setProgress:percentage animated:YES];
}

- (void)listOfScheduledDownloadsChanged
{
    [self _updateUI];
}

@end
