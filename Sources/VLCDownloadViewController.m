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
#import "VLCMediaFileDownloader.h"
#import "VLCActivityManager.h"
#import "NSString+SupportedMedia.h"
#import "VLC-Swift.h"

@interface VLCDownloadViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    NSMutableArray *_currentDownloads;
    BOOL _downloadActive;
    NSString *_humanReadableFilename;
    NSMutableDictionary *_userDefinedFileNameForDownloadItem;
    NSMutableDictionary *_expectedDownloadSizesForItem;
    NSTimeInterval _startDL;
    NSString *_currentDownloadIdentifier;

    NSLayoutConstraint *_contentViewHeight;

    VLCMediaFileDownloader *_mediaDownloader;

    NSTimeInterval _lastStatsUpdate;
    NSMutableArray *_lastSpeeds;
    CGFloat _totalReceived;
    CGFloat _lastReceived;

    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
}
@end

@implementation VLCDownloadViewController

+ (instancetype)sharedInstance
{
    static VLCDownloadViewController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [[VLCDownloadViewController alloc] initWithNibName:@"VLCDownloadViewController" bundle:nil];
    });

    return sharedInstance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self){
        _lastSpeeds = [[NSMutableArray alloc] init];
        _currentDownloads = [[NSMutableArray alloc] init];
        _userDefinedFileNameForDownloadItem = [[NSMutableDictionary alloc] init];
        _expectedDownloadSizesForItem = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForTheme) name:kVLCThemeDidChangeNotification object:nil];
        self.title = NSLocalizedString(@"DOWNLOAD_FROM_HTTP", comment:@"");
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
}

- (void)updateForTheme
{
    NSAttributedString *coloredAttributedPlaceholder = [[NSAttributedString alloc] initWithString:@"http://myserver.com/file.mkv" attributes:@{NSForegroundColorAttributeName: PresentationTheme.current.colors.lightTextColor}];
    self.urlField.attributedPlaceholder = coloredAttributedPlaceholder;
    self.urlField.backgroundColor = PresentationTheme.current.colors.background;
    self.urlField.textColor = PresentationTheme.current.colors.cellTextColor;
    self.urlBorder.backgroundColor = PresentationTheme.current.colors.mediaCategorySeparatorColor;
    self.downloadsTable.backgroundColor = PresentationTheme.current.colors.background;
    self.view.backgroundColor = PresentationTheme.current.colors.background;
    self.downloadButton.backgroundColor = PresentationTheme.current.colors.orangeUI;
    self.whatToDownloadHelpLabel.textColor = PresentationTheme.current.colors.lightTextColor;
    self.progressContainer.backgroundColor = PresentationTheme.current.colors.background;
    self.currentDownloadLabel.textColor =  PresentationTheme.current.colors.cellTextColor;
    self.progressPercent.textColor =  PresentationTheme.current.colors.cellDetailTextColor;
    self.speedRate.textColor =  PresentationTheme.current.colors.cellDetailTextColor;
    self.timeDL.textColor = PresentationTheme.current.colors.cellDetailTextColor;
    self.activityIndicator.color = PresentationTheme.current.colors.cellDetailTextColor;
    self.progressView.progressTintColor = PresentationTheme.current.colors.orangeUI;
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
        if (![URLtoSave.lastPathComponent isSupportedFormat] && ![URLtoSave.lastPathComponent.pathExtension isEqualToString:@""]) {
            [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil)
                                                 errorMessage:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), URLtoSave.lastPathComponent]
                                               viewController:self];
            return;
        }
        if (![URLtoSave.scheme isEqualToString:@"http"] & ![URLtoSave.scheme isEqualToString:@"https"] && ![URLtoSave.scheme isEqualToString:@"ftp"]) {
            [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"SCHEME_NOT_SUPPORTED", nil)
                                                 errorMessage:[NSString stringWithFormat:NSLocalizedString(@"SCHEME_NOT_SUPPORTED_LONG", nil), URLtoSave.scheme]
                                               viewController:self];
            return;
        }

        VLCMedia *media = [VLCMedia mediaWithURL:URLtoSave];
        @synchronized (_currentDownloads) {
            [_currentDownloads addObject:media];
        }
        self.urlField.text = @"";
        [self.downloadsTable reloadData];
        [self updateContentViewHeightConstraint];
        [self _triggerNextDownload];
    }
}

- (void)_updateUI
{
    if (_downloadActive) {
        [self downloadStartedWithIdentifier:_currentDownloadIdentifier];
    } else {
        [self downloadEndedWithIdentifier:_currentDownloadIdentifier];
    }
    [self.downloadsTable reloadData];
    [self updateContentViewHeightConstraint];
}

- (void)updateContentViewHeightConstraint
{
    _contentViewHeight.constant = _downloadFieldContainer.frame.size.height
                                    + _progressContainer.frame.size.height
                                    + _downloadsTable.contentSize.height;
}

- (VLCMediaFileDownloader *)mediaDownloader
{
    if (!_mediaDownloader) {
        _mediaDownloader = [[VLCMediaFileDownloader alloc] init];
        _mediaDownloader.delegate = self;
    }
    return _mediaDownloader;
}

- (NSString *)detailText
{
    return NSLocalizedString(@"DOWNLOADVC_DETAILTEXT", nil);
}

- (UIImage *)cellImage
{
    return [UIImage imageNamed:@"Downloads"];
}

#pragma mark - Download management

- (void)_startDownload
{
    [self _beginBackgroundDownload];
    [self _updateUI];
    _startDL = [NSDate timeIntervalSinceReferenceDate];
    [_lastSpeeds removeAllObjects];
    _lastReceived = 0;
    _totalReceived = 0;
}

- (void)_downloadVLCMediaItem:(VLCMedia *)media
{
    VLCMediaFileDownloader *fileDownloader = self.mediaDownloader;
    if (fileDownloader.downloadInProgress) {
        return;
    }

    NSURL *mediaURL = media.url;
    _humanReadableFilename = [_userDefinedFileNameForDownloadItem objectForKey:mediaURL];
    if (!_humanReadableFilename) {
        _humanReadableFilename = [mediaURL lastPathComponent];
    } else {
        _humanReadableFilename = [_humanReadableFilename stringByRemovingPercentEncoding];
    }

    long long unsigned expectedDownloadSize = [[_expectedDownloadSizesForItem objectForKey:mediaURL] unsignedLongLongValue];

    _downloadActive = YES;
    [fileDownloader downloadFileFromVLCMedia:media withName:_humanReadableFilename expectedDownloadSize:expectedDownloadSize];

    [_userDefinedFileNameForDownloadItem removeObjectForKey:mediaURL];
    [_expectedDownloadSizesForItem removeObjectForKey:mediaURL];

    [self _startDownload];
}

- (void)_beginBackgroundDownload
{
    if (!_backgroundTaskIdentifier || _backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        dispatch_block_t expirationHandler = ^{
            APLog(@"Downloads were interrupted after being in background too long, time remaining: %f", [[UIApplication sharedApplication] backgroundTimeRemaining]);
            [[UIApplication sharedApplication] endBackgroundTask:self->_backgroundTaskIdentifier];
            self->_backgroundTaskIdentifier = 0;
        };

        _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"VLCDownloader" expirationHandler:expirationHandler];
        if (_backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
            APLog(@"Unable to download");
        }
    }
}

- (void)_triggerNextDownload
{
    if ([_currentDownloads count] == 0) {
        _downloadActive = NO;

        if (_backgroundTaskIdentifier && _backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
            _backgroundTaskIdentifier = 0;
        }
        return;
    }

    VLCMedia *firstObject;
    @synchronized (_currentDownloads) {
        firstObject = _currentDownloads.firstObject;
    }
    [self _downloadVLCMediaItem:firstObject];

    @synchronized (_currentDownloads) {
        [_currentDownloads removeObjectAtIndex:0];
    }
}

- (IBAction)cancelDownload:(id)sender
{
    [self.mediaDownloader cancelDownload];
}

#pragma mark - VLC HTTP Downloader delegate

- (void)downloadStartedWithIdentifier:(NSString *)identifier
{
    _currentDownloadIdentifier = identifier;

    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStopped];
    [activityManager networkActivityStarted];

    self.currentDownloadLabel.text = _humanReadableFilename;
    self.progressView.progress = 0.;
    [self.progressPercent setText:@"0%"];
    self.activityIndicator.hidden = YES;
    [self.speedRate setText:@"0 Kb/s"];
    [self.timeDL setText:@"00:00:00"];
    self.progressContainer.hidden = NO;

    APLog(@"download started");
}

- (void)downloadEndedWithIdentifier:(NSString *)identifier
{
    _currentDownloadIdentifier = nil;
    [[VLCActivityManager defaultManager] networkActivityStopped];
    _downloadActive = NO;
    APLog(@"download ended");
    self.progressPercent.hidden = NO;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
    self.progressContainer.hidden = YES;

    [self _triggerNextDownload];
}

- (void)downloadFailedWithIdentifier:(NSString *)identifier errorDescription:(NSString *)description
{
    [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"DOWNLOAD_FAILED", nil)
                                         errorMessage:description
                                       viewController:self];
    [self downloadEndedWithIdentifier:identifier];
}

- (void)progressUpdatedTo:(CGFloat)percentage receivedDataSize:(CGFloat)receivedDataSize  expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    _totalReceived += receivedDataSize;
    _lastReceived += receivedDataSize;
    if ((_lastStatsUpdate > 0 && ([NSDate timeIntervalSinceReferenceDate] - _lastStatsUpdate > .5)) || _lastStatsUpdate <= 0) {
        CGFloat speed = [self getAverageSpeed:_lastReceived / ([NSDate timeIntervalSinceReferenceDate] - _lastStatsUpdate)];
        if (expectedDownloadSize <= 0) {
            if (self.activityIndicator.hidden) {
                self.progressPercent.hidden = YES;
                self.activityIndicator.hidden = NO;
                [self.activityIndicator startAnimating];
            }
        } else {
            [self.progressPercent setText:[NSString stringWithFormat:@"%.1f%%", percentage*100]];
        }
        [self.timeDL setText:[self getRemainingTimeString:speed expectedDownloadSize:expectedDownloadSize]];
        [self.speedRate setText:[self getSpeedString:speed]];
        _lastStatsUpdate = [NSDate timeIntervalSinceReferenceDate];
        _lastReceived = 0;
    }
    [self.progressView setProgress:percentage animated:YES];
}

- (CGFloat)getAverageSpeed:(CGFloat)speed
{
    [_lastSpeeds addObject:[NSNumber numberWithFloat:speed]];
    if (_lastSpeeds.count > 10) {
        [_lastSpeeds removeObjectAtIndex:0];
    }

    CGFloat averageSpeed = 0;
    int i = 0;
    while (i < _lastSpeeds.count) {
        averageSpeed += [_lastSpeeds[i] floatValue];
        i += 1;
    }
    averageSpeed /= i;
    return averageSpeed;
}

- (NSString *)getSpeedString:(CGFloat)speed
{
    NSString *string = [NSByteCountFormatter stringFromByteCount:speed
                                                      countStyle:NSByteCountFormatterCountStyleDecimal];
    string = [string stringByAppendingString:@"/s"];
    return string;
}

- (NSString *)getRemainingTimeString:(CGFloat)speed expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    if (expectedDownloadSize <= 0) {
        return @"--:--";
    }
    CGFloat remainingInSeconds = (expectedDownloadSize - _totalReceived)/speed;

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:remainingInSeconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSString *remaingTime = [formatter stringFromDate:date];
    return remaingTime;
}

#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count;
    @synchronized (_currentDownloads) {
        count = _currentDownloads.count;
    }
    self.downloadsTable.hidden = count > 0 ? NO : YES;
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
    VLCMedia *media;
    @synchronized (_currentDownloads) {
        if (_currentDownloads.count > row) {
            media = _currentDownloads[row];
        }
    }
    if (media) {
        NSURL *mediaURL;
        NSString *customFilename = [_userDefinedFileNameForDownloadItem objectForKey:mediaURL];
        if (customFilename) {
            cell.textLabel.text = [customFilename stringByRemovingPercentEncoding];
        } else {
            cell.textLabel.text = [[mediaURL lastPathComponent] stringByRemovingPercentEncoding];
        }

        cell.detailTextLabel.text = [mediaURL absoluteString];
    }
    cell.textLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    cell.detailTextLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor;

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
        @synchronized (_currentDownloads) {
            VLCMedia *media = _currentDownloads[indexPath.row];
            NSURL *mediaURL = media.url;
            [_userDefinedFileNameForDownloadItem removeObjectForKey:mediaURL];
            [_expectedDownloadSizesForItem removeObjectForKey:mediaURL];
            [_currentDownloads removeObjectAtIndex:indexPath.row];
        }
        [tableView reloadData];
        [self updateContentViewHeightConstraint];
    }
}

#pragma mark - communication with other VLC objects
- (void)addURLToDownloadList:(NSURL *)aURL fileNameOfMedia:(NSString*)fileName
{
    VLCMedia *media = [VLCMedia mediaWithURL:aURL];
    @synchronized (_currentDownloads) {
        [_currentDownloads addObject:media];
    }
    [self _updateDownloadList];
}

- (void)addVLCMediaToDownloadList:(VLCMedia *)media fileNameOfMedia:(NSString*)fileName expectedDownloadSize:(long long unsigned)expectedDownloadSize
{
    @synchronized (_currentDownloads) {
        [_currentDownloads addObject:media];
        NSURL *mediaURL = media.url;
        if (fileName) {
            [_userDefinedFileNameForDownloadItem setObject:fileName forKey:mediaURL];
        }
        if (expectedDownloadSize > 0) {
            [_expectedDownloadSizesForItem setObject:@(expectedDownloadSize) forKey:mediaURL];
        }
    }
    [self _updateDownloadList];
}

- (void)_updateDownloadList
{
    [self.downloadsTable reloadData];
    [self updateContentViewHeightConstraint];
    if (_downloadActive == NO)
        [self _triggerNextDownload];
}

#pragma mark - text view delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.urlField resignFirstResponder];
    return NO;
}

@end
