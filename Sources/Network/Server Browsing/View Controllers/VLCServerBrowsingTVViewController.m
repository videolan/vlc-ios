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
#import "VLCPlaybackService.h"
#import "VLCServerBrowsingController.h"
#import "VLCMaskView.h"
#import "GRKArrayDiff+UICollectionView.h"
#import "VLCFavoriteService.h"
#import "VLCAppCoordinator.h"

@interface VLCServerBrowsingTVViewController ()
{
    UIActivityIndicatorView *_activityIndicator;
    VLCFavoriteService *_favoriteService;
}
@property (nonatomic) VLCServerBrowsingController *browsingController;
@property (nonatomic) NSArray<id <VLCNetworkServerBrowserItem>> *items;
@property (nonatomic) UITapGestureRecognizer *playPausePressRecognizer;
@property (nonatomic) UITapGestureRecognizer *cancelRecognizer;
@property (nonatomic) NSIndexPath *currentlyFocusedIndexPath;
@property (nonatomic, assign) BOOL isAnyCellFocused;
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
        _favoriteService = [[VLCAppCoordinator sharedInstance] favoriteService];
        
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
    self.nothingFoundLabel.hidden = YES;
    self.isAnyCellFocused = NO;
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

    if (@available(tvOS 13.0, *)) {
         _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
     } else {
         _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
     }
    _activityIndicator.center = self.view.center;
    _activityIndicator.color = [UIColor VLCOrangeTintColor];
    _activityIndicator.color = [UIColor orangeColor];
    _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _activityIndicator.hidesWhenStopped = YES;
    [_activityIndicator startAnimating];
    [self.view addSubview:_activityIndicator];
    
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(startFavMode)];
    recognizer.allowedPressTypes = @[@(UIPressTypeSelect)];
    recognizer.minimumPressDuration = 1.0;
    [self.view addGestureRecognizer:recognizer];

    UITapGestureRecognizer *cancelRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endFavMode)];
    cancelRecognizer.allowedPressTypes = @[@(UIPressTypeSelect),@(UIPressTypeMenu)];
    cancelRecognizer.enabled = self.editing;
    self.cancelRecognizer = cancelRecognizer;
    [self.view addGestureRecognizer:cancelRecognizer];
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

#pragma mark - Trigger Favorite Mode
- (void)startFavMode
{
    id<VLCNetworkServerBrowserItem> item = self.serverBrowser.items[_currentlyFocusedIndexPath.row];

    if (!item) {
        return; // Ensure the item exists
    }

    VLCFavorite *favorite = [[VLCFavorite alloc] init];
    favorite.url = item.URL;
    
    UIAlertController *alertController;
    UIAlertAction *alertAction;
    
    if (![_favoriteService isFavoriteURL:favorite.url]) {
         favorite.userVisibleName = item.name;
         NSString *titleString = NSLocalizedString(@"FAVORITE_ALERT_TITLE", nil);
         NSString *buttonString = NSLocalizedString(@"ADD_FAVORITE", nil);
         alertController = [UIAlertController alertControllerWithTitle: titleString message:nil preferredStyle:UIAlertControllerStyleAlert];
         alertAction = [UIAlertAction actionWithTitle: buttonString style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
             [self setMediaFav:favorite isFavorite:YES];
        }];
     }
     else {
          NSString *titleString = NSLocalizedString(@"UNFAVORITE_ALERT_TITLE", nil);
          NSString *buttonString = NSLocalizedString(@"REMOVE_FAVORITE", nil);
          alertController = [UIAlertController alertControllerWithTitle: titleString message:nil preferredStyle:UIAlertControllerStyleAlert];
          alertAction = [UIAlertAction actionWithTitle: buttonString style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
              [self setMediaFav:favorite isFavorite:NO];
         }];
     }
    
    NSString *cancelTitle = NSLocalizedString(@"BUTTON_CANCEL", nil);
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle: cancelTitle style:UIAlertActionStyleDestructive handler:nil] ;
    [alertController addAction:alertAction];
    [alertController addAction:cancelAction];
    if (self.isAnyCellFocused) {
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)endFavMode
{
    self.editing = NO;
}

- (void)setMediaFav:(VLCFavorite *)favorite isFavorite:(BOOL)isFavorite {
    if (isFavorite) {
        [_favoriteService addFavorite:favorite];
    } else {
        [_favoriteService removeFavorite:favorite];
    }
    [self.collectionView reloadData];
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
    if (self.items.count == 0) {
        [_activityIndicator stopAnimating];
        self.nothingFoundLabel.hidden = NO;
    }
}

- (void)networkServerBrowser:(id<VLCNetworkServerBrowser>)networkBrowser requestDidFailWithError:(NSError *)error {

    [self vlc_showAlertWithTitle:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_TITLE", nil)
                         message:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_MESSAGE", nil)
                     buttonTitle:NSLocalizedString(@"BUTTON_OK", nil)];

    [_activityIndicator stopAnimating];
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
        
        BOOL isFavorited = [_favoriteService isFavoriteURL:item.URL];

        if ([cell isKindOfClass:[VLCRemoteBrowsingTVCell class]]) {
              ((VLCRemoteBrowsingTVCell *)cell).isFavorable = isFavorited;
        }
    }

    if (row == collectionView.indexPathsForVisibleItems.lastObject.row) {
        [_activityIndicator stopAnimating];
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

- (void)collectionView:(UICollectionView *)collectionView didUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    if (context.nextFocusedIndexPath) {
        id<VLCNetworkServerBrowserItem> item = self.items[context.nextFocusedIndexPath.item];
        self.currentlyFocusedIndexPath = context.nextFocusedIndexPath;
        if(item.isContainer){
            self.isAnyCellFocused = YES;
        } else {
            self.isAnyCellFocused = NO;
        }
    } else {
        self.isAnyCellFocused = NO;
    }
}

@end
