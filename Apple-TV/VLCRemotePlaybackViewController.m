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
#import "VLCMediaFileDiscoverer.h"
#import "VLCRemoteBrowsingTVCell.h"
#import "VLCMaskView.h"
#import "CAAnimation+VLCWiggle.h"
#import "NSString+SupportedMedia.h"
#import "VLC-Swift.h"

#define remotePlaybackReuseIdentifer @"remotePlaybackReuseIdentifer"

@interface VLCRemotePlaybackViewController () <UICollectionViewDataSource, UICollectionViewDelegate, VLCMediaFileDiscovererDelegate>

@property (strong, nonatomic) Reachability *reachability;
@property (strong, nonatomic) NSMutableArray<NSString *> *discoveredFiles;

@property (strong, nonatomic) VLCMediaThumbnailerCache *thumbnailerCache;

@property (nonatomic) NSIndexPath *currentlyFocusedIndexPath;

@end

@implementation VLCRemotePlaybackViewController

- (NSString *)title
{
    return NSLocalizedString(@"WEBINTF_TITLE_ATV", nil);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (@available(tvOS 13.0, *)) {
        self.navigationController.navigationBarHidden = YES;
    }

    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.cachedMediaCollectionView.collectionViewLayout;
    const CGFloat inset = 50.;
    flowLayout.sectionInset = UIEdgeInsetsMake(inset, inset, inset, inset);
    flowLayout.itemSize = CGSizeMake(250.0, 300.0);
    flowLayout.minimumInteritemSpacing = 48.0;
    flowLayout.minimumLineSpacing = 100.0;
    [self.cachedMediaCollectionView registerNib:[UINib nibWithNibName:@"VLCRemoteBrowsingTVCell" bundle:nil]
          forCellWithReuseIdentifier:VLCRemoteBrowsingTVCellIdentifier];

    self.reachability = [Reachability reachabilityForLocalWiFi];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(reachabilityChanged)
                               name:kReachabilityChangedNotification
                             object:nil];

    VLCMediaFileDiscoverer *discoverer = [VLCMediaFileDiscoverer sharedInstance];
    discoverer.filterResultsForPlayability = NO;

    self.discoveredFiles = [NSMutableArray array];

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    discoverer.directoryPath = [[searchPaths firstObject] stringByAppendingPathComponent:kVLCHTTPUploadDirectory];
    [discoverer addObserver:self];
    [discoverer startDiscovering];

    self.cachedMediaLabel.text = NSLocalizedString(@"CACHED_MEDIA", nil);
    self.cachedMediaLongLabel.text = NSLocalizedString(@"CACHED_MEDIA_LONG", nil);

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

    self.thumbnailerCache = [VLCMediaThumbnailerCache alloc];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(realoadMediaCollectionView:)
                                                 name:@"thumbnailIComplete" object:nil];
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

    [[VLCMediaFileDiscoverer sharedInstance] updateMediaList];

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
    NSString *uploadText = connectedViaWifi ? [[VLCHTTPUploaderController sharedInstance] httpStatus] : NSLocalizedString(@"HTTP_UPLOAD_NO_CONNECTIVITY", nil);
    self.httpServerLabel.text = uploadText;
    if (connectedViaWifi && [VLCHTTPUploaderController sharedInstance].isServerRunning)
        [self.toggleHTTPServerButton setTitle:NSLocalizedString(@"HTTP_SERVER_ON", nil) forState:UIControlStateNormal];
    else
        [self.toggleHTTPServerButton setTitle:NSLocalizedString(@"HTTP_SERVER_OFF", nil) forState:UIControlStateNormal];
}

- (void)toggleHTTPServer:(id)sender
{
    BOOL futureHTTPServerState = ![VLCHTTPUploaderController sharedInstance].isServerRunning ;
    [[NSUserDefaults standardUserDefaults] setBool:futureHTTPServerState forKey:kVLCSettingSaveHTTPUploadServerStatus];
    [[VLCHTTPUploaderController sharedInstance] changeHTTPServerState:futureHTTPServerState];
    [self updateHTTPServerAddress];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - collection view data source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCRemoteBrowsingTVCell *cell = (VLCRemoteBrowsingTVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:VLCRemoteBrowsingTVCellIdentifier forIndexPath:indexPath];
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(VLCRemoteBrowsingTVCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellTitle;
    NSUInteger row = indexPath.row;

   NSURL *thumbnailURL = nil;

    @synchronized(self.discoveredFiles) {
        if (self.discoveredFiles.count > row) {
            cellTitle = [self.discoveredFiles[row] lastPathComponent];
            if (cellTitle.isSupportedMediaFormat) {
                thumbnailURL = [self.thumbnailerCache getThumbnailURL:self.discoveredFiles[row]];
            }
        }
    }

    [cell prepareForReuse];
    [cell setIsDirectory:NO];
    if (thumbnailURL) {
        [cell setThumbnailURL:thumbnailURL];
    } else if (cellTitle.isSupportedMediaFormat) {
        [cell setThumbnailImage:[UIImage imageNamed:@"movie"]];
    } else if (cellTitle.isSupportedAudioMediaFormat) {
        [cell setThumbnailImage:[UIImage imageNamed:@"audio"]];
    } else {
        [cell setThumbnailImage:[UIImage imageNamed:@"blank"]];
    }
    [cell setTitle:cellTitle];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSUInteger ret;

    @synchronized(self.discoveredFiles) {
        ret = self.discoveredFiles.count;
    }
    self.cachedMediaConeImageView.hidden = ret > 0;

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

    NSString *ret = nil;
    @synchronized(self.discoveredFiles) {
        NSInteger index = indexPathToDelete.item;
        if (index < self.discoveredFiles.count) {
            ret = self.discoveredFiles[index];
        }
    }
    return ret;
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
    __block NSString *fileToDelete = nil;
    [self.cachedMediaCollectionView performBatchUpdates:^{
        @synchronized(self.discoveredFiles) {
            fileToDelete = self.discoveredFiles[indexPathToDelete.item];
            [self.discoveredFiles removeObject:fileToDelete];
        }
        [self.cachedMediaCollectionView deleteItemsAtIndexPaths:@[indexPathToDelete]];
    } completion:^(BOOL finished) {
        [[NSFileManager defaultManager] removeItemAtPath:fileToDelete error:nil];
        self.editing = NO;
    }];
}

#pragma mark - collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *url;
    @synchronized(self.discoveredFiles) {
        url = [NSURL fileURLWithPath:self.discoveredFiles[indexPath.row]];
    }

    VLCMediaList *medialist = [[VLCMediaList alloc] init];
    [medialist addMedia:[VLCMedia mediaWithURL:url]];

    [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
    [self presentViewController:[VLCFullscreenMovieTVViewController fullscreenMovieTVViewController]
                       animated:YES
                     completion:nil];
}

#pragma mark - media file discovery
- (void)mediaFilesFoundRequiringAdditionToStorageBackend:(NSArray<NSString *> *)foundFiles
{
    @synchronized(self.discoveredFiles) {
        self.discoveredFiles = [NSMutableArray arrayWithArray:foundFiles];
            for (int cnt = 0; cnt < [self.discoveredFiles count]; cnt++) {
				if (self.discoveredFiles[cnt].isSupportedMediaFormat) {
                	[self.thumbnailerCache getVideoThumbnail:self.discoveredFiles[cnt]];
				}
            }
    }
    [self.cachedMediaCollectionView reloadData];
}

- (void)mediaFileAdded:(NSString *)filePath loading:(BOOL)isLoading
{
    @synchronized(self.discoveredFiles) {
        if (![self.discoveredFiles containsObject:filePath]) {
            [self.discoveredFiles addObject:filePath];
        }
    }
    [self.cachedMediaCollectionView reloadData];
}

- (void)mediaFileDeleted:(NSString *)filePath
{
    @synchronized(self.discoveredFiles) {
        [self.discoveredFiles removeObject:filePath];
        [self.thumbnailerCache removeThumbnail:filePath];
    }
    [self.cachedMediaCollectionView reloadData];
}

- (void)realoadMediaCollectionView:(NSNotification *)notification
{
    [self.cachedMediaCollectionView reloadData];
}

@end
