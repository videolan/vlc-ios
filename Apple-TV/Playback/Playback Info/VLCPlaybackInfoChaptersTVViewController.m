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

#import "VLCPlaybackInfoChaptersTVViewController.h"
#import "VLCPlaybackInfoCollectionViewDataSource.h"
#import "VLCPlaybackInfoTVCollectionViewCell.h"
#import "VLCPlaybackInfoTVCollectionSectionTitleView.h"

#define CONTENT_INSET 20.
@interface VLCPlaybackInfoTitlesDataSource : VLCPlaybackInfoCollectionViewDataSource <UICollectionViewDataSource, UICollectionViewDelegate>
// other collectionView which sould be updated when selection changes
@property (nonatomic) UICollectionView *dependendCollectionView;
@end

@interface VLCPlaybackInfoChaptersTVViewController ()
@property (nonatomic) IBOutlet VLCPlaybackInfoTitlesDataSource *titlesDataSource;
@property (nonatomic) IBOutlet VLCPlaybackInfoCollectionViewDataSource *chaptersDataSource;
@end

@implementation VLCPlaybackInfoChaptersTVViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"CHAPTER_SELECTION_TITLE", nil);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UINib *nib = [UINib nibWithNibName:@"VLCPlaybackInfoTVCollectionViewCell" bundle:nil];
    NSString *identifier = [VLCPlaybackInfoTVCollectionViewCell identifier];

    [self.titlesCollectionView registerNib:nib forCellWithReuseIdentifier:identifier];
    [VLCPlaybackInfoTVCollectionSectionTitleView registerInCollectionView:self.titlesCollectionView];

    [self.chaptersCollectionView registerNib:nib forCellWithReuseIdentifier:identifier];
    [VLCPlaybackInfoTVCollectionSectionTitleView registerInCollectionView:self.chaptersCollectionView];

    NSLocale *currentLocale = [NSLocale currentLocale];

    self.titlesDataSource.title = [NSLocalizedString(@"TITLE", nil) uppercaseStringWithLocale:currentLocale];
    self.titlesDataSource.cellIdentifier = [VLCPlaybackInfoTVCollectionViewCell identifier];
    self.chaptersDataSource.title = [NSLocalizedString(@"CHAPTER", nil) uppercaseStringWithLocale:currentLocale];
    self.chaptersDataSource.cellIdentifier = [VLCPlaybackInfoTVCollectionViewCell identifier];

    self.titlesDataSource.dependendCollectionView = self.chaptersCollectionView;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerChanged) name:VLCPlaybackControllerPlaybackMetadataDidChange object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (BOOL)shouldBeVisibleForPlaybackController:(VLCPlaybackController *)vpc
{
    return vpc.currentMediaHasChapters;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self mediaPlayerChanged];
}

- (CGSize)preferredContentSize
{
    CGFloat prefferedHeight = MAX(self.titlesCollectionView.contentSize.height, self.chaptersCollectionView.contentSize.height) + CONTENT_INSET;
    return CGSizeMake(CGRectGetWidth(self.view.bounds), prefferedHeight);
}

- (void)mediaPlayerChanged
{
    [self.titlesCollectionView reloadData];
    [self.chaptersCollectionView reloadData];
}

@end


@interface VLCPlaybackInfoChaptersDataSource : VLCPlaybackInfoCollectionViewDataSource <UICollectionViewDataSource, UICollectionViewDelegate>
@end

@implementation VLCPlaybackInfoTitlesDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.mediaPlayer.numberOfTitles;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackInfoTVCollectionViewCell *trackCell = (VLCPlaybackInfoTVCollectionViewCell*)cell;
    NSInteger row = indexPath.row;

    BOOL isSelected = self.mediaPlayer.currentTitleIndex == row;
    trackCell.selectionMarkerVisible = isSelected;

    NSDictionary *description = self.mediaPlayer.titleDescriptions[row];
    NSString *tileName = [NSString stringWithFormat:@"%@ (%@)", description[VLCTitleDescriptionName], [[VLCTime timeWithNumber:description[VLCTitleDescriptionDuration]] stringValue]];
    trackCell.titleLabel.text = tileName;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.mediaPlayer.currentTitleIndex = (int)indexPath.row;
    [collectionView reloadData];
    [self.dependendCollectionView reloadData];
}
@end

@implementation VLCPlaybackInfoChaptersDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    VLCMediaPlayer *player = self.mediaPlayer;
    return [player numberOfChaptersForTitle:player.currentTitleIndex];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackInfoTVCollectionViewCell *trackCell = (VLCPlaybackInfoTVCollectionViewCell*)cell;
    NSInteger row = indexPath.row;
    VLCMediaPlayer *player = self.mediaPlayer;

    BOOL isSelected = player.currentChapterIndex == row;
    trackCell.selectionMarkerVisible = isSelected;

    NSDictionary *description = [player chapterDescriptionsOfTitle:player.currentTitleIndex][row];
    NSString *chapterTitle = [NSString stringWithFormat:@"%@ (%@)", description[VLCChapterDescriptionName], [[VLCTime timeWithNumber:description[VLCChapterDescriptionDuration]] stringValue]];
    trackCell.titleLabel.text = chapterTitle;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.mediaPlayer.currentChapterIndex = (int)indexPath.row;
    [collectionView reloadData];
}

@end
