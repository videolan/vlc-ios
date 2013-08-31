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
#import "VLCAppDelegate.h"
#import "AQGridView.h"

#define MAX_CACHE_SIZE 27 // three times the number of items shown on iPad

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

    [self _updatedDisplayedInformationForKeyPath:NULL];
}

- (void)_updatedDisplayedInformationForKeyPath:(NSString *)keyPath
{
    static NSMutableArray *_thumbnailCacheIndex;
    static NSMutableDictionary *_thumbnailCache;
    if (!_thumbnailCache)
        _thumbnailCache = [[NSMutableDictionary alloc] initWithCapacity:MAX_CACHE_SIZE];
    if (!_thumbnailCacheIndex)
        _thumbnailCacheIndex = [[NSMutableArray alloc] initWithCapacity:MAX_CACHE_SIZE];

    self.albumNameLabel.text = self.artistNameLabel.text = self.seriesNameLabel.text = @"";

    if ([self.mediaObject isKindOfClass:[MLFile class]]) {
        MLFile *mediaObject = self.mediaObject;
        if ([mediaObject isAlbumTrack]) {
            self.artistNameLabel.text = mediaObject.albumTrack.artist;
            self.albumNameLabel.text = mediaObject.albumTrack.album.name;
            self.titleLabel.text = (mediaObject.albumTrack.title.length > 0) ? mediaObject.albumTrack.title : mediaObject.title;
            self.thumbnailView.image = nil;
        } else if ([mediaObject isShowEpisode]) {
            MLShowEpisode *episode = mediaObject.showEpisode;
            self.seriesNameLabel.text = episode.show.name;
            self.titleLabel.text = (episode.name.length > 0) ? [NSString stringWithFormat:@"%@ - S%02dE%02d", episode.name, mediaObject.showEpisode.seasonNumber.intValue, episode.episodeNumber.intValue] : [NSString stringWithFormat:@"S%02dE%02d", episode.seasonNumber.intValue, episode.episodeNumber.intValue];
        } else
            self.titleLabel.text = mediaObject.title;

        if (self.isEditing)
            self.subtitleLabel.text = [NSString stringWithFormat:@"%@ — %i MB", [VLCTime timeWithNumber:[mediaObject duration]], (int)([mediaObject fileSizeInBytes] / 1e6)];
        else {
            self.subtitleLabel.text = [NSString stringWithFormat:@"%@", [VLCTime timeWithNumber:[mediaObject duration]]];
            if (mediaObject.videoTrack) {
                NSString *width = [[mediaObject videoTrack] valueForKey:@"width"];
                NSString *height = [[mediaObject videoTrack] valueForKey:@"height"];
                if (width.intValue > 0 && height.intValue > 0)
                    self.subtitleLabel.text = [self.subtitleLabel.text stringByAppendingFormat:@" — %@x%@", width, height];
            }
        }
        if (([keyPath isEqualToString:@"computedThumbnail"] || !keyPath) && !mediaObject.isAlbumTrack) {
            NSManagedObjectID *objID = mediaObject.objectID;
            UIImage *displayedImage;
            if ([_thumbnailCacheIndex containsObject:objID]) {
                [_thumbnailCacheIndex removeObject:objID];
                [_thumbnailCacheIndex insertObject:objID atIndex:0];
                displayedImage = [_thumbnailCache objectForKey:objID];
                if (!displayedImage) {
                    displayedImage = mediaObject.computedThumbnail;
                    if (displayedImage)
                        [_thumbnailCache setObject:displayedImage forKey:objID];
                }
            } else {
                if (_thumbnailCacheIndex.count >= MAX_CACHE_SIZE) {
                    [_thumbnailCache removeObjectForKey:[_thumbnailCacheIndex lastObject]];
                    [_thumbnailCacheIndex removeLastObject];
                }
                displayedImage = mediaObject.computedThumbnail;
                if (displayedImage)
                    [_thumbnailCache setObject:displayedImage forKey:objID];
                if (objID)
                    [_thumbnailCacheIndex insertObject:objID atIndex:0];
            }
            self.thumbnailView.image = displayedImage;
        }
        CGFloat position = mediaObject.lastPosition.floatValue;
        self.progressView.progress = position;
        self.progressView.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
        [self.progressView setNeedsDisplay];
        self.mediaIsUnreadView.hidden = !mediaObject.unread.intValue;
    } else if ([self.mediaObject isKindOfClass:[MLAlbum class]]) {
        MLAlbum *mediaObject = (MLAlbum *)self.mediaObject;
        self.titleLabel.text = mediaObject.name;
        MLAlbumTrack *anyTrack = [mediaObject.tracks anyObject];
        if (anyTrack)
            self.artistNameLabel.text = anyTrack.artist;
        else
            self.artistNameLabel.text = @"";
        self.albumNameLabel.text = mediaObject.releaseYear;
        self.thumbnailView.image = nil;
        NSUInteger count = mediaObject.tracks.count;
        self.subtitleLabel.text = [NSString stringWithFormat:(count > 1) ? NSLocalizedString(@"LIBRARY_TRACKS", @"") : NSLocalizedString(@"LIBRARY_SINGLE_TRACK", @""), count];
        self.mediaIsUnreadView.hidden = YES;
        self.progressView.hidden = YES;
    } else if ([self.mediaObject isKindOfClass:[MLAlbumTrack class]]) {
        MLAlbumTrack *mediaObject = (MLAlbumTrack *)self.mediaObject;
        self.artistNameLabel.text = mediaObject.artist;
        self.albumNameLabel.text = [NSString stringWithFormat:NSLocalizedString(@"LIBRARY_SINGLE_TRACK", @""), mediaObject.trackNumber.intValue];
        self.titleLabel.text = mediaObject.title;
        self.thumbnailView.image = nil;

        MLFile *anyFileFromTrack = mediaObject.files.anyObject;
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@", [VLCTime timeWithNumber:[anyFileFromTrack duration]]];

        CGFloat position = anyFileFromTrack.lastPosition.floatValue;
        self.progressView.progress = position;
        self.progressView.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
        [self.progressView setNeedsDisplay];
        self.mediaIsUnreadView.hidden = !anyFileFromTrack.unread.intValue;
    } else if ([self.mediaObject isKindOfClass:[MLShow class]]) {
        MLShow *mediaObject = (MLShow *)self.mediaObject;
        self.titleLabel.text = mediaObject.name;
        self.artistNameLabel.text = @"";
        self.albumNameLabel.text = mediaObject.releaseYear;
        NSUInteger count = mediaObject.episodes.count;
        self.subtitleLabel.text = [NSString stringWithFormat:(count > 1) ? NSLocalizedString(@"LIBRARY_EPISODES", @"") : NSLocalizedString(@"LIBRARY_SINGLE_EPISODE", @""), count, mediaObject.unreadEpisodes.count];
        self.mediaIsUnreadView.hidden = YES;
        self.progressView.hidden = YES;

        MLFile *anyFileFromAnyEpisode = [mediaObject.episodes.anyObject files].anyObject;
        if ([keyPath isEqualToString:@"computedThumbnail"] || !keyPath) {
            NSManagedObjectID *objID = anyFileFromAnyEpisode.objectID;
            UIImage *displayedImage;
            if ([_thumbnailCacheIndex containsObject:objID]) {
                [_thumbnailCacheIndex removeObject:objID];
                [_thumbnailCacheIndex insertObject:objID atIndex:0];
                displayedImage = [_thumbnailCache objectForKey:objID];
                if (!displayedImage) {
                    displayedImage = anyFileFromAnyEpisode.computedThumbnail;
                    if (displayedImage)
                        [_thumbnailCache setObject:displayedImage forKey:objID];
                }
            } else {
                if (_thumbnailCacheIndex.count >= MAX_CACHE_SIZE) {
                    [_thumbnailCache removeObjectForKey:[_thumbnailCacheIndex lastObject]];
                    [_thumbnailCacheIndex removeLastObject];
                }
                displayedImage = anyFileFromAnyEpisode.computedThumbnail;
                if (displayedImage)
                    [_thumbnailCache setObject:displayedImage forKey:objID];
                if (objID)
                    [_thumbnailCacheIndex insertObject:objID atIndex:0];
            }
            self.thumbnailView.image = displayedImage;
        }
    } else if ([self.mediaObject isKindOfClass:[MLShowEpisode class]]) {
        MLShowEpisode *mediaObject = (MLShowEpisode *)self.mediaObject;
        self.titleLabel.text = mediaObject.name;

        MLFile *anyFileFromEpisode = mediaObject.files.anyObject;

        if ([keyPath isEqualToString:@"computedThumbnail"] || !keyPath) {
            NSManagedObjectID *objID = anyFileFromEpisode.objectID;
            UIImage *displayedImage;
            if ([_thumbnailCacheIndex containsObject:objID]) {
                [_thumbnailCacheIndex removeObject:objID];
                [_thumbnailCacheIndex insertObject:objID atIndex:0];
                displayedImage = [_thumbnailCache objectForKey:objID];
                if (!displayedImage) {
                    displayedImage = anyFileFromEpisode.computedThumbnail;
                    if (displayedImage)
                        [_thumbnailCache setObject:displayedImage forKey:objID];
                }
            } else {
                if (_thumbnailCacheIndex.count >= MAX_CACHE_SIZE) {
                    [_thumbnailCache removeObjectForKey:[_thumbnailCacheIndex lastObject]];
                    [_thumbnailCacheIndex removeLastObject];
                }
                displayedImage = anyFileFromEpisode.computedThumbnail;
                if (displayedImage)
                    [_thumbnailCache setObject:displayedImage forKey:objID];
                if (objID)
                    [_thumbnailCacheIndex insertObject:objID atIndex:0];
            }
            self.thumbnailView.image = displayedImage;
        }
        if (self.titleLabel.text.length < 1) {
            self.titleLabel.text = [NSString stringWithFormat:@"S%02dE%02d", mediaObject.episodeNumber.intValue, mediaObject.seasonNumber.intValue];
            self.subtitleLabel.text = [NSString stringWithFormat:@"%@", [VLCTime timeWithNumber:[anyFileFromEpisode duration]]];
        } else
            self.subtitleLabel.text = [NSString stringWithFormat:@"S%02dE%02d — %@", mediaObject.episodeNumber.intValue, mediaObject.seasonNumber.intValue, [VLCTime timeWithNumber:[anyFileFromEpisode duration]]];

        CGFloat position = anyFileFromEpisode.lastPosition.floatValue;
        self.progressView.progress = position;
        self.progressView.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
        [self.progressView setNeedsDisplay];
        self.mediaIsUnreadView.hidden = !mediaObject.unread.intValue;
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

@end
