//
//  VLCOpenNetworkStreamViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 16.06.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCOpenNetworkStreamViewController.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"

@interface VLCOpenNetworkStreamViewController ()
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
    [self.openButton setTitle:NSLocalizedString(@"BUTTON_OPEN", @"") forState:UIControlStateNormal];
    [self.privateModeLabel setText:NSLocalizedString(@"PRIVATE_PLAYBACK_TOGGLE", @"")];
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

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSArray arrayWithArray:_recentURLs] forKey:kVLCRecentURLs];
    [defaults setBool:self.privateToggleSwitch.on forKey:kVLCPrivateWebStreaming];
    [defaults synchronize];

    [super viewWillDisappear:animated];
}

- (CGSize)contentSizeForViewInPopover {
    return [self.view sizeThatFits:CGSizeMake(320, 800)];
}

#pragma mark - UI interaction
- (IBAction)openButtonAction:(id)sender
{
    if ([self.urlField.text length] > 0) {
        if (!self.privateToggleSwitch.on) {
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
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:.72 alpha:1.];
    }

    NSInteger row = indexPath.row;
    cell.textLabel.text = [_recentURLs[row] lastPathComponent];
    cell.detailTextLabel.text = _recentURLs[row];

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
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.playlistViewController openMovieFromURL:[NSURL URLWithString:url]];

    [self dismissModalViewControllerAnimated:YES];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [appDelegate.playlistViewController.addMediaPopoverController dismissPopoverAnimated:YES];
}

@end
