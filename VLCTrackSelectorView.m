/*****************************************************************************
 * VLCTrackSelectorView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCTrackSelectorView.h"

#import "VLCPlaybackController.h"
#import "VLCTrackSelectorHeaderView.h"
#import "VLCTrackSelectorTableViewCell.h"

#import "UIDevice+VLC.h"

#define TRACK_SELECTOR_TABLEVIEW_CELL @"track selector table view cell"
#define TRACK_SELECTOR_TABLEVIEW_SECTIONHEADER @"track selector table view section header"

@interface VLCTrackSelectorView() <UITableViewDataSource, UITableViewDelegate>
{
    UITableView *_trackSelectorTableView;
    NSLayoutConstraint *_heightConstraint;
}
@end

@implementation VLCTrackSelectorView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        _trackSelectorTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _trackSelectorTableView.delegate = self;
        _trackSelectorTableView.dataSource = self;
        _trackSelectorTableView.separatorColor = [UIColor clearColor];
        _trackSelectorTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        _trackSelectorTableView.rowHeight = 44.;
        _trackSelectorTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _trackSelectorTableView.sectionHeaderHeight = 28.;
        [_trackSelectorTableView registerClass:[VLCTrackSelectorTableViewCell class] forCellReuseIdentifier:TRACK_SELECTOR_TABLEVIEW_CELL];
        [_trackSelectorTableView registerClass:[VLCTrackSelectorHeaderView class] forHeaderFooterViewReuseIdentifier:TRACK_SELECTOR_TABLEVIEW_SECTIONHEADER];
        _trackSelectorTableView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_trackSelectorTableView];
        [self setupConstraints];
        [self configureForDeviceCategory];
    }
    return self;
}

- (void)configureForDeviceCategory {
    if ([[UIDevice currentDevice] VLCSpeedCategory] >= 3) {
        _trackSelectorTableView.opaque = NO;
        _trackSelectorTableView.backgroundColor = [UIColor clearColor];
    } else {
        _trackSelectorTableView.backgroundColor = [UIColor blackColor];
    }
    _trackSelectorTableView.allowsMultipleSelection = YES;
}

- (void)layoutSubviews
{
    CGFloat height = _trackSelectorTableView.contentSize.height;
    _heightConstraint.constant = height;
    [super layoutSubviews];
}

- (void)setupConstraints
{
    _heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:44];
    _heightConstraint.priority = UILayoutPriorityDefaultHigh;
    NSArray *constraints = @[
                             [NSLayoutConstraint constraintWithItem:_trackSelectorTableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_trackSelectorTableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_trackSelectorTableView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_trackSelectorTableView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0],
                             _heightConstraint,
                             ];
    [NSLayoutConstraint activateConstraints:constraints];
}
#pragma mark - track selector table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger ret = 0;
    VLCMediaPlayer *mediaPlayer = [VLCPlaybackController sharedInstance].mediaPlayer;

    if (_switchingTracksNotChapters) {
        if (mediaPlayer.audioTrackIndexes.count > 2)
            ret++;

        if (mediaPlayer.videoSubTitlesIndexes.count > 1)
            ret++;
    } else {
        if ([mediaPlayer numberOfTitles] > 1)
            ret++;

        if ([mediaPlayer numberOfChaptersForTitle:mediaPlayer.currentTitleIndex] > 1)
            ret++;
    }

    return ret;
}

- (void)updateView
{
    [_trackSelectorTableView reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:TRACK_SELECTOR_TABLEVIEW_SECTIONHEADER];

    if (!view) {
        view = [[VLCTrackSelectorHeaderView alloc] initWithReuseIdentifier:TRACK_SELECTOR_TABLEVIEW_SECTIONHEADER];
    }
    return view;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    VLCMediaPlayer *mediaPlayer =  [VLCPlaybackController sharedInstance].mediaPlayer;

    if (_switchingTracksNotChapters == YES) {
        if (mediaPlayer.audioTrackIndexes.count > 2 && section == 0)
            return NSLocalizedString(@"CHOOSE_AUDIO_TRACK", nil);

        if (mediaPlayer.videoSubTitlesIndexes.count > 1)
            return NSLocalizedString(@"CHOOSE_SUBTITLE_TRACK", nil);
    } else {
        if ([mediaPlayer numberOfTitles] > 1 && section == 0)
            return NSLocalizedString(@"CHOOSE_TITLE", nil);

        if ([mediaPlayer numberOfChaptersForTitle:mediaPlayer.currentTitleIndex] > 1)
            return NSLocalizedString(@"CHOOSE_CHAPTER", nil);
    }

    return @"unknown track type";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCTrackSelectorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TRACK_SELECTOR_TABLEVIEW_CELL];

    if (!cell) {
        cell = [[VLCTrackSelectorTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TRACK_SELECTOR_TABLEVIEW_CELL];
    }
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    VLCMediaPlayer *mediaPlayer =  [VLCPlaybackController sharedInstance].mediaPlayer;
    BOOL cellShowsCurrentTrack = NO;

    if (_switchingTracksNotChapters) {
        NSArray *indexArray;
        NSString *trackName;
        if ([mediaPlayer numberOfAudioTracks] > 2 && section == 0) {
            indexArray = mediaPlayer.audioTrackIndexes;

            if ([indexArray indexOfObject:[NSNumber numberWithInt:mediaPlayer.currentAudioTrackIndex]] == row)
                cellShowsCurrentTrack = YES;

            NSArray *audioTrackNames = mediaPlayer.audioTrackNames;
            if (row < audioTrackNames.count) {
                trackName = audioTrackNames[row];
            }
        } else {
            indexArray = mediaPlayer.videoSubTitlesIndexes;

            if ([indexArray indexOfObject:[NSNumber numberWithInt:mediaPlayer.currentVideoSubTitleIndex]] == row)
                cellShowsCurrentTrack = YES;

            NSArray *videoSubtitlesNames = mediaPlayer.videoSubTitlesNames;
            if (row < videoSubtitlesNames.count) {
                trackName = mediaPlayer.videoSubTitlesNames[row];
            }
        }

        if (trackName != nil) {
            if ([trackName isEqualToString:@"Disable"]) {
                cell.textLabel.text = NSLocalizedString(@"DISABLE_LABEL", nil);
            } else {
                cell.textLabel.text = trackName;
            }
        }
    } else {
        if ([mediaPlayer numberOfTitles] > 1 && section == 0) {
            NSArray *titleDescriptions = mediaPlayer.titleDescriptions;
            if (row < titleDescriptions.count) {
                NSDictionary *description = titleDescriptions[row];
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", description[VLCTitleDescriptionName], [[VLCTime timeWithNumber:description[VLCTitleDescriptionDuration]] stringValue]];
            }

            if (row == mediaPlayer.currentTitleIndex)
                cellShowsCurrentTrack = YES;
        } else {
            NSArray *chapterDescriptions = [mediaPlayer chapterDescriptionsOfTitle:mediaPlayer.currentTitleIndex];
            if (row < chapterDescriptions.count) {
                NSDictionary *description = chapterDescriptions[row];
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", description[VLCChapterDescriptionName], [[VLCTime timeWithNumber:description[VLCChapterDescriptionDuration]] stringValue]];
            }

            if (row == mediaPlayer.currentChapterIndex)
                cellShowsCurrentTrack = YES;
        }
    }
    [cell setShowsCurrentTrack:cellShowsCurrentTrack];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    VLCMediaPlayer *mediaPlayer =  [VLCPlaybackController sharedInstance].mediaPlayer;

    if (_switchingTracksNotChapters == YES) {
        NSInteger audioTrackCount = mediaPlayer.audioTrackIndexes.count;

        if (audioTrackCount > 2 && section == 0)
            return audioTrackCount;

        return mediaPlayer.videoSubTitlesIndexes.count;
    } else {
        if ([mediaPlayer numberOfTitles] > 1 && section == 0)
            return [mediaPlayer numberOfTitles];
        else
            return [mediaPlayer numberOfChaptersForTitle:mediaPlayer.currentTitleIndex];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSInteger index = indexPath.row;
    VLCMediaPlayer *mediaPlayer =  [VLCPlaybackController sharedInstance].mediaPlayer;

    if (_switchingTracksNotChapters) {
        NSArray *indexArray;
        if (mediaPlayer.audioTrackIndexes.count > 2 && indexPath.section == 0) {
            indexArray = mediaPlayer.audioTrackIndexes;
            if (index <= indexArray.count)
                mediaPlayer.currentAudioTrackIndex = [indexArray[index] intValue];

        } else {
            indexArray = mediaPlayer.videoSubTitlesIndexes;
            if (index <= indexArray.count)
                mediaPlayer.currentVideoSubTitleIndex = [indexArray[index] intValue];
        }
    } else {
        if ([mediaPlayer numberOfTitles] > 1 && indexPath.section == 0)
            mediaPlayer.currentTitleIndex = (int)index;
        else
            mediaPlayer.currentChapterIndex = (int)index;
    }

    self.alpha = 1.0f;
    void (^animationBlock)() = ^() {
        self.alpha =  0.0f;;
    };

    NSTimeInterval animationDuration = .3;
    [UIView animateWithDuration:animationDuration animations:animationBlock completion:_completionHandler];
}
@end
