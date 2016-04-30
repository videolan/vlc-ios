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
#import "GRKArrayDiff+UICollectionView.h"

@interface VLCServerBrowsingTVViewController ()
{
    UILabel *_nothingFoundLabel;
}
@property (nonatomic) VLCServerBrowsingController *browsingController;
@property (nonatomic) NSArray<id <VLCNetworkServerBrowserItem>> *items;
@end

@implementation VLCServerBrowsingTVViewController
@synthesize subdirectoryBrowserClass = _subdirectoryBrowserClass;

- (instancetype)initWithServerBrowser:(id<VLCNetworkServerBrowser>)serverBrowser
{
    self = [super initWithNibName:@"VLCRemoteBrowsingCollectionViewController" bundle:nil];
    if (self) {
        _serverBrowser = serverBrowser;
        serverBrowser.delegate = self;

        _browsingController = [[VLCServerBrowsingController alloc] initWithViewController:self serverBrowser:serverBrowser];

        self.title = serverBrowser.title;

        self.downloadArtwork = [[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingDownloadArtwork];
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

- (void)setSubdirectoryBrowserClass:(Class)subdirectoryBrowserClass
{
    NSParameterAssert([subdirectoryBrowserClass isSubclassOfClass:[VLCServerBrowsingTVViewController class]]);
    _subdirectoryBrowserClass = subdirectoryBrowserClass;
}

- (Class)subdirectoryBrowserClass
{
    return _subdirectoryBrowserClass ?: [self class];
}

#pragma mark -

- (void)reloadData
{
    [self.serverBrowser update];
}

#pragma mark - VLCNetworkServerBrowserDelegate

- (void)networkServerBrowserDidUpdate:(id<VLCNetworkServerBrowser>)networkBrowser
{
    self.title = networkBrowser.title;

    NSArray *oldItems = self.items;
    NSArray *newItems = networkBrowser.items;
    GRKArrayDiff *diff = [[GRKArrayDiff alloc] initWithPreviousArray:oldItems
                                                        currentArray:newItems
                                                       identityBlock:^NSString * _Nullable(id <VLCNetworkServerBrowserItem> item) {
                                                           return [NSString stringWithFormat:@"%@#%@",item.URL.absoluteString ?: @"", item.name];
                                                       }
                                                       modifiedBlock:nil];

    [diff performBatchUpdatesWithCollectionView:self.collectionView
                                        section:0
                               dataSourceUpdate:^{
                                   self.items = newItems;
                               } completion:nil];

    _nothingFoundLabel.hidden = self.items.count > 0;
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
        VLCServerBrowsingTVViewController *targetViewController = [[self.subdirectoryBrowserClass alloc] initWithServerBrowser:item.containerBrowser];
        [self showViewController:targetViewController sender:self];
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
    NSInteger count = self.items.count;
    self.nothingFoundView.hidden = count > 0;
    return count;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *items = self.items;
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
    id<VLCNetworkServerBrowserItem> item = self.items[row];

    // would make sence if item came from search which isn't
    // currently the case on the TV
    const BOOL singlePlayback = ![[NSUserDefaults standardUserDefaults] boolForKey:kVLCAutomaticallyPlayNextItem];
    [self didSelectItem:item index:row singlePlayback:singlePlayback];
}

@end
