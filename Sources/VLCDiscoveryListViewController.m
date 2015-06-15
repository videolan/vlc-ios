//
//  VLCDiscoveryListViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 15/06/15.
//  Copyright © 2015 VideoLAN. All rights reserved.
//

#import "VLCDiscoveryListViewController.h"
#import "VLCNetworkListCell.h"

@interface VLCDiscoveryListViewController () <VLCNetworkListCellDelegate, UITableViewDataSource, UITableViewDelegate, VLCMediaDelegate>
{
    VLCMediaList *_mediaList;
    VLCMedia *rootMedia;
}

@end

@implementation VLCDiscoveryListViewController

- (instancetype)initWithMedia:(VLCMedia *)media
{
    self = [super init];

    if (!self)
        return self;

    _mediaList = [media subitems];
    self.title = [media metadataForKey:VLCMetaInformationTitle];

    NSLog(@"media meta %@", media.metaDictionary);

    NSLog(@"count %lu", _mediaList.count);

    rootMedia = media;

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];

    [rootMedia setDelegate:self];
    [rootMedia parseWithOptions:VLCMediaParseNetwork | VLCMediaFetchNetwork];
}

#pragma mark - media delegate

- (void)mediaDidFinishParsing:(VLCMedia *)aMedia
{
    NSLog(@"finished parsing %@, sub items %@", aMedia, [aMedia subitems]);
}

- (void)mediaMetaDataDidChange:(VLCMedia *)aMedia
{
    NSLog(@"metadata changed %@, meta %@", aMedia, [aMedia metaDictionary]);
}

#pragma mark - table view data source, for more see super

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _mediaList.count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DiscoveryCell";

    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                                                     forIndexPath:indexPath];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    VLCMedia *cellObject = [_mediaList mediaAtIndex:indexPath.row];
    cell.isDirectory = cellObject.mediaType == VLCMediaTypeDirectory;
    cell.isDownloadable = NO;
    cell.title = [cellObject metadataForKey:VLCMetaInformationTitle];
    cell.subtitle = cellObject.url.absoluteString;

    return cell;
}

- (void)triggerDownloadForCell:(VLCNetworkListCell *)cell
{
    NSLog(@"downloads not implemented");
}

@end
