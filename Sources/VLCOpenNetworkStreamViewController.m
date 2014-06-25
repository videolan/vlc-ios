/*****************************************************************************
 * VLCOpenNetworkStreamViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOpenNetworkStreamViewController.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "UIBarButtonItem+Theme.h"
#import "UINavigationController+Theme.h"
#import "VLCMenuTableViewController.h"

@interface VLCOpenNetworkStreamViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    NSMutableArray *_recentURLs;
}
@end

@implementation VLCOpenNetworkStreamViewController

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{kVLCRecentURLs : @[], kVLCPrivateWebStreaming : @(NO)};

    [defaults registerDefaults:appDefaults];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (SYSTEM_RUNS_IOS7_OR_LATER)
        [self.openButton setTitle:NSLocalizedString(@"OPEN_NETWORK", @"") forState:UIControlStateNormal];
    else
        [self.openButton setTitle:NSLocalizedString(@"BUTTON_OPEN", @"") forState:UIControlStateNormal];
    [self.privateModeLabel setText:NSLocalizedString(@"PRIVATE_PLAYBACK_TOGGLE", @"")];
    [self.ScanSubModeLabel setText:NSLocalizedString(@"SCAN_SUBTITLE_TOGGLE", @"")];
    [self.ScanSubModeLabel setAdjustsFontSizeToFitWidth:YES];
    [self.ScanSubModeLabel setNumberOfLines:0];
    self.title = NSLocalizedString(@"OPEN_NETWORK", @"");
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
    [self.whatToOpenHelpLabel setText:NSLocalizedString(@"OPEN_NETWORK_HELP", @"")];
    self.urlField.delegate = self;
    self.urlField.keyboardType = UIKeyboardTypeURL;

    if (SYSTEM_RUNS_IOS7_OR_LATER)
        self.edgesForExtendedLayout = UIRectEdgeNone;
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

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _recentURLs = [NSMutableArray arrayWithArray:[defaults objectForKey:kVLCRecentURLs]];
    self.privateToggleSwitch.on = [defaults boolForKey:kVLCPrivateWebStreaming];
    self.ScanSubToggleSwitch.on = [defaults boolForKey:kVLChttpScanSubtitle];

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSArray arrayWithArray:_recentURLs] forKey:kVLCRecentURLs];
    [defaults setBool:self.privateToggleSwitch.on forKey:kVLCPrivateWebStreaming];
    [defaults setBool:self.ScanSubToggleSwitch.on forKey:kVLChttpScanSubtitle];
    [defaults synchronize];

    [super viewWillDisappear:animated];
}

- (CGSize)contentSizeForViewInPopover {
    return [self.view sizeThatFits:CGSizeMake(320, 800)];
}

#pragma mark - UI interaction
- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

- (IBAction)goBack:(id)sender
{
    [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController] toggleSidebar:![(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController].sidebarShowing duration:kGHRevealSidebarDefaultAnimationDuration];
}

- (IBAction)openButtonAction:(id)sender
{
    if ([self.urlField.text length] > 0) {
        if (!self.privateToggleSwitch.on) {
            if ([_recentURLs indexOfObject:self.urlField.text] != NSNotFound)
                [_recentURLs removeObject:self.urlField.text];

            if (_recentURLs.count >= 15)
                [_recentURLs removeLastObject];
            [_recentURLs addObject:self.urlField.text];

            [self.historyTableView reloadData];
        }
        [self _openURLStringAndDismiss:self.urlField.text];
    }
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

    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.highlightedTextColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor VLCLightTextColor];
        cell.detailTextLabel.highlightedTextColor = [UIColor blackColor];
    }

    NSInteger row = indexPath.row;
    cell.textLabel.text = [_recentURLs[row] lastPathComponent];
    cell.detailTextLabel.text = _recentURLs[row];

    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor VLCDarkBackgroundColor];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_recentURLs removeObjectAtIndex:indexPath.row];
        [tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self _openURLStringAndDismiss:_recentURLs[indexPath.row]];
    [self.historyTableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - internals
- (void)_openURLStringAndDismiss:(NSString *)url
{
    NSURL *URLscheme = [NSURL URLWithString:url];
    NSString *URLofSubtitle = nil;

    if ([URLscheme.scheme isEqualToString:@"http"])
        if (self.ScanSubToggleSwitch.on)
            URLofSubtitle = [self _checkURLofSubtitle:url];

    [(VLCAppDelegate*)[UIApplication sharedApplication].delegate openMovieWithExternalSubtitleFromURL:[NSURL URLWithString:url] externalSubURL:URLofSubtitle];
}

- (NSString *)_checkURLofSubtitle:(NSString *)url
{
    NSString *SubtitleFileExtensions = kSupportedSubtitleFileExtensions;
    NSCharacterSet *characterFilter = [NSCharacterSet characterSetWithCharactersInString:@"\\.():$"];
    SubtitleFileExtensions = [[SubtitleFileExtensions componentsSeparatedByCharactersInSet:characterFilter] componentsJoinedByString:@""];
    NSArray *arraySubtitleFileExtensions = [SubtitleFileExtensions componentsSeparatedByString:@"|"];
    NSString *urlTemp = [[url stringByDeletingPathExtension] stringByAppendingString:@"."];

    for (int cnt = 0; cnt < arraySubtitleFileExtensions.count; cnt++) {
        NSString *CheckURL = [urlTemp stringByAppendingString:arraySubtitleFileExtensions[cnt]];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:CheckURL]];
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *receivedData = [[NSData alloc] initWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error]];
        NSInteger httpStatus = [(NSHTTPURLResponse *)response statusCode];
        receivedData = nil;

        if (httpStatus == 200) {
            NSString *receivedSub = [NSString stringWithContentsOfURL:[NSURL URLWithString:CheckURL] encoding:NSASCIIStringEncoding error:nil];

            NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *directoryPath = searchPaths[0];
            NSString *FileSubtitlePath = [directoryPath stringByAppendingPathComponent:[CheckURL lastPathComponent]];

            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
                //create local subtitle file
                [fileManager createFileAtPath:FileSubtitlePath contents:nil attributes:nil];
                if (![fileManager fileExistsAtPath:FileSubtitlePath])
                    APLog(@"file creation failed, no data was saved");
            }
            [receivedSub writeToFile:FileSubtitlePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            return FileSubtitlePath;
        }
    }
    return nil;
}

#pragma mark - text view delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.urlField resignFirstResponder];
    return NO;
}

@end
