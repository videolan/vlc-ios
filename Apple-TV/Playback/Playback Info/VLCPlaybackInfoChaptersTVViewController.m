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

+ (BOOL)shouldBeVisibleForPlaybackController:(VLCPlaybackController *)vpc
{
    return [vpc numberOfChaptersForCurrentTitle] > 1;
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
    return [[VLCPlaybackController sharedInstance] numberOfTitles];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackInfoTVCollectionViewCell *trackCell = (VLCPlaybackInfoTVCollectionViewCell*)cell;
    NSInteger row = indexPath.row;
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];

    BOOL isSelected = [vpc indexOfCurrentTitle] == row;
    trackCell.selectionMarkerVisible = isSelected;

    NSDictionary *description = [vpc titleDescriptionsDictAtIndex:row];
    NSString *title = description[VLCTitleDescriptionName];
    if (title == nil)
        title = [NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"TITLE", nil), row];
    NSString *titleName = [NSString stringWithFormat:@"%@ (%@)", title, [[VLCTime timeWithNumber:description[VLCTitleDescriptionDuration]] stringValue]];
    trackCell.titleLabel.text = titleName;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [[VLCPlaybackController sharedInstance] selectTitleAtIndex:indexPath.row];
    [collectionView reloadData];
    [self.dependendCollectionView reloadData];
}
@end

@implementation VLCPlaybackInfoChaptersDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[VLCPlaybackController sharedInstance] numberOfChaptersForCurrentTitle];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackInfoTVCollectionViewCell *trackCell = (VLCPlaybackInfoTVCollectionViewCell*)cell;
    NSInteger row = indexPath.row;

    BOOL isSelected = [[VLCPlaybackController sharedInstance] indexOfCurrentChapter] == row;
    trackCell.selectionMarkerVisible = isSelected;

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSDictionary *description = [vpc chapterDescriptionsDictAtIndex:[vpc indexOfCurrentTitle]];

    NSString *chapter = description[VLCChapterDescriptionName];
    if (chapter == nil)
        chapter = [NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"CHAPTER", nil), row];
    NSString *chapterTitle = [NSString stringWithFormat:@"%@ (%@)", chapter, [[VLCTime timeWithNumber:description[VLCChapterDescriptionDuration]] stringValue]];
    trackCell.titleLabel.text = chapterTitle;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [[VLCPlaybackController sharedInstance] selectChapterAtIndex:indexPath.row];
    [collectionView reloadData];
}

@end
