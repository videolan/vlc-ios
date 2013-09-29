//
//  VLCGridViewCell.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 11.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCPlaylistGridView.h"
#import "VLCLinearProgressIndicator.h"
#import "AQGridView.h"
#import "VLCThumbnailsCache.h"

@interface VLCPlaylistGridView (Hack)
@property (nonatomic, retain) NSString *reuseIdentifier;
@end

@implementation VLCPlaylistGridView

+ (CGSize)preferredSize
{
    return CGSizeMake(288, 220);
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _contentView = self;
    self.backgroundColor = [UIColor clearColor];
    self.reuseIdentifier = @"AQPlaylistCell";
    self.albumNameLabel.text = self.artistNameLabel.text = self.seriesNameLabel.text = @"";
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    self.removeMediaButton.hidden = !editing;
    [self _updatedDisplayedInformationForKeyPath:@"editing"];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.removeMediaButton.hidden = YES;
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
    self.albumNameLabel.text = self.artistNameLabel.text = self.seriesNameLabel.text = @"";

    if ([self.mediaObject isKindOfClass:[MLFile class]]) {
        MLFile *mediaObject = self.mediaObject;
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

- (IBAction)removeMedia:(id)sender
{
    /* ask user if s/he really wants to delete the media file */
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DELETE_FILE", @"") message:[NSString stringWithFormat:NSLocalizedString(@"DELETE_FILE_LONG", @""), self.mediaObject.title] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:NSLocalizedString(@"BUTTON_DELETE", @""), nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSUInteger cellIndex = [self.gridView indexForCell:self];
        [self.gridView.delegate gridView:self.gridView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndex:cellIndex];
    }
}

#pragma mark - presentation

- (void)configureForShow:(MLShow *)show
{
    self.titleLabel.text = show.name;
    self.artistNameLabel.text = @"";
    self.albumNameLabel.text = show.releaseYear;
    NSUInteger count = show.episodes.count;
    self.subtitleLabel.text = [NSString stringWithFormat:(count > 1) ? NSLocalizedString(@"LIBRARY_EPISODES", @"") : NSLocalizedString(@"LIBRARY_SINGLE_EPISODE", @""), count, show.unreadEpisodes.count];
    self.mediaIsUnreadView.hidden = YES;
    self.progressView.hidden = YES;
}

- (void)configureForAlbumTrack:(MLAlbumTrack *)albumTrack
{
    self.artistNameLabel.text = albumTrack.artist;
    self.albumNameLabel.text = [NSString stringWithFormat:NSLocalizedString(@"LIBRARY_SINGLE_TRACK", @""), albumTrack.trackNumber.intValue];
    self.titleLabel.text = albumTrack.title;
    self.thumbnailView.image = nil;

    MLFile *anyFileFromTrack = albumTrack.files.anyObject;
    self.subtitleLabel.text = [NSString stringWithFormat:@"%@", [VLCTime timeWithNumber:[anyFileFromTrack duration]]];

    CGFloat position = anyFileFromTrack.lastPosition.floatValue;
    self.progressView.progress = position;
    self.progressView.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
    [self.progressView setNeedsDisplay];
    self.mediaIsUnreadView.hidden = !anyFileFromTrack.unread.intValue;
}

- (void)configureForAlbum:(MLAlbum *)album
{
    self.titleLabel.text = album.name;
    MLAlbumTrack *anyTrack = [album.tracks anyObject];
    self.artistNameLabel.text = anyTrack? anyTrack.artist: @"";
    self.albumNameLabel.text = album.releaseYear;
    self.thumbnailView.image = nil;

    NSUInteger count = album.tracks.count;
    self.subtitleLabel.text = [NSString stringWithFormat:(count > 1) ? NSLocalizedString(@"LIBRARY_TRACKS", @"") : NSLocalizedString(@"LIBRARY_SINGLE_TRACK", @""), count];
    self.mediaIsUnreadView.hidden = YES;
    self.progressView.hidden = YES;
}

- (void)configureForShowEpisode:(MLShowEpisode *)showEpisode
{
    MLFile *anyFileFromEpisode = showEpisode.files.anyObject;
    self.titleLabel.text = showEpisode.name;
    if (self.titleLabel.text.length < 1) {
        self.titleLabel.text = [NSString stringWithFormat:@"S%02dE%02d", showEpisode.seasonNumber.intValue, showEpisode.episodeNumber.intValue];
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@", [VLCTime timeWithNumber:[anyFileFromEpisode duration]]];
    } else
        self.subtitleLabel.text = [NSString stringWithFormat:@"S%02dE%02d — %@", showEpisode.seasonNumber.intValue, showEpisode.episodeNumber.intValue, [VLCTime timeWithNumber:[anyFileFromEpisode duration]]];

    CGFloat position = anyFileFromEpisode.lastPosition.floatValue;
    self.progressView.progress = position;
    self.progressView.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
    [self.progressView setNeedsDisplay];
    self.mediaIsUnreadView.hidden = !showEpisode.unread.intValue;
}

- (void)configureForMLFile:(MLFile *)mediaFile
{
    if ([mediaFile isAlbumTrack]) {
        self.artistNameLabel.text = mediaFile.albumTrack.artist;
        self.albumNameLabel.text = mediaFile.albumTrack.album.name;
        self.titleLabel.text = (mediaFile.albumTrack.title.length > 0) ? mediaFile.albumTrack.title : mediaFile.title;
        self.thumbnailView.image = nil;
    } else if ([mediaFile isShowEpisode]) {
        MLShowEpisode *episode = mediaFile.showEpisode;
        self.seriesNameLabel.text = episode.show.name;
        self.titleLabel.text = (episode.name.length > 0) ? [NSString stringWithFormat:@"%@ - S%02dE%02d", episode.name, mediaFile.showEpisode.seasonNumber.intValue, episode.episodeNumber.intValue] : [NSString stringWithFormat:@"S%02dE%02d", episode.seasonNumber.intValue, episode.episodeNumber.intValue];
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
    self.progressView.progress = position;
    self.progressView.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
    [self.progressView setNeedsDisplay];
    self.mediaIsUnreadView.hidden = !mediaFile.unread.intValue;
}

@end
