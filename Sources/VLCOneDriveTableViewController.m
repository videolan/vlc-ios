/*****************************************************************************
 * VLCOneDriveTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
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
        VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];

        if (![[NSUserDefaults standardUserDefaults] boolForKey:kVLCAutomaticallyPlayNextItem]) {
            /* stream file */
            NSString *subtitlePath = [self _searchSubtitle:selectedObject.name];
            subtitlePath = [self _getFileSubtitleFromServer:[NSURL URLWithString:subtitlePath]];
            NSURL *url = [NSURL URLWithString:selectedObject.downloadPath];

            VLCMediaList *medialist = [[VLCMediaList alloc] init];
            [medialist addMedia: [VLCMedia mediaWithURL:url]];
            [[VLCPlaybackController sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:subtitlePath];
        } else {
            NSMutableArray *mediaItems = [[NSMutableArray alloc] init];
            NSInteger posIndex = 0;
            for (VLCOneDriveObject *item in folderItems) {
                if ((item.isFolder) || [item.name isSupportedSubtitleFormat])
                    continue;
                NSURL *url = [NSURL URLWithString:item.downloadPath];
                if (url) {
                    [mediaItems addObject:[VLCMedia mediaWithURL:url]];

                    if (item == selectedObject) {
                        posIndex = mediaItems.count -1;
                    }
                }
            }

            if (mediaItems.count > 0) {
                [vpc playMediaList:[[VLCMediaList alloc] initWithArray:mediaItems] firstIndex:posIndex subtitlesFilePath:nil];
            }
        }
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (NSString *)_searchSubtitle:(NSString *)url
{
    NSString *urlTemp = [[url lastPathComponent] stringByDeletingPathExtension];
    NSArray *folderItems = _oneDriveController.currentFolder.items;
    NSString *itemPath = nil;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", urlTemp];
    NSArray *results = [folderItems filteredArrayUsingPredicate:predicate];

    for (int cnt = 0; cnt < results.count; cnt++) {
        VLCOneDriveObject *iter = results[cnt];
        NSString *itemName = iter.name;
        if ([itemName isSupportedSubtitleFormat])
            itemPath = iter.downloadPath;
    }
    return itemPath;
}

- (NSString *)_getFileSubtitleFromServer:(NSURL *)subtitleURL
{
    NSString *FileSubtitlePath = nil;
    NSData *receivedSub = [NSData dataWithContentsOfURL:subtitleURL]; // TODO: fix synchronous load

    if (receivedSub.length < [[UIDevice currentDevice] VLCFreeDiskSpace].longLongValue) {
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *directoryPath = searchPaths[0];
        FileSubtitlePath = [directoryPath stringByAppendingPathComponent:[subtitleURL lastPathComponent]];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
            //create local subtitle file
            [fileManager createFileAtPath:FileSubtitlePath contents:nil attributes:nil];
            if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
                APLog(@"file creation failed, no data was saved");
                return nil;
            }
        }
        [receivedSub writeToFile:FileSubtitlePath atomically:YES];
    } else {
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), [subtitleURL lastPathComponent], [[UIDevice currentDevice] model]]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                otherButtonTitles:nil];
        [alert show];
    }

    return FileSubtitlePath;
}

- (void)playAllAction:(id)sender
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSArray *folderItems = _oneDriveController.currentFolder.items;
    NSMutableArray *mediaItems = [[NSMutableArray alloc] init];
    for (VLCOneDriveObject *item in folderItems) {
        if ((item.isFolder) || [item.name isSupportedSubtitleFormat])
            continue;

        NSURL *url = [NSURL URLWithString:item.downloadPath];
        if (url) {
            [mediaItems addObject:[VLCMedia mediaWithURL:url]];
        }
    }

    if (mediaItems.count > 0) {
        [vpc playMediaList:[[VLCMediaList alloc] initWithArray:mediaItems] firstIndex:0 subtitlesFilePath:nil];
    }
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
