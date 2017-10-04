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
    if (self) {
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

- (void)configureForDeviceCategory
{
    _trackSelectorTableView.opaque = NO;
    _trackSelectorTableView.backgroundColor = [UIColor clearColor];
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
    NSInteger sections = 0;
    VLCPlaybackController *playbackController = [VLCPlaybackController sharedInstance];

    if (_switchingTracksNotChapters) {
        if([playbackController numberOfAudioTracks] > 2)
            sections++;

        if ([playbackController numberOfVideoSubtitlesIndexes] > 1)
            sections++;
    } else {
        if ([playbackController numberOfTitles] > 1)
            sections++;

        if ([playbackController numberOfChaptersForCurrentTitle] > 1)
            sections++;
    }

    return sections;
}

- (void)updateView
{
    [_trackSelectorTableView reloadData];
    [self setNeedsLayout];
    [self layoutIfNeeded];
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
    VLCPlaybackController *playbackController = [VLCPlaybackController sharedInstance];

    if (_switchingTracksNotChapters) {
        if ([playbackController numberOfAudioTracks] > 2 && section == 0)
            return NSLocalizedString(@"CHOOSE_AUDIO_TRACK", nil);

        if ([playbackController numberOfVideoSubtitlesIndexes] > 1)
            return NSLocalizedString(@"CHOOSE_SUBTITLE_TRACK", nil);
    } else {
        if ([playbackController numberOfTitles] > 1 && section == 0)
            return NSLocalizedString(@"CHOOSE_TITLE", nil);

        if ([playbackController numberOfChaptersForCurrentTitle] > 1)
            return NSLocalizedString(@"CHOOSE_CHAPTER", nil);
    }

    return @"unknown track type";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCTrackSelectorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TRACK_SELECTOR_TABLEVIEW_CELL forIndexPath:indexPath];

    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    VLCPlaybackController *playbackController = [VLCPlaybackController sharedInstance];

    if (_switchingTracksNotChapters) {
        NSString *trackName;
        if ([playbackController numberOfAudioTracks] > 2 && section == 0) {
            if ([playbackController indexOfCurrentAudioTrack] == row) {
                [cell setShowsCurrentTrack];
            }

            trackName = [playbackController audioTrackNameAtIndex:row];
        } else {
            if ([playbackController indexOfCurrentSubtitleTrack] == row) {
                [cell setShowsCurrentTrack];
            }

            trackName = [playbackController videoSubtitleNameAtIndex:row];
        }

        if ([trackName isEqualToString:@"Disable"]) {
            cell.textLabel.text = NSLocalizedString(@"DISABLE_LABEL", nil);
        } else {
            cell.textLabel.text = trackName;
        }
    } else {
        if ([playbackController numberOfTitles] > 1 && section == 0) {

            NSDictionary *description = [playbackController titleDescriptionsDictAtIndex:row];
            if(description != nil) {
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", description[VLCTitleDescriptionName], [[VLCTime timeWithNumber:description[VLCTitleDescriptionDuration]] stringValue]];
            }

            if (row == [playbackController indexOfCurrentTitle]) {
                [cell setShowsCurrentTrack];
            }
        } else {
            NSDictionary *description = [playbackController chapterDescriptionsDictAtIndex:row];
            if (description != nil)
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", description[VLCChapterDescriptionName], [[VLCTime timeWithNumber:description[VLCChapterDescriptionDuration]] stringValue]];
        }

        if (row == [playbackController indexOfCurrentChapter])
            [cell setShowsCurrentTrack];
    }

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    VLCPlaybackController *playbackController = [VLCPlaybackController sharedInstance];

    if (_switchingTracksNotChapters) {
        if ([playbackController numberOfAudioTracks] > 2 && section == 0)
            return [playbackController numberOfAudioTracks];

        return [playbackController numberOfVideoSubtitlesIndexes];
    } else {
        if ([playbackController numberOfTitles] > 1 && section == 0)
            return [playbackController numberOfTitles];
        else
            return [playbackController numberOfChaptersForCurrentTitle];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSInteger index = indexPath.row;
    VLCPlaybackController *playbackController = [VLCPlaybackController sharedInstance];

    if (_switchingTracksNotChapters) {
        if ([playbackController numberOfAudioTracks] > 2 && indexPath.section == 0) {
            [playbackController selectAudioTrackAtIndex:index];

        } else if (index <= [playbackController numberOfVideoSubtitlesIndexes]) {
            [playbackController selectVideoSubtitleAtIndex:index];
        }
    } else {
        if ([playbackController numberOfTitles] > 1 && indexPath.section == 0)
            [playbackController selectTitleAtIndex:index];
        else
            [playbackController selectChapterAtIndex:index];
    }

    self.alpha = 1.0f;
    void (^animationBlock)() = ^() {
        self.alpha =  0.0f;;
    };

    NSTimeInterval animationDuration = .3;
    [UIView animateWithDuration:animationDuration animations:animationBlock completion:_completionHandler];
}
@end
