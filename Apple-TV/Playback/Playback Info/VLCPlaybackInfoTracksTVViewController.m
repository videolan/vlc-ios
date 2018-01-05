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

#import "VLCPlaybackInfoTracksTVViewController.h"
#import "VLCPlaybackInfoTVCollectionViewCell.h"
#import "VLCPlaybackInfoTVCollectionSectionTitleView.h"
#import "VLCPlaybackInfoCollectionViewDataSource.h"
#import "VLCPlaybackInfoSubtitlesFetcherViewController.h"

#define CONTENT_INSET 20.


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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerChanged) name:VLCPlaybackControllerPlaybackMetadataDidChange object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self mediaPlayerChanged];
}

- (CGSize)preferredContentSize
{
    CGFloat prefferedHeight = MAX(self.audioTrackCollectionView.contentSize.height, self.subtitleTrackCollectionView.contentSize.height) + CONTENT_INSET;
    return CGSizeMake(CGRectGetWidth(self.view.bounds), prefferedHeight);
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
    return [[VLCPlaybackController sharedInstance] numberOfAudioTracks] + 1;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackInfoTVCollectionViewCell *trackCell = (VLCPlaybackInfoTVCollectionViewCell*)cell;
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSInteger row = indexPath.row;
    NSString *trackName;

    trackCell.titleLabel.font = [UIFont systemFontOfSize:29.];

    if (row >= [vpc numberOfAudioTracks]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingUseSPDIF]) {
            trackName = [@"✓ " stringByAppendingString:NSLocalizedString(@"USE_SPDIF", nil)];
            trackCell.titleLabel.font = [UIFont boldSystemFontOfSize:29.];
        } else
            trackName = NSLocalizedString(@"USE_SPDIF", nil);
    } else {
        BOOL isSelected = row == [vpc indexOfCurrentAudioTrack];
        trackCell.selectionMarkerVisible = isSelected;
        if (isSelected) {
            trackCell.titleLabel.font = [UIFont boldSystemFontOfSize:29.];
        }

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
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSInteger row = indexPath.row;
    if (row >= [vpc numberOfAudioTracks]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL bValue = ![defaults boolForKey:kVLCSettingUseSPDIF];
        [vpc setAudioPassthrough:bValue];

        [defaults setBool:bValue forKey:kVLCSettingUseSPDIF];
        /* restart the audio output */
        NSInteger currentAudioTrackIndex = [vpc indexOfCurrentAudioTrack];
        [vpc selectAudioTrackAtIndex:0];
        [vpc selectAudioTrackAtIndex:currentAudioTrackIndex];
    } else {
        [vpc selectAudioTrackAtIndex:row];
    }
    [collectionView reloadData];
}

@end

@implementation VLCPlaybackInfoTracksDataSourceSubtitle
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[VLCPlaybackController sharedInstance] numberOfVideoSubtitlesIndexes] + 1;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackInfoTVCollectionViewCell *trackCell = (VLCPlaybackInfoTVCollectionViewCell*)cell;
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
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

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSInteger row = indexPath.row;
    if (row >= [vpc numberOfVideoSubtitlesIndexes]) {
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
