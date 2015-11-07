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

#import "VLCServerBrowsingTVViewController.h"
#import "VLCServerBrowsingTVCell.h"
#import "VLCPlayerDisplayController.h"
#import "VLCPlaybackController.h"
#import "VLCServerBrowsingController.h"
#import "VLCMaskView.h"

@interface VLCServerBrowsingTVViewController ()
@property (nonatomic, readonly) id<VLCNetworkServerBrowser>serverBrowser;
@property (nonatomic) VLCServerBrowsingController *browsingController;
@end

@implementation VLCServerBrowsingTVViewController

- (instancetype)initWithServerBrowser:(id<VLCNetworkServerBrowser>)serverBrowser
{
    self = [super initWithNibName:@"VLCServerBrowsingTVViewController" bundle:nil];
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

    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    const CGFloat inset = 50;
    flowLayout.sectionInset = UIEdgeInsetsMake(inset, inset, inset, inset);
    [self.collectionView registerNib:[UINib nibWithNibName:@"VLCServerBrowsingTVCell" bundle:nil] forCellWithReuseIdentifier:VLCServerBrowsingTVCellIdentifier];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadData)];

    self.collectionView.maskView = [[VLCMaskView alloc] initWithFrame:self.collectionView.bounds];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.serverBrowser update];
}


- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    UICollectionView *collectionView = self.collectionView;
    VLCMaskView *maskView = (VLCMaskView *)collectionView.maskView;
    maskView.maskEnd = self.topLayoutGuide.length * 0.8;

    /*
     Update the position from where the collection view's content should
     start to fade out. The size of the fade increases as the collection
     view scrolls to a maximum of half the navigation bar's height.
     */
    CGFloat maximumMaskStart = maskView.maskEnd + (self.topLayoutGuide.length * 0.5);
    CGFloat verticalScrollPosition = MAX(0, collectionView.contentOffset.y + collectionView.contentInset.top);
    maskView.maskStart = MIN(maximumMaskStart, maskView.maskEnd + verticalScrollPosition);

    /*
     Position the mask view so that it is always fills the visible area of
     the collection view.
     */
    CGSize collectionViewSize = self.collectionView.bounds.size;
    maskView.frame = CGRectMake(0, collectionView.contentOffset.y, collectionViewSize.width, collectionViewSize.height);
    
}

#pragma mark -

- (void)reloadData {
    [self.serverBrowser update];
}

#pragma mark -

- (void)networkServerBrowserDidUpdate:(id<VLCNetworkServerBrowser>)networkBrowser {
    self.title = networkBrowser.title;
    [self.collectionView reloadData];
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
        VLCServerBrowsingTVViewController *targetViewController = [[VLCServerBrowsingTVViewController alloc] initWithServerBrowser:item.containerBrowser];
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


#pragma mark - collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.serverBrowser items].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCServerBrowsingTVCell *cell = (VLCServerBrowsingTVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:VLCServerBrowsingTVCellIdentifier forIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
        id<VLCNetworkServerBrowserItem> item = self.serverBrowser.items[indexPath.row];

    if ([cell conformsToProtocol:@protocol(VLCServerBrowsingCell)]) {
        [self.browsingController configureCell:(id<VLCServerBrowsingCell>)cell withItem:item];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    id<VLCNetworkServerBrowserItem> item = self.serverBrowser.items[row];

    // would make sence if item came from search which isn't
    // currently the case on the TV
    const BOOL singlePlayback = NO;
    [self didSelectItem:item index:row singlePlayback:singlePlayback];
}

@end
