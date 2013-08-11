//
//  VLCLocalServerFolderListViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 10.08.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCLocalServerFolderListViewController.h"
#import "MediaServerBasicObjectParser.h"
#import "MediaServer1ItemObject.h"
#import "MediaServer1ContainerObject.h"
#import "MediaServer1Device.h"
#import "VLCLocalNetworkListCell.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "UINavigationController+Theme.h"

@interface VLCLocalServerFolderListViewController () <UITableViewDataSource, UITableViewDelegate>
{
    UIBarButtonItem *_backButton;

    MediaServer1Device *_device;
    NSString *_header;
    NSString *_rootID;

    NSMutableArray *_objectList;
}

@end

@implementation VLCLocalServerFolderListViewController

- (void)loadView
{
    _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    self.view = _tableView;
}

- (id)initWithDevice:(MediaServer1Device*)device header:(NSString*)header andRootID:(NSString*)rootID
{
    self = [super init];

    if (self) {
        _device = device;
        _header = header;
        _rootID = rootID;

        _objectList = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSMutableString *outResult = [[NSMutableString alloc] init];
    NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
    NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
    NSMutableString *outUpdateID = [[NSMutableString alloc] init];

    [[_device contentDirectory] BrowseWithObjectID:_rootID BrowseFlag:@"BrowseDirectChildren" Filter:@"*" StartingIndex:@"0" RequestedCount:@"0" SortCriteria:@"+dc:title" OutResult:outResult OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];

    [_objectList removeAllObjects];
    NSData *didl = [outResult dataUsingEncoding:NSUTF8StringEncoding];
    MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:_objectList itemsOnly:NO];
    [parser parseFromData:didl];

    self.tableView.separatorColor = [UIColor colorWithWhite:.122 alpha:1.];
    self.view.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];

    self.title = _header;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objectList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalNetworkCellDetail";

    VLCLocalNetworkListCell *cell = (VLCLocalNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCLocalNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    MediaServer1BasicObject *item = _objectList[indexPath.row];

    if (![item isContainer]) {
        MediaServer1ItemObject *mediaItem = _objectList[indexPath.row];
        [cell setSubtitle: [NSString stringWithFormat:@"%0.2f MB", (float)([mediaItem.size intValue] / 1e6)]];
        [cell setIsDirectory:NO];
        [cell setIcon:[UIImage imageNamed:@"blank"]];
    } else {
        [cell setIsDirectory:YES];
        [cell setIcon:[UIImage imageNamed:@"folder"]];
    }

    [cell setTitle:[item title]];

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor colorWithWhite:.122 alpha:1.];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaServer1BasicObject *item = _objectList[indexPath.row];
    if ([item isContainer]) {
        MediaServer1ContainerObject *container = _objectList[indexPath.row];
        VLCLocalServerFolderListViewController *targetViewController = [[VLCLocalServerFolderListViewController alloc] initWithDevice:_device header:[container title] andRootID:[container objectID]];
        [[self navigationController] pushViewController:targetViewController animated:YES];
    } else {
        MediaServer1ItemObject *item = _objectList[indexPath.row];

        MediaServer1ItemRes *resource = nil;
        NSEnumerator *e = [[item resources] objectEnumerator];
        NSURL *itemURL;
        while((resource = (MediaServer1ItemRes*)[e nextObject])){
            APLog(@"%@ - %d, %@, %d, %d, %d, %@ (%@)", [item title], [resource bitrate], [resource duration], [resource nrAudioChannels], [resource size],  [resource durationInSeconds],  [resource protocolInfo], [item uri]);
            itemURL = [NSURL URLWithString:[item uri]];
        }

        if (itemURL && ([itemURL.scheme isEqualToString:@"http"] || [itemURL.scheme isEqualToString:@"rtsp"] || [itemURL.scheme isEqualToString:@"rtp"] || [itemURL.scheme isEqualToString:@"mms"] || [itemURL.scheme isEqualToString:@"mmsh"])) {
            VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;

            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:appDelegate.playlistViewController];
            [navController loadTheme];

            appDelegate.revealController.contentViewController = navController;
            [appDelegate.revealController toggleSidebar:NO duration:kGHRevealSidebarDefaultAnimationDuration];

            [appDelegate.playlistViewController performSelector:@selector(openMovieFromURL:) withObject:itemURL afterDelay:kGHRevealSidebarDefaultAnimationDuration];
        }
    }
}

@end
