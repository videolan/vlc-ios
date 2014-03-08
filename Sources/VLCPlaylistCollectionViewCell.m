/*****************************************************************************
 * VLCPlaylistCollectionViewCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaylistCollectionViewCell.h"
#import "VLCPlaylistViewController.h"
#import "VLCThumbnailsCache.h"

@interface VLCPlaylistCollectionViewCell ()
{
    UIImage *_checkboxEmptyImage;
    UIImage *_checkboxImage;
}

@end

@implementation VLCPlaylistCollectionViewCell

- (void)awakeFromNib
{
    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        _checkboxEmptyImage = [UIImage imageNamed:@"checkboxEmpty"];
        _checkboxImage = [UIImage imageNamed:@"checkbox"];
    } else {
        _checkboxEmptyImage = [UIImage imageNamed:@"checkbox-legacy-empty"];
        _checkboxImage = [UIImage imageNamed:@"checkbox-legacy"];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    self.isSelectedView.hidden = !editing;

    if (!([_mediaObject isKindOfClass:[MLFile class]] && [_mediaObject.labels count] > 0))
        [self shake:editing];
    [self selectionUpdate];
    [self _updatedDisplayedInformationForKeyPath:@"editing"];
}

- (void)selectionUpdate
{
    if (self.selected)
        self.isSelectedView.image = _checkboxImage;
    else
        self.isSelectedView.image = _checkboxEmptyImage;
}

- (void)shake:(BOOL)shake
{
    if (shake) {
        [UIView animateWithDuration:0.3 animations:^{
            self.contentView.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
        }];
        CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
        CGFloat shakeAngle = 0.02f;
        animation.values = @[@(-shakeAngle), @(shakeAngle)];
        animation.autoreverses = YES;
        animation.duration = 0.125;
        animation.repeatCount = HUGE_VALF;

        [[self layer] addAnimation:animation forKey:@"shakeAnimation"];
        self.contentView.layer.cornerRadius = 10.0;
        self.contentView.clipsToBounds = YES;
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.contentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
            self.contentView.layer.cornerRadius = 0.0;
            self.contentView.clipsToBounds = NO;
        }];
        [[self layer] removeAnimationForKey:@"shakeAnimation"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self _updatedDisplayedInformationForKeyPath:keyPath];
}

- (void)setMediaObject:(MLFile *)mediaObject
{
    if (_mediaObject != mediaObject) {
        [_mediaObject removeObserver:self forKeyPath:@"computedThumbnail"];
        [_mediaObject removeObserver:self forKeyPath:@"lastPosition"];
        [_mediaObject removeObserver:self forKeyPath:@"duration"];
        [_mediaObject removeObserver:self forKeyPath:@"fileSizeInBytes"];
        [_mediaObject removeObserver:self forKeyPath:@"title"];
        [_mediaObject removeObserver:self forKeyPath:@"thumbnailTimeouted"];
        [_mediaObject removeObserver:self forKeyPath:@"unread"];
        [_mediaObject removeObserver:self forKeyPath:@"albumTrackNumber"];
        [_mediaObject removeObserver:self forKeyPath:@"album"];
        [_mediaObject removeObserver:self forKeyPath:@"artist"];
        [_mediaObject removeObserver:self forKeyPath:@"genre"];
        if ([_mediaObject respondsToSelector:@selector(didHide)])
            [(MLFile*)_mediaObject didHide];

        _mediaObject = mediaObject;

        [_mediaObject addObserver:self forKeyPath:@"computedThumbnail" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"lastPosition" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"duration" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"fileSizeInBytes" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"title" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"thumbnailTimeouted" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"unread" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"albumTrackNumber" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"album" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"artist" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"genre" options:0 context:nil];

        if ([_mediaObject respondsToSelector:@selector(willDisplay)])
            [(MLFile*)_mediaObject willDisplay];
    }

    [self _updatedDisplayedInformationForKeyPath:nil];
}

- (void)_updatedDisplayedInformationForKeyPath:(NSString *)keyPath
{
    BOOL isFolder = [self.mediaObject isKindOfClass:[MLLabel class]];
    self.thumbnailView.contentMode = isFolder ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
    if ([self.mediaObject isKindOfClass:[MLFile class]]) {
        MLFile *mediaObject = self.mediaObject;
        [self _configureForMLFile:mediaObject];

        if (([keyPath isEqualToString:@"computedThumbnail"] || !keyPath) || (!self.thumbnailView.image && [keyPath isEqualToString:@"editing"]))
            self.thumbnailView.image = [VLCThumbnailsCache thumbnailForMediaFile:mediaObject];
    } else if ([self.mediaObject isKindOfClass:[MLLabel class]]) {
        MLLabel *mediaObject = (MLLabel *)self.mediaObject;
        [self _configureForFolder:mediaObject];

        if (([keyPath isEqualToString:@"computedThumbnail"] || !keyPath) || (!self.thumbnailView.image && [keyPath isEqualToString:@"editing"])) {
            if (mediaObject.files.count == 0)
                self.thumbnailView.image = [UIImage imageNamed:@"folderIcon"];
            else
                self.thumbnailView.image = [VLCThumbnailsCache thumbnailForLabel:mediaObject];
        }
    } else if ([self.mediaObject isKindOfClass:[MLAlbum class]]) {
        MLAlbum *mediaObject = (MLAlbum *)self.mediaObject;
        [self _configureForAlbum:mediaObject];

        if ([keyPath isEqualToString:@"computedThumbnail"] || !keyPath || (!self.thumbnailView.image && [keyPath isEqualToString:@"editing"])) {
            MLFile *anyFileFromAnyTrack = [mediaObject.tracks.anyObject files].anyObject;
            self.thumbnailView.image = [VLCThumbnailsCache thumbnailForMediaFile:anyFileFromAnyTrack];
        }
    } else if ([self.mediaObject isKindOfClass:[MLAlbumTrack class]]) {
        MLAlbumTrack *mediaObject = (MLAlbumTrack *)self.mediaObject;
        [self _configureForAlbumTrack:mediaObject];

        if ([keyPath isEqualToString:@"computedThumbnail"] || !keyPath || (!self.thumbnailView.image && [keyPath isEqualToString:@"editing"])) {
            MLFile *anyFileFromTrack = mediaObject.files.anyObject;
            self.thumbnailView.image = [VLCThumbnailsCache thumbnailForMediaFile:anyFileFromTrack];
        }
    } else if ([self.mediaObject isKindOfClass:[MLShow class]]) {
        MLShow *mediaObject = (MLShow *)self.mediaObject;
        [self _configureForShow:mediaObject];

        if ([keyPath isEqualToString:@"computedThumbnail"] || !keyPath || (!self.thumbnailView.image && [keyPath isEqualToString:@"editing"])) {
            self.thumbnailView.image = [VLCThumbnailsCache thumbnailForShow:mediaObject];
        }
    } else if ([self.mediaObject isKindOfClass:[MLShowEpisode class]]) {
        MLShowEpisode *mediaObject = (MLShowEpisode *)self.mediaObject;
        [self _configureForShowEpisode:mediaObject];

        if ([keyPath isEqualToString:@"computedThumbnail"] || !keyPath || (!self.thumbnailView.image && [keyPath isEqualToString:@"editing"])) {
            MLFile *anyFileFromEpisode = mediaObject.files.anyObject;
            self.thumbnailView.image = [VLCThumbnailsCache thumbnailForMediaFile:anyFileFromEpisode];
        }
    }

    [self setNeedsDisplay];
}

#pragma mark - presentation

- (void)_configureForShow:(MLShow *)show
{
    self.titleLabel.text = show.name;
    NSUInteger count = show.episodes.count;
    NSString *string = @"";
    if (show.releaseYear)
        string = [NSString stringWithFormat:@"%@ — ", show.releaseYear];
    self.subtitleLabel.text = [string stringByAppendingString:[NSString stringWithFormat:(count > 1) ? NSLocalizedString(@"LIBRARY_EPISODES", @"") : NSLocalizedString(@"LIBRARY_SINGLE_EPISODE", @""), count, show.unreadEpisodes.count]];
    self.mediaIsUnreadView.hidden = YES;
    self.progressView.hidden = YES;
}

- (void)_configureForAlbumTrack:(MLAlbumTrack *)albumTrack
{
    MLFile *anyFileFromTrack = albumTrack.files.anyObject;

    self.subtitleLabel.text = [NSString stringWithFormat:@"%@ — %@ — %@", albumTrack.artist, [NSString stringWithFormat:NSLocalizedString(@"LIBRARY_TRACK_N", @""), albumTrack.trackNumber.intValue], [VLCTime timeWithNumber:[anyFileFromTrack duration]]];
    self.titleLabel.text = albumTrack.title;

    [self _showPositionOfItem:anyFileFromTrack];
}

- (void)_configureForShowEpisode:(MLShowEpisode *)showEpisode
{
    self.titleLabel.text = showEpisode.name;

    MLFile *anyFileFromEpisode = showEpisode.files.anyObject;
    if (self.titleLabel.text.length < 1) {
        self.titleLabel.text = [NSString stringWithFormat:@"S%02dE%02d", showEpisode.seasonNumber.intValue, showEpisode.episodeNumber.intValue];
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@", [VLCTime timeWithNumber:[anyFileFromEpisode duration]]];
    } else
        self.subtitleLabel.text = [NSString stringWithFormat:@"S%02dE%02d — %@", showEpisode.seasonNumber.intValue, showEpisode.episodeNumber.intValue, [VLCTime timeWithNumber:[anyFileFromEpisode duration]]];
    [self _showPositionOfItem:anyFileFromEpisode];
}

- (void)_configureForAlbum:(MLAlbum *)album
{
    self.titleLabel.text = album.name;
    MLAlbumTrack *anyTrack = [album.tracks anyObject];
    NSUInteger count = album.tracks.count;
    NSMutableString *string = [[NSMutableString alloc] init];
    if (anyTrack) {
        [string appendString:anyTrack.artist];
        [string appendString:@" — "];
    }
    [string appendString:[NSString stringWithFormat:(count > 1) ? NSLocalizedString(@"LIBRARY_TRACKS", @"") : NSLocalizedString(@"LIBRARY_SINGLE_TRACK", @""), count]];
    if (album.releaseYear)
        [string appendFormat:@" — %@", album.releaseYear];
    self.subtitleLabel.text = string;
    self.mediaIsUnreadView.hidden = YES;
    self.progressView.hidden = YES;
}

- (void)_configureForFolder:(MLLabel *)label
{
    self.titleLabel.text = label.name;
    NSUInteger count = label.files.count;
    self.subtitleLabel.text = [NSString stringWithFormat:(count == 1) ? NSLocalizedString(@"LIBRARY_SINGLE_TRACK", @"") : NSLocalizedString(@"LIBRARY_TRACKS", @""), count];
    self.mediaIsUnreadView.hidden = YES;
    self.progressView.hidden = YES;
}

- (void)_configureForMLFile:(MLFile *)mediaFile
{
    if (mediaFile.isAlbumTrack) {
        NSString *string = @"";
        if (mediaFile.albumTrack.artist)
            string = [NSString stringWithFormat:@"%@ — ", mediaFile.albumTrack.artist];
        else if (mediaFile.albumTrack.album.name)
            string = [NSString stringWithFormat:@"%@ — ", mediaFile.albumTrack.artist];
        self.titleLabel.text = [string stringByAppendingString:(mediaFile.albumTrack.title.length > 1) ? mediaFile.albumTrack.title : mediaFile.title];
    } else
        self.titleLabel.text = mediaFile.title;

    VLCPlaylistViewController *delegate = (VLCPlaylistViewController*)self.collectionView.delegate;

    if (delegate.isEditing)
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@ — %@", [VLCTime timeWithNumber:[mediaFile duration]], [NSByteCountFormatter stringFromByteCount:[mediaFile fileSizeInBytes] countStyle:NSByteCountFormatterCountStyleFile]];
    else {
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@", [VLCTime timeWithNumber:[mediaFile duration]]];
        if (mediaFile.videoTrack) {
            NSString *width = [[mediaFile videoTrack] valueForKey:@"width"];
            NSString *height = [[mediaFile videoTrack] valueForKey:@"height"];
            if (width.intValue > 0 && height.intValue > 0)
                self.subtitleLabel.text = [self.subtitleLabel.text stringByAppendingFormat:@" — %@x%@", width, height];
        }
    }
    [self _showPositionOfItem:mediaFile];
}

- (void)_showPositionOfItem:(MLFile *)mediaItem
{
    CGFloat position = mediaItem.lastPosition.floatValue;

    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        CGFloat duration = mediaItem.duration.floatValue;
        if (position > .05f && position < .95f && (duration * position - duration) < -60000) {
            [(UITextView*)self.mediaIsUnreadView setText:[NSString stringWithFormat:NSLocalizedString(@"LIBRARY_MINUTES_LEFT", @""), [[VLCTime timeWithInt:(duration * position - duration)] minuteStringValue]]];
            self.mediaIsUnreadView.hidden = NO;
        } else if (mediaItem.unread.intValue) {
            [(UILabel *)self.mediaIsUnreadView setText:[NSLocalizedString(@"NEW", @"") capitalizedStringWithLocale:[NSLocale currentLocale]]];
            self.mediaIsUnreadView.hidden = NO;
        } else
            self.mediaIsUnreadView.hidden = YES;
    } else {
        self.progressView.progress = position;
        self.progressView.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
        [self.progressView setNeedsDisplay];
        self.mediaIsUnreadView.hidden = !mediaItem.unread.intValue;
    }
}

@end
