/*****************************************************************************
 * VLCUPnPServerListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Marc Etcheverry <marc@taplightsoftware.com>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCUPnPServerListViewController.h"

#import "VLCNetworkListCell.h"
#import "VLCAppDelegate.h"
#import "VLCStatusLabel.h"
#import "NSString+SupportedMedia.h"

#import "MediaServerBasicObjectParser.h"
#import "MediaServer1ItemObject.h"
#import "MediaServer1ContainerObject.h"
#import "MediaServer1Device.h"
#import "BasicUPnPDevice+VLC.h"

@interface VLCUPnPServerListViewController () <VLCNetworkListCellDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
    MediaServer1Device *_UPNPdevice;
    NSString *_UPNProotID;
    NSMutableArray *_mutableObjectList;
    NSMutableArray *_searchData;

    MediaServer1ItemObject *_lastSelectedMediaItem;
    UIView *_resourceSelectionActionSheetAnchorView;
}

@end

@implementation VLCUPnPServerListViewController

- (id)initWithUPNPDevice:(MediaServer1Device*)device header:(NSString*)header andRootID:(NSString*)rootID
{
    self = [super init];

    if (self) {
        _UPNPdevice = device;
        self.title = header;
        _UPNProotID = rootID;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    @synchronized(self) {
        _mutableObjectList = [[NSMutableArray alloc] init];
    }

    NSString *sortCriteria = @"";
    NSMutableString *outSortCaps = [[NSMutableString alloc] init];
    [[_UPNPdevice contentDirectory] GetSortCapabilitiesWithOutSortCaps:outSortCaps];

    if ([outSortCaps rangeOfString:@"dc:title"].location != NSNotFound)
    {
        sortCriteria = @"+dc:title";
    }

    NSMutableString *outResult = [[NSMutableString alloc] init];
    NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
    NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
    NSMutableString *outUpdateID = [[NSMutableString alloc] init];

    [[_UPNPdevice contentDirectory] BrowseWithObjectID:_UPNProotID BrowseFlag:@"BrowseDirectChildren" Filter:@"*" StartingIndex:@"0" RequestedCount:@"0" SortCriteria:sortCriteria OutResult:outResult OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];

    @synchronized(self) {
        [_mutableObjectList removeAllObjects];
    }
    NSData *didl = [outResult dataUsingEncoding:NSUTF8StringEncoding];
    MediaServerBasicObjectParser *parser;
    @synchronized(self) {
        parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:_mutableObjectList itemsOnly:NO];
    }
    [parser parseFromData:didl];
}

#pragma mark - table view data source, for more see super

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count;

    if (tableView == self.searchDisplayController.searchResultsTableView) {
        @synchronized(self) {
            count = _searchData.count;
        }
    } else {
        @synchronized(self) {
            count = _mutableObjectList.count;
        }
    }

    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalNetworkCellDetail";

    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    MediaServer1BasicObject *item;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        @synchronized(self) {
            item = _searchData[indexPath.row];
        }
    } else {
        @synchronized(self) {
            item = _mutableObjectList[indexPath.row];
        }
    }

    if (![item isContainer]) {
        MediaServer1ItemObject *mediaItem;
        long long mediaSize = 0;
        unsigned int durationInSeconds = 0;
        unsigned int bitrate = 0;

        if (tableView == self.searchDisplayController.searchResultsTableView) {
            @synchronized(self) {
                mediaItem = _searchData[indexPath.row];
            }
        } else {
            @synchronized(self) {
                mediaItem = _mutableObjectList[indexPath.row];
            }
        }

        MediaServer1ItemRes *resource = nil;
        NSEnumerator *e = [[mediaItem resources] objectEnumerator];
        while((resource = (MediaServer1ItemRes*)[e nextObject])){
            if (resource.bitrate > 0 && resource.durationInSeconds > 0) {
                mediaSize = resource.size;
                durationInSeconds = resource.durationInSeconds;
                bitrate = resource.bitrate;
            }
        }
        if (mediaSize < 1)
            mediaSize = [mediaItem.size longLongValue];

        if (mediaSize < 1)
            mediaSize = (bitrate * durationInSeconds);

        // object.item.videoItem.videoBroadcast items (like the HDHomeRun) may not have this information. Center the title (this makes channel names look better for the HDHomeRun)
        if (mediaSize > 0 && durationInSeconds > 0) {
            [cell setSubtitle: [NSString stringWithFormat:@"%@ (%@)", [NSByteCountFormatter stringFromByteCount:mediaSize countStyle:NSByteCountFormatterCountStyleFile], [VLCTime timeWithInt:durationInSeconds * 1000].stringValue]];
        } else {
            cell.titleLabelCentered = YES;
        }

        // Custom TV icon for video broadcasts
        if ([[mediaItem objectClass] isEqualToString:@"object.item.videoItem.videoBroadcast"]) {
            UIImage *broadcastImage;

            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                broadcastImage = [UIImage imageNamed:@"TVBroadcastIcon"];
            } else {
                broadcastImage = [UIImage imageNamed:@"TVBroadcastIcon~ipad"];
            }
            [cell setIcon:broadcastImage];
        } else {
            [cell setIcon:[UIImage imageNamed:@"blank"]];
        }

        [cell setIsDirectory:NO];
        if (mediaItem.albumArt != nil)
            [cell setIconURL:[NSURL URLWithString:mediaItem.albumArt]];

        // Disable downloading for the HDHomeRun for now to avoid infinite downloads (URI needs a duration parameter, otherwise you are just downloading a live stream). VLC also needs an extension in the file name for this to work.
        if (![_UPNPdevice VLC_isHDHomeRunMediaServer]) {
            cell.isDownloadable = YES;
        }
        cell.delegate = self;
    } else {
        [cell setIsDirectory:YES];
        if (item.albumArt != nil)
            [cell setIconURL:[NSURL URLWithString:item.albumArt]];
        [cell setIcon:[UIImage imageNamed:@"folder"]];
    }
    [cell setTitle:[item title]];

    return cell;
}

#pragma mark - table view delegate, for more see super

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaServer1BasicObject *item;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        @synchronized(self) {
            item = _searchData[indexPath.row];
        }
    } else {
        @synchronized(self) {
            item = _mutableObjectList[indexPath.row];
        }
    }

    if ([item isContainer]) {
        MediaServer1ContainerObject *container;
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            @synchronized(self) {
                container = _searchData[indexPath.row];
            }
        } else {
            @synchronized(self) {
                container = _mutableObjectList[indexPath.row];
            }
        }

        VLCUPnPServerListViewController *targetViewController = [[VLCUPnPServerListViewController alloc] initWithUPNPDevice:_UPNPdevice header:[container title] andRootID:[container objectID]];
        [[self navigationController] pushViewController:targetViewController animated:YES];
    } else {
        MediaServer1ItemObject *mediaItem;

        if (tableView == self.searchDisplayController.searchResultsTableView) {
            @synchronized(self) {
                mediaItem = _searchData[indexPath.row];
            }
        } else {
            @synchronized(self) {
                mediaItem = _mutableObjectList[indexPath.row];
            }
        }

        NSURL *itemURL;
        NSArray *uriCollectionKeys = [[mediaItem uriCollection] allKeys];
        NSUInteger count = uriCollectionKeys.count;
        NSRange position;
        NSUInteger correctIndex = 0;
        NSUInteger numberOfDownloadableResources = 0;
        for (NSUInteger i = 0; i < count; i++) {
            position = [uriCollectionKeys[i] rangeOfString:@"http-get:*:video/"];
            if (position.location != NSNotFound) {
                correctIndex = i;
                numberOfDownloadableResources++;
            }
        }
        NSArray *uriCollectionObjects = [[mediaItem uriCollection] allValues];

        // Present an action sheet for the user to choose which URI to download. Do not deselect the cell to provide visual feedback to the user
        if (numberOfDownloadableResources > 1) {
            _resourceSelectionActionSheetAnchorView = [tableView cellForRowAtIndexPath:indexPath];
            [self presentResourceSelectionActionSheetForUPnPMediaItem:mediaItem forDownloading:NO];
        } else {
            if (uriCollectionObjects.count > 0) {
                itemURL = [NSURL URLWithString:uriCollectionObjects[correctIndex]];
            }
            if (itemURL) {
                VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
                [appDelegate openMovieFromURL:itemURL];
            }
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - VLCNetworkListCell delegation
- (void)triggerDownloadForCell:(VLCNetworkListCell *)cell
{
    MediaServer1ItemObject *item;
    if ([self.searchDisplayController isActive]) {
        @synchronized(self) {
            item = _searchData[[self.searchDisplayController.searchResultsTableView indexPathForCell:cell].row];
        }
    } else {
        @synchronized(self) {
            item = _mutableObjectList[[self.tableView indexPathForCell:cell].row];
        }
    }

    [self _downloadUPNPFileFromMediaItem:item];
    [cell.statusLabel showStatusMessage:NSLocalizedString(@"DOWNLOADING", nil)];
}

#pragma mark - UPnP specifics

- (void)_downloadUPNPFileFromMediaItem:(MediaServer1ItemObject *)mediaItem
{
    NSURL *itemURL;
    NSArray *uriCollectionKeys = [[mediaItem uriCollection] allKeys];
    NSUInteger count = uriCollectionKeys.count;
    NSRange position;
    NSUInteger correctIndex = 0;
    for (NSUInteger i = 0; i < count; i++) {
        position = [uriCollectionKeys[i] rangeOfString:@"http-get:*:video/"];
        if (position.location != NSNotFound)
            correctIndex = i;
    }
    NSArray *uriCollectionObjects = [[mediaItem uriCollection] allValues];

    if (uriCollectionObjects.count > 0)
        itemURL = [NSURL URLWithString:uriCollectionObjects[correctIndex]];

    if (itemURL) {
        NSString *filename;

        /* there are few crappy UPnP servers who don't reveal the correct file extension, so we use a generic fake (#11123) */
        if (![itemURL.absoluteString isSupportedFormat])
            filename = [mediaItem.title stringByAppendingString:@".vlc"];
        else
            filename = [[mediaItem.title stringByAppendingString:@"."] stringByAppendingString:[[itemURL absoluteString] pathExtension]];

        [[VLCDownloadViewController sharedInstance] addURLToDownloadList:itemURL fileNameOfMedia:filename];
    }
}

#pragma mark - UPnP Multiple Resources

/// Presents an UIActionSheet for the user to choose which <res> resource to play or download. Contains some display code specific to the HDHomeRun devices. Also parses "DLNA.ORG_PN" protocolInfo.
- (void)presentResourceSelectionActionSheetForUPnPMediaItem:(MediaServer1ItemObject *)mediaItem forDownloading:(BOOL)forDownloading {
    NSParameterAssert(mediaItem);

    if (!mediaItem) {
        return;
    }

    // Store it so we can act on the action sheet callback.
    _lastSelectedMediaItem = mediaItem;

    NSArray *uriCollectionKeys = [[_lastSelectedMediaItem uriCollection] allKeys];
    NSArray *uriCollectionObjects = [[_lastSelectedMediaItem uriCollection] allValues];
    NSUInteger count = uriCollectionKeys.count;
    NSRange position;

    NSString *titleString;

    if (!forDownloading) {
        titleString = NSLocalizedString(@"SELECT_RESOURCE_TO_PLAY", nil);
    } else {
        titleString = NSLocalizedString(@"SELECT_RESOURCE_TO_DOWNLOAD", nil);
    }

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:titleString
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];

    // Provide users with a descriptive action sheet for them to choose based on the multiple resources advertised by DLNA devices (HDHomeRun for example)
    for (NSUInteger i = 0; i < count; i++) {
        position = [uriCollectionKeys[i] rangeOfString:@"http-get:*:video/"];

        if (position.location == NSNotFound)
            continue;

        NSString *orgPNValue;
        NSString *transcodeValue;

        // Attempt to parse DLNA.ORG_PN first
        NSString *protocolInfo = uriCollectionKeys[i];
        NSArray *components = [protocolInfo componentsSeparatedByString:@";"];
        NSArray *nonFlagsComponents = [components[0] componentsSeparatedByString:@":"];
        NSString *orgPN = [nonFlagsComponents lastObject];

        // Check to see if we are where we should be
        NSRange orgPNRange = [orgPN rangeOfString:@"DLNA.ORG_PN="];
        if (orgPNRange.location == 0) {
            orgPNValue = [orgPN substringFromIndex:orgPNRange.length];
        }

        // HDHomeRun: Get the transcode profile from the HTTP API if possible
        if ([_UPNPdevice VLC_isHDHomeRunMediaServer]) {
            NSRange transcodeRange = [uriCollectionObjects[i] rangeOfString:@"transcode="];
            if (transcodeRange.location != NSNotFound) {
                transcodeValue = [uriCollectionObjects[i] substringFromIndex:transcodeRange.location + transcodeRange.length];
                // Check that there are no more parameters
                NSRange ampersandRange = [transcodeValue rangeOfString:@"&"];
                if (ampersandRange.location != NSNotFound) {
                    transcodeValue = [transcodeValue substringToIndex:transcodeRange.location];
                }

                transcodeValue = [transcodeValue capitalizedString];
            }
        }

        // Fallbacks to get the most descriptive resource title
        NSString *profileTitle;
        if ([transcodeValue length] && [orgPNValue length]) {
            profileTitle = [NSString stringWithFormat:@"%@ (%@)", transcodeValue, orgPNValue];

            // The extra whitespace is to get UIActionSheet to render the text better (this bug has been fixed in iOS 8)
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
                    profileTitle = [NSString stringWithFormat:@" %@ ", profileTitle];
                }
            }
        } else if ([transcodeValue length]) {
            profileTitle = transcodeValue;
        } else if ([orgPNValue length]) {
            profileTitle = orgPNValue;
        } else if ([uriCollectionKeys[i] length]) {
            profileTitle = uriCollectionKeys[i];
        } else if ([uriCollectionObjects[i] length]) {
            profileTitle = uriCollectionObjects[i];
        } else  {
            profileTitle = NSLocalizedString(@"UNKNOWN", nil);
        }

        [actionSheet addButtonWithTitle:profileTitle];
    }

    // If no resources are found, an empty action sheet will be presented, but the fact that we got here implies that we have playable resources, so no special handling for this case is included
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Attach it to a specific view (a cell, a download button, etc)
        if (_resourceSelectionActionSheetAnchorView) {
            CGRect presentationRect = [self.view convertRect:_resourceSelectionActionSheetAnchorView.frame fromView:_resourceSelectionActionSheetAnchorView.superview];
            [actionSheet showFromRect:presentationRect inView:self.view animated:YES];
        } else {
            [actionSheet showInView:self.view];
        }
    } else {
        [actionSheet showInView:self.view];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Act on the selected resource that the user selected
    if (_lastSelectedMediaItem) {
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            // Check again through our raw list which items are playable, since this same code was used to build the action sheet. Make sure we choose the right object based on the action sheet button index.
            NSArray *uriCollectionKeys = [[_lastSelectedMediaItem uriCollection] allKeys];
            NSArray *uriCollectionObjects = [[_lastSelectedMediaItem uriCollection] allValues];

            if (uriCollectionObjects.count > 0) {
                NSUInteger count = uriCollectionKeys.count;
                NSMutableArray *possibleCollectionObjects = [[NSMutableArray alloc] initWithCapacity:[uriCollectionObjects count]];

                for (NSUInteger i = 0; i < count; i++) {
                    if ([uriCollectionKeys[i] rangeOfString:@"http-get:*:video/"].location != NSNotFound) {
                        [possibleCollectionObjects addObject:uriCollectionObjects[i]];
                    }
                }

                NSString *itemURLString = uriCollectionObjects[buttonIndex];

                if ([itemURLString length]) {
                    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
                    [appDelegate openMovieFromURL:[NSURL URLWithString:itemURLString]];
                }
            }
        }

        _lastSelectedMediaItem = nil;
        _resourceSelectionActionSheetAnchorView = nil;

        UITableView *activeTableView;
        if ([self.searchDisplayController isActive]) {
            activeTableView = self.searchDisplayController.searchResultsTableView;
        } else {
            activeTableView = self.tableView;
        }
        [activeTableView deselectRowAtIndexPath:[activeTableView indexPathForSelectedRow] animated:NO];
    }
}

#pragma mark - search

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    MediaServer1BasicObject *item;
    NSInteger listCount = 0;

    @synchronized(self) {
        [_searchData removeAllObjects];
        listCount = _mutableObjectList.count;

        for (int i = 0; i < listCount; i++) {
            NSRange nameRange;
            item = _mutableObjectList[i];
            nameRange = [[item title] rangeOfString:searchString options:NSCaseInsensitiveSearch];

            if (nameRange.location != NSNotFound)
                [_searchData addObject:_mutableObjectList[i]];
        }
    }

    return YES;
}

@end
