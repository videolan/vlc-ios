/*****************************************************************************
 * VLCLocalServerFolderListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalServerFolderListViewController.h"
#import "MediaServerBasicObjectParser.h"
#import "MediaServer1ItemObject.h"
#import "MediaServer1ContainerObject.h"
#import "MediaServer1Device.h"
#import "VLCLocalNetworkListCell.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "UINavigationController+Theme.h"
#import "VLCDownloadViewController.h"
#import "WhiteRaccoon.h"
#import "NSString+SupportedMedia.h"
#import "VLCStatusLabel.h"
#import "BasicUPnPDevice+VLC.h"
#import "UIBarButtonItem+Theme.h"
#import "UIDevice+VLC.h"

#define kVLCServerTypeUPNP 0
#define kVLCServerTypeFTP 1

@interface VLCLocalServerFolderListViewController () <UITableViewDataSource, UITableViewDelegate, WRRequestDelegate, VLCLocalNetworkListCell, UISearchBarDelegate, UISearchDisplayDelegate, UIActionSheetDelegate>
{
    /* UI */
    UIBarButtonItem *_menuButton;

    /* generic data storage */
    NSString *_listTitle;
    NSArray *_objectList;
    NSMutableArray *_mutableObjectList;
    NSUInteger _serverType;

    /* UPNP specifics */
    MediaServer1Device *_UPNPdevice;
    NSString *_UPNProotID;

    /* FTP specifics */
    NSString *_ftpServerAddress;
    NSString *_ftpServerUserName;
    NSString *_ftpServerPassword;
    NSString *_ftpServerPath;
    WRRequestListDirectory *_FTPListDirRequest;

    NSMutableArray *_searchData;
    UISearchBar *_searchBar;
    UISearchDisplayController *_searchDisplayController;

    /* UPnP items with multiple resources specifics */
    MediaServer1ItemObject *_lastSelectedMediaItem;
    UIView *_resourceSelectionActionSheetAnchorView;
}

@end

@implementation VLCLocalServerFolderListViewController

- (void)loadView
{
    _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = [VLCLocalNetworkListCell heightOfCell];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.view = _tableView;
}

- (id)initWithUPNPDevice:(MediaServer1Device*)device header:(NSString*)header andRootID:(NSString*)rootID
{
    self = [super init];

    if (self) {
        _UPNPdevice = device;
        _listTitle = header;
        _UPNProotID = rootID;
        _serverType = kVLCServerTypeUPNP;
        _mutableObjectList = [[NSMutableArray alloc] init];
    }

    return self;
}

- (id)initWithFTPServer:(NSString *)serverAddress userName:(NSString *)username andPassword:(NSString *)password atPath:(NSString *)path
{
    self = [super init];

    if (self) {
        _ftpServerAddress = serverAddress;
        _ftpServerUserName = username;
        _ftpServerPassword = password;
        _ftpServerPath = path;
        _serverType = kVLCServerTypeFTP;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (_serverType == kVLCServerTypeUPNP) {
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

        [_mutableObjectList removeAllObjects];
        NSData *didl = [outResult dataUsingEncoding:NSUTF8StringEncoding];
        MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:_mutableObjectList itemsOnly:NO];
        [parser parseFromData:didl];
    } else if (_serverType == kVLCServerTypeFTP) {
        if ([_ftpServerPath isEqualToString:@"/"])
            _listTitle = _ftpServerAddress;
        else
            _listTitle = [_ftpServerPath lastPathComponent];
        [self _listFTPDirectory];
    }

    self.tableView.separatorColor = [UIColor VLCDarkBackgroundColor];
    self.view.backgroundColor = [UIColor VLCDarkBackgroundColor];

    self.title = _listTitle;

    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        _searchBar.barTintColor = navBar.barTintColor;
    _searchBar.tintColor = navBar.tintColor;
    _searchBar.translucent = navBar.translucent;
    _searchBar.opaque = navBar.opaque;
    _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
    _searchDisplayController.delegate = self;
    _searchDisplayController.searchResultsDataSource = self;
    _searchDisplayController.searchResultsDelegate = self;
    _searchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _searchDisplayController.searchResultsTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        _searchDisplayController.searchBar.searchBarStyle = UIBarStyleBlack;
    _searchBar.delegate = self;
    _searchBar.hidden = YES;

    UITapGestureRecognizer *tapTwiceGesture = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(tapTwiceGestureAction:)];
    [tapTwiceGesture setNumberOfTapsRequired:2];
    [self.navigationController.navigationBar addGestureRecognizer:tapTwiceGesture];

    _menuButton = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(menuButtonAction:)];
    self.navigationItem.rightBarButtonItem = _menuButton;

    _searchData = [[NSMutableArray alloc] init];
    [_searchData removeAllObjects];
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

- (IBAction)menuButtonAction:(id)sender
{
    [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController] toggleSidebar:![(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController].sidebarShowing duration:kGHRevealSidebarDefaultAnimationDuration];

    if (self.isEditing)
        [self setEditing:NO animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return _searchData.count;
    else {
        if (_serverType == kVLCServerTypeUPNP)
            return _mutableObjectList.count;

        return _objectList.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalNetworkCellDetail";

    VLCLocalNetworkListCell *cell = (VLCLocalNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCLocalNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    if (_serverType == kVLCServerTypeUPNP) {
        MediaServer1BasicObject *item;
        if (tableView == self.searchDisplayController.searchResultsTableView)
            item = _searchData[indexPath.row];
        else
            item = _mutableObjectList[indexPath.row];

        if (![item isContainer]) {
            MediaServer1ItemObject *mediaItem;
            long long mediaSize = 0;
            unsigned int durationInSeconds = 0;
            unsigned int bitrate = 0;

            if (tableView == self.searchDisplayController.searchResultsTableView)
                mediaItem = _searchData[indexPath.row];
            else
                mediaItem = _mutableObjectList[indexPath.row];

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
    } else if (_serverType == kVLCServerTypeFTP) {
        NSMutableArray *ObjList = [[NSMutableArray alloc] init];
        [ObjList removeAllObjects];

        if (tableView == self.searchDisplayController.searchResultsTableView)
            [ObjList addObjectsFromArray:_searchData];
        else
            [ObjList addObjectsFromArray:_objectList];

        NSString *rawFileName = [ObjList[indexPath.row] objectForKey:(id)kCFFTPResourceName];
        NSData *flippedData = [rawFileName dataUsingEncoding:[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingFTPTextEncoding] intValue] allowLossyConversion:YES];
        cell.title = [[NSString alloc] initWithData:flippedData encoding:NSUTF8StringEncoding];

        if ([[ObjList[indexPath.row] objectForKey:(id)kCFFTPResourceType] intValue] == 4) {
            cell.isDirectory = YES;
            cell.icon = [UIImage imageNamed:@"folder"];
        } else {
            cell.isDirectory = NO;
            cell.icon = [UIImage imageNamed:@"blank"];
            cell.subtitle = [NSString stringWithFormat:@"%0.2f MB", (float)([[ObjList[indexPath.row] objectForKey:(id)kCFFTPResourceSize] intValue] / 1e6)];
            cell.isDownloadable = YES;
            cell.delegate = self;
        }
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCLocalNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *color = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor VLCDarkBackgroundColor];
    cell.contentView.backgroundColor = cell.titleLabel.backgroundColor = cell.folderTitleLabel.backgroundColor = cell.subtitleLabel.backgroundColor =  color;

    if (_serverType == kVLCServerTypeFTP)
        if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row)
            [(VLCAppDelegate*)[UIApplication sharedApplication].delegate networkActivityStopped];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_serverType == kVLCServerTypeUPNP) {
        MediaServer1BasicObject *item;
        if (tableView == self.searchDisplayController.searchResultsTableView)
            item = _searchData[indexPath.row];
        else
            item = _mutableObjectList[indexPath.row];

        if ([item isContainer]) {
            MediaServer1ContainerObject *container;
            if (tableView == self.searchDisplayController.searchResultsTableView)
                container = _searchData[indexPath.row];
            else
                container = _mutableObjectList[indexPath.row];

            VLCLocalServerFolderListViewController *targetViewController = [[VLCLocalServerFolderListViewController alloc] initWithUPNPDevice:_UPNPdevice header:[container title] andRootID:[container objectID]];
            [[self navigationController] pushViewController:targetViewController animated:YES];
        } else {
            MediaServer1ItemObject *mediaItem;

            if (tableView == self.searchDisplayController.searchResultsTableView)
                mediaItem = _searchData[indexPath.row];
            else
                mediaItem = _mutableObjectList[indexPath.row];

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
    } else if (_serverType == kVLCServerTypeFTP) {
        NSMutableArray *ObjList = [[NSMutableArray alloc] init];
        [ObjList removeAllObjects];

        if (tableView == self.searchDisplayController.searchResultsTableView)
            [ObjList addObjectsFromArray:_searchData];
        else
            [ObjList addObjectsFromArray:_objectList];

        if ([[ObjList[indexPath.row] objectForKey:(id)kCFFTPResourceType] intValue] == 4) {
            NSString *newPath = [NSString stringWithFormat:@"%@/%@", _ftpServerPath, [ObjList[indexPath.row] objectForKey:(id)kCFFTPResourceName]];

            VLCLocalServerFolderListViewController *targetViewController = [[VLCLocalServerFolderListViewController alloc] initWithFTPServer:_ftpServerAddress userName:_ftpServerUserName andPassword:_ftpServerPassword atPath:newPath];
            [self.navigationController pushViewController:targetViewController animated:YES];
        } else {
            NSString *rawObjectName = [ObjList[indexPath.row] objectForKey:(id)kCFFTPResourceName];
            NSData *flippedData = [rawObjectName dataUsingEncoding:[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingFTPTextEncoding] intValue] allowLossyConversion:YES];
            NSString *properObjectName = [[NSString alloc] initWithData:flippedData encoding:NSUTF8StringEncoding];
            if (![properObjectName isSupportedFormat]) {
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil) message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), properObjectName] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:nil];
                [alert show];
            } else
                [self _streamFTPFile:properObjectName];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
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
        if (position.location != NSNotFound) {
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

#pragma mark - FTP specifics
- (void)_listFTPDirectory
{
    if (_FTPListDirRequest)
        return;

    _FTPListDirRequest = [[WRRequestListDirectory alloc] init];
    _FTPListDirRequest.delegate = self;
    _FTPListDirRequest.hostname = _ftpServerAddress;
    _FTPListDirRequest.username = _ftpServerUserName;
    _FTPListDirRequest.password = _ftpServerPassword;
    _FTPListDirRequest.path = _ftpServerPath;
    _FTPListDirRequest.passive = YES;

    [(VLCAppDelegate*)[UIApplication sharedApplication].delegate networkActivityStarted];
    [_FTPListDirRequest start];
}

- (NSString *)_credentials
{
    NSString * cred;

    if (_ftpServerUserName.length > 0) {
        if (_ftpServerPassword.length > 0)
            cred = [NSString stringWithFormat:@"%@:%@@", _ftpServerUserName, _ftpServerPassword];
        else
            cred = [NSString stringWithFormat:@"%@@", _ftpServerPassword];
    } else
        cred = @"";

    return [cred stringByStandardizingPath];
}

- (void)_downloadFTPFile:(NSString *)fileName
{
    NSURL *URLToQueue = [NSURL URLWithString:[[@"ftp" stringByAppendingFormat:@"://%@%@/%@/%@", [self _credentials], _ftpServerAddress, _ftpServerPath, fileName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate downloadViewController] addURLToDownloadList:URLToQueue fileNameOfMedia:nil];
}

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

    if (![itemURL.absoluteString isSupportedFormat]) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil) message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), [mediaItem uri]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:nil];
        [alert show];
    } else if (itemURL) {
        NSString *fileName = [[mediaItem.title stringByAppendingString:@"."] stringByAppendingString:[[itemURL absoluteString] pathExtension]];
        [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate downloadViewController] addURLToDownloadList:itemURL fileNameOfMedia:fileName];
    }
}

- (void)requestCompleted:(WRRequest *)request
{
    if (request == _FTPListDirRequest) {
        NSMutableArray *filteredList = [[NSMutableArray alloc] init];
        NSArray *rawList = [(WRRequestListDirectory*)request filesInfo];
        NSUInteger count = rawList.count;

        for (NSUInteger x = 0; x < count; x++) {
            if (![[rawList[x] objectForKey:(id)kCFFTPResourceName] hasPrefix:@"."])
                [filteredList addObject:rawList[x]];
        }

        _objectList = [NSArray arrayWithArray:filteredList];
        [self.tableView reloadData];
    } else
        APLog(@"unknown request %@ completed", request);
}

- (void)requestFailed:(WRRequest *)request
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_TITLE", nil) message:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_MESSAGE", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:nil];
    [alert show];

    APLog(@"request %@ failed with error %i", request, request.error.errorCode);
}

#pragma mark - VLCLocalNetworkListCell delegation
- (void)triggerDownloadForCell:(VLCLocalNetworkListCell *)cell
{
    if (_serverType == kVLCServerTypeUPNP) {
        MediaServer1ItemObject *item;
        if ([self.searchDisplayController isActive])
            item = _searchData[[self.searchDisplayController.searchResultsTableView indexPathForCell:cell].row];
        else
            item = _mutableObjectList[[self.tableView indexPathForCell:cell].row];

        [self _downloadUPNPFileFromMediaItem:item];
        [cell.statusLabel showStatusMessage:NSLocalizedString(@"DOWNLOADING", nil)];
    }else if (_serverType == kVLCServerTypeFTP) {
        NSString *rawObjectName;
        NSInteger size;
        NSMutableArray *ObjList = [[NSMutableArray alloc] init];
        [ObjList removeAllObjects];

        if ([self.searchDisplayController isActive]) {
            [ObjList addObjectsFromArray:_searchData];
            rawObjectName = [ObjList[[self.searchDisplayController.searchResultsTableView indexPathForCell:cell].row] objectForKey:(id)kCFFTPResourceName];
            size = [[ObjList[[self.searchDisplayController.searchResultsTableView indexPathForCell:cell].row] objectForKey:(id)kCFFTPResourceSize] intValue];
        } else {
            [ObjList addObjectsFromArray:_objectList];
            rawObjectName = [ObjList[[self.tableView indexPathForCell:cell].row] objectForKey:(id)kCFFTPResourceName];
            size = [[ObjList[[self.tableView indexPathForCell:cell].row] objectForKey:(id)kCFFTPResourceSize] intValue];
        }

        NSData *flippedData = [rawObjectName dataUsingEncoding:[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingFTPTextEncoding] intValue] allowLossyConversion:YES];
        NSString *properObjectName = [[NSString alloc] initWithData:flippedData encoding:NSUTF8StringEncoding];
        if (![properObjectName isSupportedFormat]) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil) message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), properObjectName] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:nil];
            [alert show];
        } else {
            if (size  < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
                [self _downloadFTPFile:properObjectName];
                [cell.statusLabel showStatusMessage:NSLocalizedString(@"DOWNLOADING", nil)];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), properObjectName, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil];
                [alert show];
            }
        }
    }
}

#pragma mark - communication with playback engine
- (void)_streamFTPFile:(NSString *)fileName
{
    NSString *URLofSubtitle = nil;
    NSMutableArray *SubtitlesList = [[NSMutableArray alloc] init];
    [SubtitlesList removeAllObjects];
    SubtitlesList = [self _searchSubtitle:fileName];

    if(SubtitlesList.count > 0)
       URLofSubtitle = [self _getFileSubtitleFromFtpServer:SubtitlesList[0]];

    NSURL *URLToPlay = [NSURL URLWithString:[[@"ftp" stringByAppendingFormat:@"://%@%@/%@/%@", [self _credentials], _ftpServerAddress, _ftpServerPath, fileName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate openMovieWithExternalSubtitleFromURL:URLToPlay externalSubURL:URLofSubtitle];
}

- (NSMutableArray *)_searchSubtitle:(NSString *)url
{
    NSString *urlTemp = [[url lastPathComponent] stringByDeletingPathExtension];
    NSMutableArray *ObjList = [[NSMutableArray alloc] init];
    [ObjList removeAllObjects];
    for (int loop = 0; loop < _objectList.count; loop++)
        [ObjList addObject:[_objectList[loop] objectForKey:(id)kCFFTPResourceName]];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", urlTemp];
    NSArray *results = [ObjList filteredArrayUsingPredicate:predicate];

    [ObjList removeAllObjects];

    for (int cnt = 0; cnt < results.count; cnt++) {
        if ([results[cnt] isSupportedSubtitleFormat])
            [ObjList addObject:results[cnt]];
    }
    return ObjList;
}

- (NSString *)_getFileSubtitleFromFtpServer:(NSString *)fileName
{
    NSURL *url = [NSURL URLWithString:[[@"ftp" stringByAppendingFormat:@"://%@%@/%@/%@", [self _credentials], _ftpServerAddress, _ftpServerPath, fileName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    NSString *receivedSub = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:nil];
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = searchPaths[0];
    NSString *FileSubtitlePath = [directoryPath stringByAppendingPathComponent:[fileName lastPathComponent]];

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

#pragma mark - Search Display Controller Delegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    MediaServer1BasicObject *item;
    NSInteger listCount = 0;
    [_searchData removeAllObjects];

    if (_serverType == kVLCServerTypeUPNP)
        listCount = _mutableObjectList.count;
    else if (_serverType == kVLCServerTypeFTP)
        listCount = _objectList.count;

    for (int i = 0; i < listCount; i++) {
        NSRange nameRange;
        if (_serverType == kVLCServerTypeUPNP) {
            item = _mutableObjectList[i];
            nameRange = [[item title] rangeOfString:searchString options:NSCaseInsensitiveSearch];
        } else if (_serverType == kVLCServerTypeFTP) {
            NSString *rawObjectName = [_objectList[i] objectForKey:(id)kCFFTPResourceName];
            NSData *flippedData = [rawObjectName dataUsingEncoding:[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingFTPTextEncoding] intValue] allowLossyConversion:YES];
            NSString *properObjectName = [[NSString alloc] initWithData:flippedData encoding:NSUTF8StringEncoding];
            nameRange = [properObjectName rangeOfString:searchString options:NSCaseInsensitiveSearch];
        }

        if (nameRange.location != NSNotFound) {
            if (_serverType == kVLCServerTypeUPNP)
                [_searchData addObject:_mutableObjectList[i]];
            else
                [_searchData addObject:_objectList[i]];
        }
    }

    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        tableView.rowHeight = 80.0f;
    else
        tableView.rowHeight = 68.0f;

    tableView.backgroundColor = [UIColor blackColor];
}

#pragma mark - Gesture Action

- (void)tapTwiceGestureAction:(UIGestureRecognizer *)recognizer
{
    _searchBar.hidden = !_searchBar.hidden;
    if (_searchBar.hidden)
        self.tableView.tableHeaderView = nil;
    else
        self.tableView.tableHeaderView = _searchBar;

    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:NO];
}

@end
