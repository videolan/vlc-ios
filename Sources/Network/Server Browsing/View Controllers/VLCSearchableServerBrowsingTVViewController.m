/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSearchableServerBrowsingTVViewController.h"
#import "VLCNetworkServerSearchBrowser.h"
#import "VLCSearchController.h"
#import "VLCIRTVTapGestureRecognizer.h"

static NSString * const VLCSearchableServerBrowsingTVViewControllerSectionHeaderKey = @"VLCSearchableServerBrowsingTVViewControllerSectionHeader";
@interface VLCSearchableServerBrowsingTVViewControllerHeader : UICollectionReusableView
@property (nonatomic) UISearchBar *searchBar;
@end

@interface VLCSearchableServerBrowsingTVViewController() <UISearchControllerDelegate, UISearchResultsUpdating>
@property (nonatomic) UISearchController *searchController;
@property (nonatomic) VLCNetworkServerSearchBrowser *searchBrowser;
@property (nonatomic) NSNumber *collectionTopContentOffset;
@end

@implementation VLCSearchableServerBrowsingTVViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    VLCNetworkServerSearchBrowser *searchBrowser = [[VLCNetworkServerSearchBrowser alloc] initWithServerBrowser:self.serverBrowser];
    VLCServerBrowsingTVViewController *resultBrowsingViewController = [[VLCServerBrowsingTVViewController alloc] initWithServerBrowser:searchBrowser];
    resultBrowsingViewController.subdirectoryBrowserClass = [self class];
    _searchBrowser = searchBrowser;
    VLCSearchController *searchController = [[VLCSearchController alloc] initWithSearchResultsController:resultBrowsingViewController];
    searchController.searchResultsUpdater = self;
    searchController.delegate = self;
    searchController.hidesNavigationBarDuringPresentation = NO;
    [searchController setupTapGesture];
    _searchController = searchController;
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    flowLayout.headerReferenceSize = searchController.searchBar.bounds.size;

    [self.collectionView registerClass:[VLCSearchableServerBrowsingTVViewControllerHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:VLCSearchableServerBrowsingTVViewControllerSectionHeaderKey];

    [self setupGestures];

    self.definesPresentationContext = YES;
}

#pragma mark - UICollectionViewDataSource

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:VLCSearchableServerBrowsingTVViewControllerSectionHeaderKey forIndexPath:indexPath];

    VLCSearchableServerBrowsingTVViewControllerHeader *header = [supplementaryView isKindOfClass:[VLCSearchableServerBrowsingTVViewControllerHeader class]] ? (id)supplementaryView : nil;
    UISearchController *searchController = self.searchController;
    header.searchBar = searchController.searchBar;
    if (!searchController.active) {
        [header addSubview:searchController.searchBar];
    }

    if (_collectionTopContentOffset == nil) {
        _collectionTopContentOffset = [[NSNumber alloc] initWithDouble:self.collectionView.contentOffset.y];
    }

    return supplementaryView;
}

#pragma mark - VLCNetworkServerBrowserDelegate
- (void)networkServerBrowserDidUpdate:(id<VLCNetworkServerBrowser>)networkBrowser
{
    [super networkServerBrowserDidUpdate:networkBrowser];
    if (self.searchController.active) {
        [self.searchBrowser networkServerBrowserDidUpdate:networkBrowser];
    }
}

- (void)networkServerBrowser:(id<VLCNetworkServerBrowser>)networkBrowser requestDidFailWithError:(NSError *)error
{
    if (self.searchController.active) {
        [self.searchBrowser networkServerBrowser:networkBrowser requestDidFailWithError:error];
    } else {
        [super networkServerBrowser:networkBrowser requestDidFailWithError:error];
    }
}

#pragma mark - UISearchControllerDelegate
- (void)willPresentSearchController:(UISearchController *)searchController
{
    [self.searchBrowser networkServerBrowserDidUpdate:self.serverBrowser];
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    self.searchBrowser.searchText = searchController.searchBar.text;
}

#pragma mark - Gestures

- (void)setupGestures
{
    UITapGestureRecognizer *upArrowRecognizer = [[VLCIRTVTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleUpGestures)];
    upArrowRecognizer.allowedPressTypes = @[@(UIPressTypeUpArrow)];

    UISwipeGestureRecognizer *upSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleUpGestures)];
    upSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionUp;

    [self.view addGestureRecognizer:upArrowRecognizer];
    [self.view addGestureRecognizer:upSwipeRecognizer];
}

- (void)handleUpGestures
{
    // If the user swipes up or taps the up button at the top of the collection view it
    // will present the search controller
    if (self.collectionView.contentOffset.y == [_collectionTopContentOffset floatValue]) {
        [self presentViewController:_searchController animated:NO completion:nil];
    }
}

@end

@implementation VLCSearchableServerBrowsingTVViewControllerHeader

- (void)setSearchBar:(UISearchBar *)searchBar {
    _searchBar = searchBar;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    // UISearchController 'steals' the search bar from us when it's active.
    if (self.searchBar.superview == self) {
        self.searchBar.center = self.center;
    }
}

@end
