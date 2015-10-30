/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCServerBrowsingTVTableViewController.h"
#import "VLCServerBrowsingTVCell.h"
#import "VLCPlayerDisplayController.h"
#import "VLCPlaybackController.h"
#import "VLCServerBrowsingController.h"

@interface VLCServerBrowsingTVTableViewController ()
@property (nonatomic, readonly) id<VLCNetworkServerBrowser>serverBrowser;
@property (nonatomic) VLCServerBrowsingController *browsingController;

@end

@implementation VLCServerBrowsingTVTableViewController

- (instancetype)initWithServerBrowser:(id<VLCNetworkServerBrowser>)serverBrowser
{
    self = [super init];
    if (self) {
        _serverBrowser = serverBrowser;
        serverBrowser.delegate = self;

        _browsingController = [[VLCServerBrowsingController alloc] initWithViewController:self serverBrowser:serverBrowser];

        self.title = serverBrowser.title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 150;
    [self.tableView registerNib:[UINib nibWithNibName:@"VLCServerBrowsingTVCell" bundle:nil] forCellReuseIdentifier:VLCServerBrowsingTVCellIdentifier];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadData)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.serverBrowser update];
}

#pragma mark -

- (void)reloadData {
    [self.serverBrowser update];
}

#pragma mark -

- (void)networkServerBrowserDidUpdate:(id<VLCNetworkServerBrowser>)networkBrowser {
    self.title = networkBrowser.title;
    [self.tableView reloadData];
}

- (void)networkServerBrowser:(id<VLCNetworkServerBrowser>)networkBrowser requestDidFailWithError:(NSError *)error {

    [self vlc_showAlertWithTitle:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_TITLE", nil)
                         message:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_MESSAGE", nil)
                     buttonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)];
}

#pragma mark -

- (void)didSelectItem:(id<VLCNetworkServerBrowserItem>)item index:(NSUInteger)index singlePlayback:(BOOL)singlePlayback
{
    if (item.isContainer) {
        VLCServerBrowsingTVTableViewController *targetViewController = [[VLCServerBrowsingTVTableViewController alloc] initWithServerBrowser:item.containerBrowser];
        [self.navigationController pushViewController:targetViewController animated:YES];
    } else {
        if (singlePlayback) {
            [self.browsingController streamFileForItem:item];
        } else {
            VLCMediaList *mediaList = self.serverBrowser.mediaList;
            [self.browsingController configureSubtitlesInMediaList:mediaList];
            [self.browsingController streamMediaList:mediaList startingAtIndex:index];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.serverBrowser items].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCServerBrowsingTVCell *cell = (VLCServerBrowsingTVCell *)[tableView dequeueReusableCellWithIdentifier:VLCServerBrowsingTVCellIdentifier];
    if (!cell) {
        cell = [[VLCServerBrowsingTVCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:VLCServerBrowsingTVCellIdentifier];
    }
    id<VLCNetworkServerBrowserItem> item = self.serverBrowser.items[indexPath.row];

    [self.browsingController configureCell:cell withItem:item];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    id<VLCNetworkServerBrowserItem> item = self.serverBrowser.items[row];

    // would make sence if item came from search which isn't
    // currently the case on the TV
    const BOOL singlePlayback = NO;
    [self didSelectItem:item index:row singlePlayback:singlePlayback];
}

@end
