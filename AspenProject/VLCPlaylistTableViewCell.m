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
#import <MediaLibraryKit/MLAlbum.h>

#define MAX_CACHE_SIZE 21 // three times the number of items shown on iPhone 5

@implementation VLCPlaylistTableViewCell

+ (VLCPlaylistTableViewCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCPlaylistTableViewCell" owner:nil options:nil];
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

    [self _updatedDisplayedInformationForKeyPath:NULL];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self _updatedDisplayedInformationForKeyPath:@"editing"];
}

- (void)_updatedDisplayedInformationForKeyPath:(NSString *)keyPath
{
    static NSMutableArray *_thumbnailCacheIndex;
    static NSMutableDictionary *_thumbnailCache;
    if (!_thumbnailCache)
        _thumbnailCache = [[NSMutableDictionary alloc] initWithCapacity:MAX_CACHE_SIZE];
    if (!_thumbnailCacheIndex)
        _thumbnailCacheIndex = [[NSMutableArray alloc] initWithCapacity:MAX_CACHE_SIZE];

    self.albumNameLabel.text = self.artistNameLabel.text = @"";

    if ([self.mediaObject isKindOfClass:[MLFile class]]) {
        MLFile *mediaObject = (MLFile*)self.mediaObject;

        if (mediaObject.isAlbumTrack) {
            self.artistNameLabel.text = mediaObject.albumTrack.artist;
            self.albumNameLabel.text = mediaObject.albumTrack.album.name;
            self.titleLabel.text = (mediaObject.albumTrack.title.length > 1) ? mediaObject.albumTrack.title : mediaObject.title;
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
        if ([keyPath isEqualToString:@"computedThumbnail"] || !keyPath) {
            NSManagedObjectID *objID = mediaObject.objectID;
            UIImage *displayedImage;
            if ([_thumbnailCacheIndex containsObject:objID]) {
                [_thumbnailCacheIndex removeObject:objID];
                [_thumbnailCacheIndex insertObject:objID atIndex:0];
                displayedImage = [_thumbnailCache objectForKey:objID];
            } else {
                if (_thumbnailCacheIndex.count >= MAX_CACHE_SIZE) {
                    [_thumbnailCache removeObjectForKey:[_thumbnailCacheIndex lastObject]];
                    [_thumbnailCacheIndex removeLastObject];
                }
                displayedImage = mediaObject.computedThumbnail;
                if (displayedImage)
                    [_thumbnailCache setObject:displayedImage forKey:objID];
                [_thumbnailCacheIndex insertObject:objID atIndex:0];
            }
            self.thumbnailView.image = displayedImage;
        }
        CGFloat position = mediaObject.lastPosition.floatValue;
        self.progressIndicator.progress = position;
        self.progressIndicator.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
        [self.progressIndicator setNeedsDisplay];
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
        self.subtitleLabel.text = [NSString stringWithFormat:(count > 1) ? @"%i Tracks" : @"%i Track", count];
        self.mediaIsUnreadView.hidden = YES;
        self.progressIndicator.hidden = YES;
    } else if ([self.mediaObject isKindOfClass:[MLAlbumTrack class]]) {
        MLAlbumTrack *mediaObject = (MLAlbumTrack *)self.mediaObject;
        self.artistNameLabel.text = mediaObject.artist;
        self.albumNameLabel.text = [NSString stringWithFormat:@"Track %i", mediaObject.trackNumber.intValue];
        self.titleLabel.text = mediaObject.title;
        self.thumbnailView.image = nil;

        MLFile *anyFileFromTrack = mediaObject.files.anyObject;
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@", [VLCTime timeWithNumber:[anyFileFromTrack duration]]];

        CGFloat position = anyFileFromTrack.lastPosition.floatValue;
        self.progressIndicator.progress = position;
        self.progressIndicator.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
        [self.progressIndicator setNeedsDisplay];
        self.mediaIsUnreadView.hidden = !anyFileFromTrack.unread.intValue;
    } else if ([self.mediaObject isKindOfClass:[MLShow class]]) {
        MLShow *mediaObject = (MLShow *)self.mediaObject;
        self.titleLabel.text = mediaObject.name;
        self.artistNameLabel.text = @"";
        self.albumNameLabel.text = mediaObject.releaseYear;
        self.thumbnailView.image = nil;
        NSUInteger count = mediaObject.episodes.count;
        self.subtitleLabel.text = [NSString stringWithFormat:(count > 1) ? @"%i Tracks, %i unread" : @"%i Track, %i unread", count, mediaObject.unreadEpisodes.count];
        self.mediaIsUnreadView.hidden = YES;
        self.progressIndicator.hidden = YES;
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
            } else {
                if (_thumbnailCacheIndex.count >= MAX_CACHE_SIZE) {
                    [_thumbnailCache removeObjectForKey:[_thumbnailCacheIndex lastObject]];
                    [_thumbnailCacheIndex removeLastObject];
                }
                displayedImage = anyFileFromEpisode.computedThumbnail;
                if (displayedImage)
                    [_thumbnailCache setObject:displayedImage forKey:objID];
                [_thumbnailCacheIndex insertObject:objID atIndex:0];
            }
            self.thumbnailView.image = displayedImage;
        }
        self.subtitleLabel.text = [NSString stringWithFormat:@"%i/%i — %@", mediaObject.episodeNumber.intValue, mediaObject.seasonNumber.intValue, [VLCTime timeWithNumber:[anyFileFromEpisode duration]]];

        CGFloat position = anyFileFromEpisode.lastPosition.floatValue;
        self.progressIndicator.progress = position;
        self.progressIndicator.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
        [self.progressIndicator setNeedsDisplay];
        self.mediaIsUnreadView.hidden = !mediaObject.unread.intValue;
    }

    [self setNeedsDisplay];
}

+ (CGFloat)heightOfCell
{
    return 80.;
}

@end
