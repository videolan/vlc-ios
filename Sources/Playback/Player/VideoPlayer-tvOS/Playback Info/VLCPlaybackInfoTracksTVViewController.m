/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoTracksTVViewController.h"
#import "VLCPlaybackInfoTVCollectionViewCell.h"
#import "VLCPlaybackInfoTVCollectionSectionTitleView.h"
#import "VLCPlaybackInfoCollectionViewDataSource.h"
#import "VLCPlaybackInfoSubtitlesFetcherViewController.h"

@interface VLCPlaybackInfoTracksDataSourceAudio : VLCPlaybackInfoCollectionViewDataSource <UICollectionViewDataSource, UICollectionViewDelegate>
@end
@interface VLCPlaybackInfoTracksDataSourceSubtitle : VLCPlaybackInfoCollectionViewDataSource <UICollectionViewDataSource, UICollectionViewDelegate>
@end


@interface VLCPlaybackInfoTracksTVViewController ()
@property (nonatomic) IBOutlet VLCPlaybackInfoTracksDataSourceAudio *audioDataSource;
@property (nonatomic) IBOutlet VLCPlaybackInfoTracksDataSourceSubtitle *subtitleDataSource;
@end


@implementation VLCPlaybackInfoTracksTVViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"TRACK_SELECTION", nil);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UINib *nib = [UINib nibWithNibName:@"VLCPlaybackInfoTVCollectionViewCell" bundle:nil];
    NSString *identifier = [VLCPlaybackInfoTVCollectionViewCell identifier];
    [self.audioTrackCollectionView registerNib:nib forCellWithReuseIdentifier:identifier];
    [self.subtitleTrackCollectionView registerNib:nib forCellWithReuseIdentifier:identifier];
    [VLCPlaybackInfoTVCollectionSectionTitleView registerInCollectionView:self.audioTrackCollectionView];
    [VLCPlaybackInfoTVCollectionSectionTitleView registerInCollectionView:self.subtitleTrackCollectionView];

    NSLocale *currentLocale = [NSLocale currentLocale];
    self.audioDataSource.title = [NSLocalizedString(@"AUDIO", nil) uppercaseStringWithLocale:currentLocale];
    self.audioDataSource.cellIdentifier = [VLCPlaybackInfoTVCollectionViewCell identifier];
    self.subtitleDataSource.title = [NSLocalizedString(@"SUBTITLES", nil) uppercaseStringWithLocale:currentLocale];
    self.subtitleDataSource.cellIdentifier = [VLCPlaybackInfoTVCollectionViewCell identifier];
    self.subtitleDataSource.parentViewController = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerChanged) name:VLCPlaybackServicePlaybackMetadataDidChange object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self mediaPlayerChanged];
}

- (CGSize)preferredContentSize
{
    CGFloat preferredHeight = MAX(self.audioTrackCollectionView.contentSize.height, self.subtitleTrackCollectionView.contentSize.height) + CONTENT_INSET;
    if (preferredHeight < MINIMAL_CONTENT_SIZE) {
        preferredHeight = MINIMAL_CONTENT_SIZE;
    }
    return CGSizeMake(CGRectGetWidth(self.view.bounds), preferredHeight);
}

- (void)mediaPlayerChanged
{
    [self.audioTrackCollectionView reloadData];
    [self.subtitleTrackCollectionView reloadData];
}

- (void)downloadMoreSPU
{
    VLCPlaybackInfoSubtitlesFetcherViewController *targetViewController = [[VLCPlaybackInfoSubtitlesFetcherViewController alloc] initWithNibName:nil bundle:nil];
    targetViewController.title = NSLocalizedString(@"DOWNLOAD_SUBS_FROM_OSO", nil);
    [self presentViewController:targetViewController
                       animated:YES
                     completion:nil];
}

@end

@implementation VLCPlaybackInfoTracksDataSourceAudio
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[VLCPlaybackService sharedInstance] numberOfAudioTracks] + 1;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackInfoTVCollectionViewCell *trackCell = (VLCPlaybackInfoTVCollectionViewCell*)cell;
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    NSInteger row = indexPath.row;
    NSString *trackName;

    if (row >= [vpc numberOfAudioTracks]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingUseSPDIF]) {
            trackName = [@"✓ " stringByAppendingString:NSLocalizedString(@"USE_SPDIF", nil)];
            trackCell.titleLabel.font = [UIFont boldSystemFontOfSize:29.];
        } else
            trackName = NSLocalizedString(@"USE_SPDIF", nil);
    } else {
        BOOL isSelected = row == [vpc indexOfCurrentAudioTrack];
        trackCell.selectionMarkerVisible = isSelected;

        trackName = [vpc audioTrackNameAtIndex:row];
        if (trackName != nil) {
            if ([trackName isEqualToString:@"Disable"])
                trackName = NSLocalizedString(@"DISABLE_LABEL", nil);
        }
    }
    trackCell.titleLabel.text = trackName;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    NSInteger row = indexPath.row;
    if (row >= [vpc numberOfAudioTracks]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL bValue = ![defaults boolForKey:kVLCSettingUseSPDIF];
        [vpc setAudioPassthrough:bValue];

        [defaults setBool:bValue forKey:kVLCSettingUseSPDIF];
    } else {
        [vpc selectAudioTrackAtIndex:row];
    }
    [collectionView reloadData];
}

@end

@implementation VLCPlaybackInfoTracksDataSourceSubtitle
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[VLCPlaybackService sharedInstance] numberOfVideoSubtitlesIndexes];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackInfoTVCollectionViewCell *trackCell = (VLCPlaybackInfoTVCollectionViewCell*)cell;
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    NSInteger row = indexPath.row;
    NSString *trackName;
    if (row >= [vpc numberOfVideoSubtitlesIndexes]) {
        trackName = NSLocalizedString(@"DOWNLOAD_SUBS_FROM_OSO", nil);
    } else {
        BOOL isSelected = [vpc indexOfCurrentSubtitleTrack] == row;
        trackCell.selectionMarkerVisible = isSelected;

        trackName = [vpc videoSubtitleNameAtIndex:row];
        if (trackName != nil) {
            if ([trackName isEqualToString:@"Disable"])
                trackName = NSLocalizedString(@"DISABLE_LABEL", nil);
        }
    }
    trackCell.titleLabel.text = trackName;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    NSInteger row = indexPath.row;
    if (row == [vpc numberOfVideoSubtitlesIndexes] - 1) {
        if (self.parentViewController) {
            if ([self.parentViewController respondsToSelector:@selector(downloadMoreSPU)]) {
                [self.parentViewController performSelector:@selector(downloadMoreSPU)];
            }
        }
    } else {
        [vpc selectVideoSubtitleAtIndex:row];
        [collectionView reloadData];
    }
}

@end
