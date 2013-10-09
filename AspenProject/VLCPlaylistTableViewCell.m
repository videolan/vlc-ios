//
//  VLCPlaylistTableViewCell.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 01.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCPlaylistTableViewCell.h"
#import "VLCLinearProgressIndicator.h"
#import "VLCThumbnailsCache.h"
#import <MediaLibraryKit/MLAlbum.h>

@implementation VLCPlaylistTableViewCell

+ (VLCPlaylistTableViewCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray;
    if (SYSTEM_RUNS_IN_THE_FUTURE)
        nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCFuturePlaylistTableViewCell" owner:nil options:nil];
    else
        nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCPlaylistTableViewCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCPlaylistTableViewCell class]], @"meh meh");
    VLCPlaylistTableViewCell *cell = (VLCPlaylistTableViewCell *)[nibContentArray lastObject];

    return cell;
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self _updatedDisplayedInformationForKeyPath:@"editing"];
}

- (void)_updatedDisplayedInformationForKeyPath:(NSString *)keyPath
{
    self.albumNameLabel.text = self.artistNameLabel.text = @"";

    if ([self.mediaObject isKindOfClass:[MLFile class]]) {
        MLFile *mediaObject = (MLFile*)self.mediaObject;
        [self configureForMLFile:mediaObject];

        if (([keyPath isEqualToString:@"computedThumbnail"] || !keyPath) && !mediaObject.isAlbumTrack) {
            self.thumbnailView.image = [VLCThumbnailsCache thumbnailForMediaFile:mediaObject];
        }

    } else if ([self.mediaObject isKindOfClass:[MLAlbum class]]) {
        MLAlbum *mediaObject = (MLAlbum *)self.mediaObject;
        [self configureForAlbum:mediaObject];

    } else if ([self.mediaObject isKindOfClass:[MLAlbumTrack class]]) {
        MLAlbumTrack *mediaObject = (MLAlbumTrack *)self.mediaObject;
        [self configureForAlbumTrack:mediaObject];

    } else if ([self.mediaObject isKindOfClass:[MLShow class]]) {
        MLShow *mediaObject = (MLShow *)self.mediaObject;
        [self configureForShow:mediaObject];

        if ([keyPath isEqualToString:@"computedThumbnail"] || !keyPath) {
            MLFile *anyFileFromAnyEpisode = [mediaObject.episodes.anyObject files].anyObject;
            self.thumbnailView.image = [VLCThumbnailsCache thumbnailForMediaFile:anyFileFromAnyEpisode];
        }

    } else if ([self.mediaObject isKindOfClass:[MLShowEpisode class]]) {
        MLShowEpisode *mediaObject = (MLShowEpisode *)self.mediaObject;
        [self configureForShowEpisode:mediaObject];

        if ([keyPath isEqualToString:@"computedThumbnail"] || !keyPath) {
            MLFile *anyFileFromEpisode = mediaObject.files.anyObject;
            self.thumbnailView.image = [VLCThumbnailsCache thumbnailForMediaFile:anyFileFromEpisode];
        }
    }

    [self setNeedsDisplay];
}

+ (CGFloat)heightOfCell
{
    if (SYSTEM_RUNS_IN_THE_FUTURE)
        return 90.;

    return 80.;
}

#pragma mark - presentation

- (void)configureForShow:(MLShow *)show
{
    self.titleLabel.text = show.name;
    NSUInteger count = show.episodes.count;
    if (SYSTEM_RUNS_IN_THE_FUTURE) {
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@ — %@", show.releaseYear, [NSString stringWithFormat:(count > 1) ? NSLocalizedString(@"LIBRARY_EPISODES", @"") : NSLocalizedString(@"LIBRARY_SINGLE_EPISODE", @""), count, show.unreadEpisodes.count]];
    } else {
        self.artistNameLabel.text = @"";
        self.albumNameLabel.text = show.releaseYear;
        self.subtitleLabel.text = [NSString stringWithFormat:(count > 1) ? NSLocalizedString(@"LIBRARY_EPISODES", @"") : NSLocalizedString(@"LIBRARY_SINGLE_EPISODE", @""), count, show.unreadEpisodes.count];
    }
    self.mediaIsUnreadView.hidden = YES;
    self.progressIndicator.hidden = YES;
}

- (void)configureForAlbumTrack:(MLAlbumTrack *)albumTrack
{
    MLFile *anyFileFromTrack = albumTrack.files.anyObject;

    if (SYSTEM_RUNS_IN_THE_FUTURE)
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@ — %@ — %@", albumTrack.artist, [NSString stringWithFormat:NSLocalizedString(@"LIBRARY_TRACK_N", @""), albumTrack.trackNumber.intValue], [VLCTime timeWithNumber:[anyFileFromTrack duration]]];
    else {
        self.artistNameLabel.text = albumTrack.artist;
        self.albumNameLabel.text = [NSString stringWithFormat:NSLocalizedString(@"LIBRARY_TRACK_N", @""), albumTrack.trackNumber.intValue];
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@", [VLCTime timeWithNumber:[anyFileFromTrack duration]]];
    }
    self.titleLabel.text = albumTrack.title;
    self.thumbnailView.image = nil;

    CGFloat position = anyFileFromTrack.lastPosition.floatValue;
    self.progressIndicator.progress = position;
    self.progressIndicator.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
    [self.progressIndicator setNeedsDisplay];
    self.mediaIsUnreadView.hidden = !anyFileFromTrack.unread.intValue;
}

- (void)configureForShowEpisode:(MLShowEpisode *)showEpisode
{
    self.titleLabel.text = showEpisode.name;

    MLFile *anyFileFromEpisode = showEpisode.files.anyObject;
    if (self.titleLabel.text.length < 1) {
        self.titleLabel.text = [NSString stringWithFormat:@"S%02dE%02d", showEpisode.seasonNumber.intValue, showEpisode.episodeNumber.intValue];
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@", [VLCTime timeWithNumber:[anyFileFromEpisode duration]]];
    } else
        self.subtitleLabel.text = [NSString stringWithFormat:@"S%02dE%02d — %@", showEpisode.seasonNumber.intValue, showEpisode.episodeNumber.intValue, [VLCTime timeWithNumber:[anyFileFromEpisode duration]]];

    CGFloat position = anyFileFromEpisode.lastPosition.floatValue;
    self.progressIndicator.progress = position;
    self.progressIndicator.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
    [self.progressIndicator setNeedsDisplay];
    self.mediaIsUnreadView.hidden = !showEpisode.unread.intValue;
}

- (void)configureForAlbum:(MLAlbum *)album
{
    self.titleLabel.text = album.name;
    MLAlbumTrack *anyTrack = [album.tracks anyObject];
    NSUInteger count = album.tracks.count;
    if (SYSTEM_RUNS_IN_THE_FUTURE) {
        NSMutableString *string = [[NSMutableString alloc] init];
        if (anyTrack) {
            [string appendString:anyTrack.artist];
            [string appendString:@" — "];
        }
        [string appendFormat:@"%@ — %@", [NSString stringWithFormat:(count > 1) ? NSLocalizedString(@"LIBRARY_TRACKS", @"") : NSLocalizedString(@"LIBRARY_SINGLE_TRACK", @""), count], album.releaseYear];
        self.subtitleLabel.text = string;
    } else {
        self.artistNameLabel.text = anyTrack? anyTrack.artist: @"";
        self.albumNameLabel.text = album.releaseYear;
        self.subtitleLabel.text = [NSString stringWithFormat:(count > 1) ? NSLocalizedString(@"LIBRARY_TRACKS", @"") : NSLocalizedString(@"LIBRARY_SINGLE_TRACK", @""), count];
    }
    self.thumbnailView.image = nil;
    self.mediaIsUnreadView.hidden = YES;
    self.progressIndicator.hidden = YES;
}

- (void)configureForMLFile:(MLFile *)mediaFile
{
    if (mediaFile.isAlbumTrack) {
        if (SYSTEM_RUNS_IN_THE_FUTURE) {
            self.titleLabel.text = [NSString stringWithFormat:@"%@ — %@ — %@", mediaFile.albumTrack.artist, mediaFile.albumTrack.album.name, (mediaFile.albumTrack.title.length > 1) ? mediaFile.albumTrack.title : mediaFile.title];
        } else {
            self.artistNameLabel.text = mediaFile.albumTrack.artist;
            self.albumNameLabel.text = mediaFile.albumTrack.album.name;
            self.titleLabel.text = (mediaFile.albumTrack.title.length > 1) ? mediaFile.albumTrack.title : mediaFile.title;
        }
        self.thumbnailView.image = nil;
    } else
        self.titleLabel.text = mediaFile.title;

    if (self.isEditing)
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@ — %i MB", [VLCTime timeWithNumber:[mediaFile duration]], (int)([mediaFile fileSizeInBytes] / 1e6)];
    else {
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@", [VLCTime timeWithNumber:[mediaFile duration]]];
        if (mediaFile.videoTrack) {
            NSString *width = [[mediaFile videoTrack] valueForKey:@"width"];
            NSString *height = [[mediaFile videoTrack] valueForKey:@"height"];
            if (width.intValue > 0 && height.intValue > 0)
                self.subtitleLabel.text = [self.subtitleLabel.text stringByAppendingFormat:@" — %@x%@", width, height];
        }
    }

    CGFloat position = mediaFile.lastPosition.floatValue;
    self.progressIndicator.progress = position;
    self.progressIndicator.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
    [self.progressIndicator setNeedsDisplay];
    self.mediaIsUnreadView.hidden = !mediaFile.unread.intValue;
}

@end
