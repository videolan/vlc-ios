/*****************************************************************************
 * VLCOneDriveTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOneDriveTableViewController.h"
#import "VLCOneDriveController.h"
#import "VLCCloudStorageTableViewCell.h"
#import "VLCPlaybackController.h"
#import "VLCProgressView.h"
#import "UIDevice+VLC.h"
#import "NSString+SupportedMedia.h"
#import "VLCConstants.h"

@interface VLCOneDriveTableViewController () <VLCCloudStorageDelegate>
{
    VLCOneDriveController *_oneDriveController;
    VLCOneDriveObject *_selectedFile;
}
@end

@implementation VLCOneDriveTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _oneDriveController = (VLCOneDriveController *)[VLCOneDriveController sharedInstance];
    self.controller = _oneDriveController;
    self.controller.delegate = self;

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OneDriveWhite"]];

#if TARGET_OS_IOS
    [self.cloudStorageLogo setImage:[UIImage imageNamed:@"OneDriveWhite"]];

    [self.cloudStorageLogo sizeToFit];
    self.cloudStorageLogo.center = self.view.center;
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateViewAfterSessionChange];
    self.authorizationInProgress = NO;
}

#pragma mark - generic interface interaction

- (void)goBack
{
    if ((_oneDriveController.rootFolder != _oneDriveController.currentFolder) && [_oneDriveController isAuthorized]) {
        if ([_oneDriveController.rootFolder.name isEqualToString:_oneDriveController.currentFolder.parent.name]) {
            _oneDriveController.currentFolder = nil;
            self.title = _oneDriveController.rootFolder.name;
        } else {
            _oneDriveController.currentFolder = _oneDriveController.currentFolder.parent;
            self.title = _oneDriveController.currentFolder.name;
        }
        [self.activityIndicator startAnimating];
        [_oneDriveController loadCurrentFolder];
    } else
        [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"OneDriveCell";

    VLCCloudStorageTableViewCell *cell = (VLCCloudStorageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCCloudStorageTableViewCell cellWithReuseIdentifier:CellIdentifier];

    NSArray *items = _oneDriveController.currentFolder.items;

    if (indexPath.row < items.count) {
        cell.oneDriveFile = _oneDriveController.currentFolder.items[indexPath.row];
        cell.delegate = self;
    }

    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *folderItems = _oneDriveController.currentFolder.items;
    NSInteger row = indexPath.row;
    if (row >= folderItems.count)
        return;

    VLCOneDriveObject *selectedObject = folderItems[row];
    if (selectedObject.isFolder) {
        /* dive into sub folder */
        [self.activityIndicator startAnimating];
        _oneDriveController.currentFolder = selectedObject;
        [_oneDriveController loadCurrentFolder];
        self.title = selectedObject.name;
    } else {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kVLCAutomaticallyPlayNextItem]) {
            /* stream file */
            NSURL *url = [NSURL URLWithString:selectedObject.downloadPath];

            VLCMediaList *mediaList = [[VLCMediaList alloc] initWithArray:@[[VLCMedia mediaWithURL:url]]];
            [self streamMediaList:mediaList startingAtIndex:0 subtitlesFilePath:selectedObject.subtitleURL];
        } else {
            NSInteger posIndex = 0;
            NSUInteger counter = 0;
            VLCMediaList *mediaList = [[VLCMediaList alloc] init];
            for (VLCOneDriveObject *item in folderItems) {
                if ((item.isFolder) || [item.name isSupportedSubtitleFormat])
                    continue;
                NSURL *url = [NSURL URLWithString:item.downloadPath];
                if (url) {
                    [mediaList addMedia:[VLCMedia mediaWithURL:url]];
                    if (item.subtitleURL)
                        [[mediaList mediaAtIndex:counter] addOptions:@{ kVLCSettingSubtitlesFilePath : item.subtitleURL }];
                    counter ++;

                    if (item == selectedObject)
                        posIndex = mediaList.count - 1;
                }
            }

            if (mediaList.count > 0)
                [self streamMediaList:mediaList startingAtIndex:posIndex subtitlesFilePath:nil];
        }
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)streamMediaList:(VLCMediaList *)mediaList startingAtIndex:(NSInteger)startIndex subtitlesFilePath:(NSString *)subtitlesFilePath
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    vpc.fullscreenSessionRequested = NO;
    [vpc playMediaList:mediaList firstIndex:startIndex subtitlesFilePath:subtitlesFilePath];
}

- (void)playAllAction:(id)sender
{
    NSUInteger counter = 0;
    NSArray *folderItems = _oneDriveController.currentFolder.items;
    VLCMediaList *mediaList = [[VLCMediaList alloc] init];
    for (VLCOneDriveObject *item in folderItems) {
        if ((item.isFolder) || [item.name isSupportedSubtitleFormat])
            continue;
        NSURL *url = [NSURL URLWithString:item.downloadPath];
        if (url) {
            [mediaList addMedia:[VLCMedia mediaWithURL:url]];
            if (item.subtitleURL)
                [[mediaList mediaAtIndex:counter] addOptions:@{ kVLCSettingSubtitlesFilePath : item.subtitleURL }];
            counter ++;
        }
    }

    if (mediaList.count > 0)
        [self streamMediaList:mediaList startingAtIndex:0 subtitlesFilePath:nil];
}

#pragma mark - login dialog

- (void)loginAction:(id)sender
{
    if (![_oneDriveController isAuthorized]) {
        self.authorizationInProgress = YES;
        [_oneDriveController loginWithViewController:self];
    } else
        [_oneDriveController logout];
}

#pragma mark - onedrive controller delegation

- (void)sessionWasUpdated
{
    [self updateViewAfterSessionChange];
}

#pragma mark - cell delegation

#if TARGET_OS_IOS
- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    _selectedFile = _oneDriveController.currentFolder.items[indexPath.row];

    if (_selectedFile.size.longLongValue < [[UIDevice currentDevice] VLCFreeDiskSpace].longLongValue) {
        /* selected item is a proper file, ask the user if s/he wants to download it */
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DROPBOX_DOWNLOAD", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"DROPBOX_DL_LONG", nil), _selectedFile.name, [[UIDevice currentDevice] model]]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                otherButtonTitles:NSLocalizedString(@"BUTTON_DOWNLOAD", nil), nil];
        [alert show];
    } else {
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), _selectedFile.name, [[UIDevice currentDevice] model]]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                otherButtonTitles:nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [_oneDriveController downloadObject:_selectedFile];

    _selectedFile = nil;
}
#endif

@end
