/*****************************************************************************
 * VLCDiscoveryListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDiscoveryListViewController.h"
#import "VLCNetworkListCell.h"
#import "VLCPlaybackController.h"

@interface VLCDiscoveryListViewController () <UITableViewDataSource, UITableViewDelegate, VLCMediaListDelegate>
{
    VLCMediaList *_mediaList;
    VLCMedia *_rootMedia;
    NSDictionary *_mediaOptions;
}

@end

@implementation VLCDiscoveryListViewController

- (instancetype)initWithMedia:(VLCMedia *)media options:(NSDictionary *)options
{
    self = [super init];

    if (!self)
        return self;

    _rootMedia = media;
    [_rootMedia parseWithOptions:VLCMediaParseNetwork];

    _mediaList = [_rootMedia subitems];
    _mediaList.delegate = self;

    self.title = [_rootMedia metadataForKey:VLCMetaInformationTitle];

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}


#pragma mark - media list delegate
- (void)mediaList:(VLCMediaList *)aMediaList mediaAdded:(VLCMedia *)media atIndex:(NSInteger)index
{
    [media parseWithOptions:VLCMediaParseNetwork];
    [self.tableView reloadData];
}

- (void)mediaList:(VLCMediaList *)aMediaList mediaRemovedAtIndex:(NSInteger)index
{
    [self.tableView reloadData];
}

#pragma mark - table view data source, for more see super

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _mediaList.count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:VLCNetworkListCellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:VLCNetworkListCellIdentifier];

    VLCMedia *cellObject = [_mediaList mediaAtIndex:indexPath.row];
    if (cellObject.mediaType == VLCMediaTypeDirectory) {
        cell.isDirectory = YES;
        cell.icon = [UIImage imageNamed:@"folder"];
    } else {
        cell.isDirectory = NO;
        cell.icon = [UIImage imageNamed:@"blank"];
    }

    cell.isDownloadable = NO;

    NSString *title = [cellObject metadataForKey:VLCMetaInformationTitle];
    if (!title)
        title = cellObject.url.lastPathComponent;
    if (!title)
        title = cellObject.url.absoluteString;
    cell.title = [cellObject metadataForKey:VLCMetaInformationTitle];
    cell.subtitle = cellObject.url.absoluteString;

    return cell;
}

#pragma mark - table view delegation

- (void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger row = indexPath.row;

    VLCMedia *cellMedia = [_mediaList mediaAtIndex:row];

    if (cellMedia.mediaType == VLCMediaTypeDirectory) {
        [cellMedia parseWithOptions:VLCMediaParseNetwork];
        [cellMedia addOptions:_mediaOptions];

        VLCDiscoveryListViewController *targetViewController = [[VLCDiscoveryListViewController alloc]
                                                                initWithMedia:cellMedia
                                                                options:_mediaOptions];
        [[self navigationController] pushViewController:targetViewController animated:YES];
    } else {
        VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
        [vpc playMediaList:_mediaList firstIndex:(int)row];
    }
}

@end
