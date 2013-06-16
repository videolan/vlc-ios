//
//  VLCHTTPDownloadViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 16.06.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCHTTPDownloadViewController.h"
#import "VLCHTTPFileDownloader.h"

@interface VLCHTTPDownloadViewController ()
{
    VLCHTTPFileDownloader *_httpDownloader;
    NSMutableArray *_currentDownloads;
}
@end

@implementation VLCHTTPDownloadViewController

- (void)viewDidLoad
{
    [self.downloadButton setTitle:NSLocalizedString(@"BUTTON_DOWNLOAD",@"") forState:UIControlStateNormal];
    _currentDownloads = [[NSMutableArray alloc] init];
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([[UIPasteboard generalPasteboard] containsPasteboardTypes:@[@"public.url", @"public.text"]]) {
        NSURL *pasteURL = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.url"];
        if (!pasteURL || [[pasteURL absoluteString] isEqualToString:@""]) {
            NSString *pasteString = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.text"];
            pasteURL = [NSURL URLWithString:pasteString];
        }

        if (pasteURL && ![[pasteURL scheme] isEqualToString:@""] && ![[pasteURL absoluteString] isEqualToString:@""])
            self.urlField.text = [pasteURL absoluteString];
    }

    [super viewWillAppear:animated];
}

#pragma mark - UI interaction
- (IBAction)downloadAction:(id)sender
{
    if ([self.urlField.text length] > 0) {
        NSURL *URLtoSave = [NSURL URLWithString:self.urlField.text];
        if (([URLtoSave.scheme isEqualToString:@"http"] || [URLtoSave.scheme isEqualToString:@"https"]) && ![URLtoSave.lastPathComponent.pathExtension isEqualToString:@""]) {
            if (!_httpDownloader) {
                _httpDownloader = [[VLCHTTPFileDownloader alloc] init];
                _httpDownloader.delegate = self;
            }
            [_currentDownloads addObject:URLtoSave];
            self.urlField.text = @"";
            [self.downloadsTable reloadData];

            [self _triggerNextDownload];
        }
    }
}

#pragma mark - download management
- (void)_triggerNextDownload
{
    if (!_httpDownloader.downloadInProgress && _currentDownloads.count > 0) {
        [_httpDownloader downloadFileFromURL:_currentDownloads[0]];
        [self.activityIndicator startAnimating];
        [_currentDownloads removeObjectAtIndex:0];
        [self.downloadsTable reloadData];
    }
}

- (IBAction)cancelDownload:(id)sender
{
    if (_httpDownloader.downloadInProgress)
        [_httpDownloader cancelDownload];
}

#pragma mark - VLC HTTP Downloader delegate

- (void)downloadStarted
{
    [self.activityIndicator stopAnimating];
    self.currentDownloadLabel.text = _httpDownloader.userReadableDownloadName;
    self.progressView.progress = 0.;
    self.currentDownloadLabel.hidden = NO;
    self.progressView.hidden = NO;
    self.cancelButton.hidden = NO;
    APLog(@"download started");
}

- (void)downloadEnded
{
    self.currentDownloadLabel.hidden = YES;
    self.progressView.hidden = YES;
    self.cancelButton.hidden = YES;
    APLog(@"download ended");

    [self _triggerNextDownload];
}

- (void)downloadFailedWithErrorDescription:(NSString *)description
{
    APLog(@"download failed: %@", description);
}

- (void)progressUpdatedTo:(CGFloat)percentage
{
    [self.progressView setProgress:percentage animated:YES];
}

#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _currentDownloads.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ScheduledDownloadsCell";

    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:.72 alpha:1.];
    }

    NSInteger row = indexPath.row;
    cell.textLabel.text = [_currentDownloads[row] lastPathComponent];
    cell.detailTextLabel.text = [_currentDownloads[row] absoluteString];

    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor colorWithWhite:.122 alpha:1.];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_currentDownloads removeObjectAtIndex:indexPath.row];
        [tableView reloadData];
    }
}

@end
