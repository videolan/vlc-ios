/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRemotePlaybackViewController.h"
#import "Reachability.h"
#import "VLCHTTPUploaderController.h"
#import "VLCMovieTVCollectionViewCell.h"
#import "VLCMediaTVCollectionViewCell.h"
#import "VLCMaskView.h"
#import "CAAnimation+VLCWiggle.h"
#import "VLC-Swift.h"
#import "VLCAppCoordinator.h"

static NSString * const VLCMediaFooterIdentifier = @"VLCMediaFooterView";

@interface VLCRemotePlaybackViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, MediaLibraryDelegate>

@property (strong, nonatomic) Reachability *reachability;
@property (nonatomic) NSIndexPath *currentlyFocusedIndexPath;
@property (strong) MediaLibraryService *medialibraryservice;
@property (strong) VideoModel *videomodel;
@property (strong) TrackModel *audiomodel;
@property (nonatomic) BOOL isAudio;
@property (nonatomic) tvOSModelObserver *modelObserver;
@property (nonatomic) SortingHandler *sorthandler;
@property (nonatomic, strong) UITabBarController *mediatabController;

// Editing Properties
@property (nonatomic) BOOL editSelectionActive;
@property (nonatomic) UIButton* addtoPlaylist;
@property (nonatomic, strong) NSMapTable<VLCMovieTVCollectionViewCell *, VLCMLMedia *> *cellToMediaMap;

// Searching properties
@property (nonatomic, assign) BOOL didBeginSearching;
@property (nonatomic, strong) NSMutableArray<VLCMLMedia*> *searchedMedia;

@end

@implementation VLCRemotePlaybackViewController

- (NSString *)title
{
     return NSLocalizedString(@"WEBINTF_TITLE_ATV", nil);
}

- (void)viewDidLoad
{
     [super viewDidLoad];

     // Media Library Service
     _medialibraryservice = [[VLCAppCoordinator sharedInstance] mediaLibraryService];

     // Init the models
     _videomodel = [[VideoModel alloc] initWithMedialibrary:_medialibraryservice];

     _audiomodel = [[TrackModel alloc] initWithMedialibrary:_medialibraryservice];

     _modelObserver = [[tvOSModelObserver alloc] initWithObserverDelegate: self videoModel: _videomodel audioModel: _audiomodel];

     [_modelObserver observeLibrary];

     self.cellToMediaMap = [NSMapTable strongToStrongObjectsMapTable];
     _sorthandler = [[SortingHandler alloc] initWithVideoModel:_videomodel];

     _mediatabController = [[UITabBarController alloc] init];

     // Customize the tab bar appearance if needed
     _mediatabController.tabBar.barTintColor = [UIColor orangeColor];

     // Set the delegate to handle tab switching events
     _mediatabController.delegate = self;

     _searchedMedia = [[NSMutableArray alloc] init];
     _searchBar.delegate = self;
     _didBeginSearching = NO;

     UIViewController *videoViewController = [[UIViewController alloc] init];
     videoViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Video" image:nil tag:0];

     UIViewController *audioViewController = [[UIViewController alloc] init];
     audioViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Audio" image:nil tag:1];

     _mediatabController.viewControllers = @[videoViewController, audioViewController];
     _mediatabController.tabBar.frame = CGRectMake(0, self.view.bounds.size.height - 1000, self.view.bounds.size.width, 50);

     // Set the mediatabController as the child view controller
     [self addChildViewController:_mediatabController];
     [self.view addSubview:_mediatabController.view];
     UIView *containerView = [[UIView alloc] initWithFrame:self.view.bounds];
     [self.view addSubview:containerView];

     // Add the tab bar controller as a child view controller
     [self addChildViewController:_mediatabController];
     [containerView addSubview:_mediatabController.view];
     [_mediatabController didMoveToParentViewController:self];

     // Set up constraints for the container view
     containerView.translatesAutoresizingMaskIntoConstraints = NO;
     NSLayoutConstraint *leadingConstraint = [containerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:100];
     NSLayoutConstraint *trailingConstraint = [containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-100];
     NSLayoutConstraint *topConstraint = [containerView.topAnchor constraintEqualToAnchor:self.view.topAnchor];
     NSLayoutConstraint *bottomConstraint = [containerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-1000];
     NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:_mediatabController.tabBar
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:0];

     [NSLayoutConstraint activateConstraints:@[leadingConstraint, trailingConstraint, topConstraint, bottomConstraint, heightConstraint]];

     _mediatabController.view.frame = containerView.bounds;
     [_mediatabController didMoveToParentViewController:self];

     if (@available(tvOS 13.0, *)) {
          self.navigationController.navigationBarHidden = YES;
     }

     UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.cachedMediaCollectionView.collectionViewLayout;
     const CGFloat inset = 50.;
     flowLayout.sectionInset = UIEdgeInsetsMake(inset, inset, 10, inset);
     flowLayout.itemSize = [VLCMovieTVCollectionViewCell cellSize];
     flowLayout.minimumInteritemSpacing = 48.0;
     flowLayout.minimumLineSpacing = 80.0;
     [self.cachedMediaCollectionView registerClass:[VLCMovieTVCollectionViewCell class]
                       forCellWithReuseIdentifier:VLCMovieTVCollectionViewCellIdentifier];
     [self.cachedMediaCollectionView registerClass:[VLCMediaTVCollectionViewCell class]
                       forCellWithReuseIdentifier:VLCMediaTVCollectionViewCellIdentifier];
     [self.cachedMediaCollectionView registerClass:[UICollectionReusableView class]
                        forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                               withReuseIdentifier:VLCMediaFooterIdentifier];
     CGFloat footerWidth = self.view.bounds.size.width - 400.0;
     CGSize constraintSize = CGSizeMake(footerWidth, CGFLOAT_MAX);
     CGFloat headlineHeight = [NSLocalizedString(@"CACHED_MEDIA", nil)
                               boundingRectWithSize:constraintSize
                               options:NSStringDrawingUsesLineFragmentOrigin
                               attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]}
                               context:nil].size.height;
     CGFloat bodyHeight = [NSLocalizedString(@"CACHED_MEDIA_LONG", nil)
                           boundingRectWithSize:constraintSize
                           options:NSStringDrawingUsesLineFragmentOrigin
                           attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]}
                           context:nil].size.height;
     flowLayout.footerReferenceSize = CGSizeMake(0, ceil(headlineHeight + bodyHeight + 46.0));

     self.reachability = [Reachability reachabilityForLocalWiFi];

     NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
     [notificationCenter addObserver:self
                            selector:@selector(reachabilityChanged)
                                name:kReachabilityChangedNotification
                              object:nil];


     /* After day 354 of the year, the usual VLC cone is replaced by another cone
      * wearing a Father Xmas hat.
      * Note: this icon doesn't represent an endorsement of The Coca-Cola Company
      * and should not be confused with the idea of religious statements or propagation there off
      */
     NSCalendar *gregorian =
     [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
     NSUInteger dayOfYear = [gregorian ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitYear forDate:[NSDate date]];
     if (dayOfYear >= 354)
          self.cachedMediaConeImageView.image = [UIImage imageNamed:@"xmas-cone"];
}

- (void)viewDidLayoutSubviews
{
     [super viewDidLayoutSubviews];

     UICollectionView *collectionView = self.cachedMediaCollectionView;
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
     CGSize collectionViewSize = collectionView.bounds.size;
     maskView.frame = CGRectMake(0, collectionView.contentOffset.y, collectionViewSize.width, collectionViewSize.height);
}

- (void)viewWillAppear:(BOOL)animated
{
     [super viewWillAppear:animated];

     [self.reachability startNotifier];
     [self updateHTTPServerAddress];
}

- (void)viewWillDisappear:(BOOL)animated
{
     [super viewWillDisappear:animated];

     [self.reachability stopNotifier];
}

- (void)reachabilityChanged
{
     [self updateHTTPServerAddress];
}

- (void)updateHTTPServerAddress
{
     BOOL connectedViaWifi = self.reachability.currentReachabilityStatus == ReachableViaWiFi;
     self.toggleHTTPServerButton.enabled = connectedViaWifi;
     NSString *uploadText = connectedViaWifi ? [[[VLCAppCoordinator sharedInstance] httpUploaderController] httpStatus] : NSLocalizedString(@"HTTP_UPLOAD_NO_CONNECTIVITY", nil);
     self.httpServerLabel.text = uploadText;
     if (connectedViaWifi && [[VLCAppCoordinator sharedInstance] httpUploaderController].isServerRunning)
          [self.toggleHTTPServerButton setTitle:NSLocalizedString(@"HTTP_SERVER_ON", nil) forState:UIControlStateNormal];
     else
          [self.toggleHTTPServerButton setTitle:NSLocalizedString(@"HTTP_SERVER_OFF", nil) forState:UIControlStateNormal];
}

- (IBAction)toggleEditSelectionMode:(id)sender
{
     if(_editSelectionActive) {
          _editSelectionActive = NO;
          [self.cachedMediaCollectionView reloadData];
          [self createPlaylist];
          return;
     }

     _editSelectionActive = YES;
     _sortButton.hidden = YES;
     [self.cachedMediaCollectionView reloadData];
}

- (void)toggleHTTPServer:(id)sender
{
     BOOL futureHTTPServerState = ![[VLCAppCoordinator sharedInstance] httpUploaderController].isServerRunning ;
     [[NSUserDefaults standardUserDefaults] setBool:futureHTTPServerState forKey:kVLCSettingSaveHTTPUploadServerStatus];
     [[[VLCAppCoordinator sharedInstance] httpUploaderController] changeHTTPServerState:futureHTTPServerState];
     [self updateHTTPServerAddress];
     [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)createPlaylist
{
     NSMutableArray *cellsToRemove = [NSMutableArray array];
     NSMutableArray *playlistMedia = [NSMutableArray array];

     for (VLCMovieTVCollectionViewCell *cell in [self.cellToMediaMap keyEnumerator]) {
          cell.selectedPreviously = YES;
          [cell toggleCheckbox];
          [cellsToRemove addObject:cell];
          VLCMLMedia *media = [self.cellToMediaMap objectForKey:cell];
          [playlistMedia addObject:media];
     }

     for (VLCMovieTVCollectionViewCell *cellToRemove in cellsToRemove) {
          [self.cellToMediaMap removeObjectForKey:cellToRemove];
     }

     AddToPlaylistViewController *addtoplaylistController = [[AddToPlaylistViewController alloc] init];
     if ([playlistMedia count] != 0) {
          addtoplaylistController.mediaToAdd = playlistMedia;
          [self presentViewController:addtoplaylistController animated:YES completion:nil];
     }
}

- (IBAction)sortMedia:(id)sender
{
     [_sorthandler constructSortAlertWithRemotePlaybackView: self playlistView: nil];
}

#pragma mark - collection view data source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
     NSUInteger row = indexPath.row;

     VLCMLMedia *media = nil;

     if (_didBeginSearching) {
          media = _searchedMedia[row];
     } else {
          if (!_isAudio) {
               media = [_videomodel getmediaAt:row];
          } else {
               media = [_audiomodel getmediaAt:row];
          }
     }

     [_medialibraryservice requestThumbnailFor:media];

     if (_isAudio) {
          VLCMediaTVCollectionViewCell *cell = (VLCMediaTVCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:VLCMediaTVCollectionViewCellIdentifier forIndexPath:indexPath];
          [cell configureWithMedia:media];
          if (_editSelectionActive) {
               _searchBar.hidden = YES;
               cell.checkboxImageView.hidden = NO;
          } else {
               cell.checkboxImageView.hidden = YES;
          }
          return cell;
     }

     VLCMovieTVCollectionViewCell *cell = (VLCMovieTVCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:VLCMovieTVCollectionViewCellIdentifier forIndexPath:indexPath];
     [cell configureWithMedia:media];
     if (_editSelectionActive) {
          _searchBar.hidden = YES;
          cell.checkboxImageView.hidden = NO;
     } else {
          cell.checkboxImageView.hidden = YES;
     }
     return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
     return 1;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
     UICollectionReusableView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                          withReuseIdentifier:VLCMediaFooterIdentifier
                                                                                 forIndexPath:indexPath];

     if (footer.subviews.count == 0) {
          ColorPalette *colors = PresentationTheme.current.colors;

          UILabel *cachedMediaLabel = [[UILabel alloc] init];
          cachedMediaLabel.text = NSLocalizedString(@"CACHED_MEDIA", nil);
          cachedMediaLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
          cachedMediaLabel.textColor = colors.cellTextColor;
          cachedMediaLabel.textAlignment = NSTextAlignmentCenter;
          cachedMediaLabel.translatesAutoresizingMaskIntoConstraints = NO;

          UILabel *cachedMediaLongLabel = [[UILabel alloc] init];
          cachedMediaLongLabel.text = NSLocalizedString(@"CACHED_MEDIA_LONG", nil);
          cachedMediaLongLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
          cachedMediaLongLabel.textColor = colors.cellDetailTextColor;
          cachedMediaLongLabel.textAlignment = NSTextAlignmentCenter;
          cachedMediaLongLabel.numberOfLines = 0;
          cachedMediaLongLabel.translatesAutoresizingMaskIntoConstraints = NO;

          [footer addSubview:cachedMediaLabel];
          [footer addSubview:cachedMediaLongLabel];

          [NSLayoutConstraint activateConstraints:@[
               [cachedMediaLabel.topAnchor constraintEqualToAnchor:footer.topAnchor constant:20.0],
               [cachedMediaLabel.leadingAnchor constraintEqualToAnchor:footer.leadingAnchor constant:200.0],
               [cachedMediaLabel.trailingAnchor constraintEqualToAnchor:footer.trailingAnchor constant:-200.0],

               [cachedMediaLongLabel.topAnchor constraintEqualToAnchor:cachedMediaLabel.bottomAnchor constant:6.0],
               [cachedMediaLongLabel.leadingAnchor constraintEqualToAnchor:footer.leadingAnchor constant:200.0],
               [cachedMediaLongLabel.trailingAnchor constraintEqualToAnchor:footer.trailingAnchor constant:-200.0],
          ]];
     }

     return footer;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
     NSUInteger ret;

     if (_didBeginSearching) {
          ret = _searchedMedia.count;
     } else {
          ret = (_isAudio ? _audiomodel.files.count : _videomodel.files.count);
     }

     self.cachedMediaConeImageView.hidden = ret > 0;
     self.sortButton.hidden = ret <= 1;
     if (_didBeginSearching) {
          self.searchBar.hidden = NO;
          self.editSelectionButton.hidden = YES;
     } else {
          self.searchBar.hidden = ret <= 1;
          self.editSelectionButton.hidden = ret == 0;
     }

     return ret;
}

-(BOOL)collectionView:(UICollectionView *)collectionView shouldUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context
{
     if (self.editing) {
          return context.nextFocusedIndexPath == nil;
     }
     return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
     NSIndexPath *nextPath = context.nextFocusedIndexPath;
     if (!nextPath) {
          self.editing = NO;
     }
     self.currentlyFocusedIndexPath = nextPath;
}

#pragma mark - editing

- (NSIndexPath *)indexPathToDelete
{
     NSIndexPath *indexPathToDelete = self.currentlyFocusedIndexPath;
     return indexPathToDelete;
}

- (NSString *)itemToDelete
{
     NSIndexPath *indexPathToDelete = self.indexPathToDelete;

     if (!indexPathToDelete) {
          return nil;
     }

     VLCMLMedia *mediatodelete;
     if (_didBeginSearching) {
          mediatodelete = _searchedMedia[indexPathToDelete.row];
     } else {
          mediatodelete = (_isAudio ? [_audiomodel getmediaAt:indexPathToDelete.row] : [_videomodel getmediaAt:indexPathToDelete.row]);
     }
     return mediatodelete.title;
}

- (void)setEditing:(BOOL)editing
{
     [super setEditing:editing];

     UICollectionViewCell *focusedCell = [self.cachedMediaCollectionView cellForItemAtIndexPath:self.currentlyFocusedIndexPath];
     if (editing) {
          [focusedCell.layer addAnimation:[CAAnimation vlc_wiggleAnimationwithSoftMode:NO]
                                   forKey:VLCWiggleAnimationKey];
     } else {
          [focusedCell.layer removeAnimationForKey:VLCWiggleAnimationKey];
     }
}

- (void)deleteFileAtIndex:(NSIndexPath *)indexPathToDelete
{
     [super deleteFileAtIndex:indexPathToDelete];
     if (!indexPathToDelete) {
          return;
     }

     VLCMLMedia *mediatodestroy;
     if (_didBeginSearching) {
          mediatodestroy = _searchedMedia[indexPathToDelete.row];
          [_searchedMedia removeObjectAtIndex:indexPathToDelete.row];
          if (_searchedMedia.count == 0) {
               _didBeginSearching = NO;
               _searchBar.text = @"";
          }
     } else {
          mediatodestroy = (_isAudio ? [_audiomodel getmediaAt:indexPathToDelete.row] : [_videomodel getmediaAt:indexPathToDelete.row]);
     }
     [mediatodestroy deleteMainFile];
     self.editing = NO;
     [self.cachedMediaCollectionView reloadData];
}

- (void)renameFileAtIndex:(NSIndexPath *)indexPathToRename
{
     VLCMLMedia *mediatoRename;
     if (_didBeginSearching) {
          mediatoRename = _searchedMedia[indexPathToRename.row];
     } else {
          mediatoRename = (_isAudio ? [_audiomodel getmediaAt:indexPathToRename.row] : [_videomodel getmediaAt:indexPathToRename.row]);
     }
     NSString *currentTitle = mediatoRename.title;

     NSString *alertTitle = [NSString stringWithFormat:@"Rename %@ to:", currentTitle];
     UIAlertController *renameAlert = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleAlert];

     __block NSString *newName = nil;

     [renameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
     }];

     UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"style:UIAlertActionStyleCancel
                                                          handler:nil];

     UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Confirm" style: UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          UITextField *textField = renameAlert.textFields.firstObject;
          newName = textField.text;

          if (![newName isEqualToString:@""]) {
               [mediatoRename updateTitle:newName];
               [self.cachedMediaCollectionView reloadData];
          }
     }];

     [renameAlert addAction:confirmAction];
     [renameAlert addAction:cancelAction];

     [self presentViewController:renameAlert animated:YES completion:nil];
}

#pragma mark - collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
     VLCMLMedia *mediatoPlay;
     NSArray<VLCMLMedia *> *collection;

     if (_didBeginSearching) {
          mediatoPlay = _searchedMedia[indexPath.row];
          [[VLCPlaybackService sharedInstance] playMedia:mediatoPlay];
          return;
     }

     if (_isAudio) {
          mediatoPlay = [_audiomodel getmediaAt: indexPath.row];
          collection = _audiomodel.files;
     } else {
          mediatoPlay = [_videomodel getmediaAt: indexPath.row];
          collection = _videomodel.files;
     }

     if (_editSelectionActive) {
          VLCMovieTVCollectionViewCell *selectedCell = (VLCMovieTVCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
          [selectedCell toggleCheckbox];
          if (selectedCell.selectedPreviously) {
               [self.cellToMediaMap setObject: collection[indexPath.row] forKey: selectedCell];
          } else {
               [self.cellToMediaMap removeObjectForKey:selectedCell];
          }
          _editSelectionButton.imageView.image = [UIImage imageNamed:@"addToPlaylist"];
          return;
     }

     if ([[NSUserDefaults standardUserDefaults] boolForKey:kVLCAutomaticallyPlayNextItem]) {
          [[VLCPlaybackService sharedInstance] playMediaAtIndex:indexPath.row fromCollection:collection];
     } else {
          [[VLCPlaybackService sharedInstance] playMedia:mediatoPlay];
     }
}


- (void)reloadMediaCollectionView:(NSNotification *)notification
{
     [self.cachedMediaCollectionView reloadData];
}

#pragma mark -  media library delegate

-(void)refreshCollection
{
     dispatch_async(dispatch_get_main_queue(), ^{
          [self.cachedMediaCollectionView reloadData];
     });
}
#pragma mark - tab bar controller delegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
     // Perform custom code when switching between tabs

     NSUInteger selectedIndex = tabBarController.selectedIndex;
     _isAudio = (selectedIndex == 1);
     if (_isAudio){
          _sorthandler = [[SortingHandler alloc] initWithAudioModel:_audiomodel];
     } else {
          _sorthandler = [[SortingHandler alloc] initWithVideoModel:_videomodel];
     }
     NSMutableArray<VLCMLMedia *> *mutableMedia = [_searchedMedia mutableCopy];
     [mutableMedia removeAllObjects];
     _searchedMedia = [_searchedMedia copy];

     UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.cachedMediaCollectionView.collectionViewLayout;
     if (_isAudio) {
          flowLayout.itemSize = [VLCMediaTVCollectionViewCell cellSize];
          flowLayout.minimumInteritemSpacing = 48.0;
          flowLayout.minimumLineSpacing = 60.0;
     } else {
          flowLayout.itemSize = [VLCMovieTVCollectionViewCell cellSize];
          flowLayout.minimumLineSpacing = 80.0;
     }

     [self.cachedMediaCollectionView reloadData];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
     if (_editSelectionActive || _didBeginSearching) {
          return NO;
     }
     return YES;
}

#pragma mark - search bar delegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
     NSString *searchString = textField.text;
     NSMutableArray<VLCMLMedia *> *searchResults = [NSMutableArray array];

     if ([textField.text isEqualToString:@""]) {
          self.didBeginSearching = NO;
          self.sortButton.hidden = NO;
          self.editSelectionButton.hidden = YES;
          searchResults = [NSMutableArray arrayWithArray:_searchedMedia];
     } else {
          self.didBeginSearching = YES;
          self.sortButton.hidden = YES;
          self.editSelectionButton.hidden = YES;

          NSArray<VLCMLMedia *> *sourceArray = _isAudio ? _audiomodel.files : _videomodel.files;

          for (VLCMLMedia *media in sourceArray) {
               if ([media contains:searchString]) {
                    [searchResults addObject:media];
               }
          }
     }
     // Update the search results array and reload the collection view
     _searchedMedia = [NSMutableArray arrayWithArray:searchResults];
     [self.cachedMediaCollectionView reloadData];
}

@end
