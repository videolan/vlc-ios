/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRemotePlaybackViewController.h"
#import "Reachability.h"
#import "VLCHTTPUploaderController.h"
#import "VLCMediaFileDiscoverer.h"
#import "VLCRemoteBrowsingTVCell.h"
#import "VLCMaskView.h"

#define remotePlaybackReuseIdentifer @"remotePlaybackReuseIdentifer"

@interface VLCRemotePlaybackViewController () <UICollectionViewDataSource, UICollectionViewDelegate, VLCMediaFileDiscovererDelegate>
{
    Reachability *_reachability;
    NSMutableArray *_discoveredFiles;
}
@end

@implementation VLCRemotePlaybackViewController

- (NSString *)title
{
    return NSLocalizedString(@"WEBINTF_TITLE_ATV", nil);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.cachedMediaCollectionView.collectionViewLayout;
    const CGFloat inset = 50.;
    flowLayout.sectionInset = UIEdgeInsetsMake(inset, inset, inset, inset);
    flowLayout.itemSize = CGSizeMake(250.0, 300.0);
    flowLayout.minimumInteritemSpacing = 48.0;
    flowLayout.minimumLineSpacing = 100.0;
    [self.cachedMediaCollectionView registerNib:[UINib nibWithNibName:@"VLCRemoteBrowsingTVCell" bundle:nil]
          forCellWithReuseIdentifier:VLCRemoteBrowsingTVCellIdentifier];

    _reachability = [Reachability reachabilityForLocalWiFi];
    self.httpServerLabel.textColor = [UIColor VLCDarkBackgroundColor];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(reachabilityChanged)
                               name:kReachabilityChangedNotification
                             object:nil];

    VLCMediaFileDiscoverer *discoverer = [VLCMediaFileDiscoverer sharedInstance];

    _discoveredFiles = [NSMutableArray array];

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    discoverer.directoryPath = [[searchPaths firstObject] stringByAppendingPathComponent:@"Upload"];
    [discoverer addObserver:self];
    [discoverer startDiscovering];
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

    [_reachability startNotifier];
    [self updateHTTPServerAddress];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_reachability stopNotifier];
}

- (void)reachabilityChanged
{
    [self updateHTTPServerAddress];
}

- (void)updateHTTPServerAddress
{
    BOOL connectedViaWifi = _reachability.currentReachabilityStatus == ReachableViaWiFi;
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
    @synchronized(_discoveredFiles) {
        if (_discoveredFiles.count > row) {
            cellTitle = [_discoveredFiles[row] lastPathComponent];
        }
    }

    [cell prepareForReuse];
    [cell setIsDirectory:NO];
    [cell setThumbnailImage:[UIImage imageNamed:@"blank"]];
    [cell setTitle:cellTitle];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSUInteger ret;

    @synchronized(_discoveredFiles) {
        ret = _discoveredFiles.count;
    }

    return ret;
}

#pragma mark - collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSURL *url;
    @synchronized(_discoveredFiles) {
        url = [NSURL fileURLWithPath:_discoveredFiles[indexPath.row]];
    }
    [vpc playURL:url subtitlesFilePath:nil];
    [self presentViewController:[VLCFullscreenMovieTVViewController fullscreenMovieTVViewController]
                       animated:YES
                     completion:nil];
}

#pragma mark - media file discovery
- (void)mediaFilesFoundRequiringAdditionToStorageBackend:(NSArray<NSString *> *)foundFiles
{
    @synchronized(_discoveredFiles) {
        _discoveredFiles = [NSMutableArray arrayWithArray:foundFiles];
    }
    [self.cachedMediaCollectionView reloadData];
}

- (void)mediaFileAdded:(NSString *)filePath loading:(BOOL)isLoading
{
    @synchronized(_discoveredFiles) {
        if (![_discoveredFiles containsObject:filePath]) {
            [_discoveredFiles addObject:filePath];
        }
    }
    [self.cachedMediaCollectionView reloadData];
}

- (void)mediaFileDeleted:(NSString *)filePath
{
    @synchronized(_discoveredFiles) {
        [_discoveredFiles removeObject:filePath];
    }
    [self.cachedMediaCollectionView reloadData];
}

@end
