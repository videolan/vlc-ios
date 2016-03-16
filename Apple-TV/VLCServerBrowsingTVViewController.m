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
#import "VLCRemoteBrowsingTVCell.h"
#import "VLCPlayerDisplayController.h"
#import "VLCPlaybackController.h"
#import "VLCServerBrowsingController.h"
#import "VLCMaskView.h"

@interface VLCServerBrowsingTVViewController ()
{
    UILabel *_nothingFoundLabel;
    NSIndexPath *_currentFocus;
    BOOL _focusChangeAllowed;
}
@property (nonatomic, readonly) id<VLCNetworkServerBrowser>serverBrowser;
@property (nonatomic) VLCServerBrowsingController *browsingController;
@end

@implementation VLCServerBrowsingTVViewController

- (instancetype)initWithServerBrowser:(id<VLCNetworkServerBrowser>)serverBrowser
{
    self = [super initWithNibName:@"VLCRemoteBrowsingCollectionViewController" bundle:nil];
    if (self) {
        _serverBrowser = serverBrowser;
        serverBrowser.delegate = self;

        _browsingController = [[VLCServerBrowsingController alloc] initWithViewController:self serverBrowser:serverBrowser];

        self.title = serverBrowser.title;

        self.downloadArtwork = [[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingDownloadArtwork];

        _currentFocus = [NSIndexPath indexPathForRow:0 inSection:0];
        _focusChangeAllowed = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.nothingFoundLabel.text = NSLocalizedString(@"FOLDER_EMPTY", nil);
    [self.nothingFoundLabel sizeToFit];
    UIView *nothingFoundView = self.nothingFoundView;
    [nothingFoundView sizeToFit];
    [nothingFoundView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:nothingFoundView];

    NSLayoutConstraint *yConstraint = [NSLayoutConstraint constraintWithItem:nothingFoundView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:yConstraint];
    NSLayoutConstraint *xConstraint = [NSLayoutConstraint constraintWithItem:nothingFoundView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:xConstraint];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.serverBrowser update];
}

#pragma mark -

- (void)reloadData
{
    [self.serverBrowser update];
}

#pragma mark -

- (void)networkServerBrowserDidUpdate:(id<VLCNetworkServerBrowser>)networkBrowser
{
    self.title = networkBrowser.title;
    [self.collectionView reloadData];
    _nothingFoundLabel.hidden = [self.serverBrowser items].count > 0;
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
    NSInteger count = [self.serverBrowser items].count;
    self.nothingFoundView.hidden = count > 0;
    return count;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *items = self.serverBrowser.items;
    NSInteger row = indexPath.row;
    if (row < items.count) {
        id<VLCNetworkServerBrowserItem> item = items[row];

        if ([cell isKindOfClass:[VLCRemoteBrowsingTVCell class]]) {
            ((VLCRemoteBrowsingTVCell *) cell).downloadArtwork = self.downloadArtwork;
        }

        if ([cell conformsToProtocol:@protocol(VLCRemoteBrowsingCell)]) {
            [self.browsingController configureCell:(id<VLCRemoteBrowsingCell>)cell withItem:item];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    id<VLCNetworkServerBrowserItem> item = self.serverBrowser.items[row];

    // would make sence if item came from search which isn't
    // currently the case on the TV
    const BOOL singlePlayback = ![[NSUserDefaults standardUserDefaults] boolForKey:kVLCAutomaticallyPlayNextItem];
    [self didSelectItem:item index:row singlePlayback:singlePlayback];
}

#pragma mark - focus recovery workaround

- (void)collectionView:(UICollectionView *)collectionView didUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    if (context.previouslyFocusedIndexPath == nil && context.nextFocusedIndexPath != nil)
        [self setNeedsFocusUpdate];

    if (context.previouslyFocusedIndexPath != nil && context.nextFocusedIndexPath != nil)
        _currentFocus = context.nextFocusedIndexPath;

    _focusChangeAllowed = context.nextFocusedIndexPath != nil;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canFocusItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _focusChangeAllowed || [_currentFocus compare:indexPath] == NSOrderedSame;
}

- (NSIndexPath *)indexPathForPreferredFocusedViewInCollectionView:(UICollectionView *)collectionView
{
    return _currentFocus;
}

@end
