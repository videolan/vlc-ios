/*****************************************************************************
 * VLCOneDriveTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2019 VideoLAN. All rights reserved.
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
#import "VLCPlaybackService.h"
#import "VLCProgressView.h"
#import "NSString+SupportedMedia.h"
#import "VLC-Swift.h"

#import <OneDriveSDK/ODItem.h>
#import <OneDriveSDK/ODItemReference.h>

@interface VLCOneDriveTableViewController () <VLCCloudStorageDelegate>
{
    VLCOneDriveController *_oneDriveController;
}
@end

@implementation VLCOneDriveTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self prepareOneDriveControllerIfNeeded];
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
    [self prepareOneDriveControllerIfNeeded];
}

- (void)prepareOneDriveControllerIfNeeded
{
    if (!_oneDriveController) {
        _oneDriveController = [VLCOneDriveController sharedInstance];
        _oneDriveController.presentingViewController = self;
    }
}

#pragma mark - generic interface interaction

- (void)goBack
{
    NSString *currentItemID = _oneDriveController.currentItem.id;

    if (currentItemID && ![currentItemID isEqualToString:_oneDriveController.rootItemID]) {
        if (!_oneDriveController.parentItem
            || [_oneDriveController.rootItemID isEqualToString:_oneDriveController.parentItem.id]) {
            _oneDriveController.currentItem = nil;
        } else {
            _oneDriveController.currentItem = [[ODItem alloc] initWithDictionary:_oneDriveController.parentItem.dictionaryFromItem];
            _oneDriveController.parentItem.id = _oneDriveController.parentItem.parentReference.id;
        }
        self.title = _oneDriveController.currentItem.name;
        [self.activityIndicator startAnimating];
        [_oneDriveController loadODItems];
        [_oneDriveController loadODParentItem];
    } else {
        // We're at root, we need to pop the view
        [self.navigationController popViewControllerAnimated:YES];
    }
    return;
}

#pragma mark - table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"OneDriveCell";

    VLCCloudStorageTableViewCell *cell = (VLCCloudStorageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCCloudStorageTableViewCell cellWithReuseIdentifier:CellIdentifier];

    NSArray *items = _oneDriveController.currentListFiles;

    if (indexPath.row < items.count) {
        cell.oneDriveFile = items[indexPath.row];
        cell.delegate = self;
    }

    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *items = _oneDriveController.currentListFiles;
    NSInteger row = indexPath.row;
    if (row >= items.count)
        return;

    ODItem *selectedItem = items[row];

    if (selectedItem.folder) {
        [self.activityIndicator startAnimating];
        _oneDriveController.parentItem = _oneDriveController.currentItem;
        _oneDriveController.currentItem = selectedItem;
        [_oneDriveController loadODItems];
        self.title = selectedItem.name;
    } else {
        NSString *streamingURLString = selectedItem.dictionaryFromItem[@"@content.downloadUrl"];
        if (streamingURLString) {
            VLCMediaList *mediaList;
            NSURL *url = [NSURL URLWithString:streamingURLString];
            NSString *subtitlePath = nil;
            NSInteger positionIndex = 0;
            VLCMedia *mediaToPlay = [VLCMedia mediaWithURL:url];
            mediaToPlay = [_oneDriveController setMediaNameMetadata:mediaToPlay withName:selectedItem.name];
            if (![[NSUserDefaults standardUserDefaults] boolForKey:kVLCAutomaticallyPlayNextItem]) {
                mediaList = [[VLCMediaList alloc] initWithArray:@[mediaToPlay]];
                subtitlePath = [_oneDriveController configureSubtitleWithFileName:selectedItem.name
                                                                      folderItems:items];
            } else {
                mediaList = [self createMediaListWithODItem:selectedItem positionIndex:&positionIndex];
            }
            [self streamMediaList:mediaList startingAtIndex:positionIndex subtitlesFilePath:subtitlePath];
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ERROR", nil)
                                                                                     message:NSLocalizedString(@"ONEDRIVE_MEDIA_WITHOUT_URL", nil)
                                                                              preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];

            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)streamMediaList:(VLCMediaList *)mediaList startingAtIndex:(NSInteger)startIndex subtitlesFilePath:(NSString *)subtitlesFilePath
{
    if (mediaList.count <= 0) {
        NSLog(@"VLCOneDriveTableViewController: Empty or wrong mediaList");
        return;
    }

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    [vpc playMediaList:mediaList firstIndex:startIndex subtitlesFilePath:subtitlesFilePath];
}

- (VLCMediaList *)createMediaListWithODItem:(ODItem *)item positionIndex:(NSInteger *)index
{
    NSUInteger counter = 0;
    NSArray *folderItems = _oneDriveController.currentListFiles;
    VLCMediaList *mediaList = [[VLCMediaList alloc] init];
    for (ODItem *tmpItem in folderItems) {
        if (tmpItem.folder || [tmpItem.name isSupportedSubtitleFormat]) {
            continue;
        }
        NSURL *url = [NSURL URLWithString:tmpItem.dictionaryFromItem[@"@content.downloadUrl"]];
        if (url) {
            VLCMedia *media = [_oneDriveController setMediaNameMetadata:[VLCMedia mediaWithURL:url]
                                                               withName:tmpItem.name];
            [mediaList addMedia:media];
            NSString *subtitlePath = [_oneDriveController configureSubtitleWithFileName:tmpItem.name
                                                                            folderItems:folderItems];
            if (subtitlePath) {
                [[mediaList mediaAtIndex:counter] addOptions:@{ kVLCSettingSubtitlesFilePath : subtitlePath }];
            }
            // Index needed to know where to begin in the medialist
            if (item == tmpItem) {
                *index = mediaList.count - 1;
            }

            counter++;
        }
    }
    return mediaList;
}

- (VLCMediaList *)createMediaList
{
    return [self createMediaListWithODItem:nil positionIndex:0];
}

- (void)playAllAction:(id)sender
{
    [self streamMediaList:[self createMediaList] startingAtIndex:0 subtitlesFilePath:nil];
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
    ODItem *selectedItem = _oneDriveController.currentListFiles[indexPath.row];

    if (selectedItem.size < [[UIDevice currentDevice] VLCFreeDiskSpace].longLongValue) {
        /* selected item is a proper file, ask the user if s/he wants to download it */
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DROPBOX_DOWNLOAD", nil)
                                                                                 message:[NSString stringWithFormat:NSLocalizedString(@"DROPBOX_DL_LONG", nil),
                                                                                          selectedItem.name,
                                                                                          [[UIDevice currentDevice] model]]
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *downloadAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_DOWNLOAD", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *alertAction){
                                                             [self->_oneDriveController startDownloadingODItem:selectedItem];
                                                         }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];


        [alertController addAction:downloadAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                                                 message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil),
                                                                                          selectedItem.name,
                                                                                          [[UIDevice currentDevice] model]]
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                                 style:UIAlertActionStyleCancel
                                                               handler:nil];

        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#endif

@end
