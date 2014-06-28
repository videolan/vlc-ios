/*****************************************************************************
 * VLCPlaylistTableViewCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Carola Nitz <nitz.carola #googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaylistTableViewCell.h"
#import "VLCLinearProgressIndicator.h"
#import "VLCThumbnailsCache.h"
#import <MediaLibraryKit/MLAlbum.h>

@interface VLCPlaylistTableViewCell ()
{
    UILongPressGestureRecognizer *_longPress;
}

@end

@implementation VLCPlaylistTableViewCell

- (void)dealloc
{
    [self _removeObserver];
}

+ (VLCPlaylistTableViewCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray;
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCFuturePlaylistTableViewCell" owner:nil options:nil];
    else
        nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCPlaylistTableViewCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCPlaylistTableViewCell class]], @"meh meh");
    VLCPlaylistTableViewCell *cell = (VLCPlaylistTableViewCell *)[nibContentArray lastObject];
    cell.multipleSelectionBackgroundView = [[UIView alloc] initWithFrame:cell.frame];

    return cell;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self _updatedDisplayedInformationForKeyPath:keyPath];
}

- (void)_removeObserver
{
    if ([_mediaObject isKindOfClass:[MLLabel class]]) {
        [_mediaObject removeObserver:self forKeyPath:@"files"];
        [_mediaObject removeObserver:self forKeyPath:@"name"];
    } else if ([_mediaObject isKindOfClass:[MLShow class]])
        [_mediaObject removeObserver:self forKeyPath:@"episodes"];
    else if ([_mediaObject isKindOfClass:[MLShowEpisode class]]) {
        [_mediaObject removeObserver:self forKeyPath:@"name"];
        [_mediaObject removeObserver:self forKeyPath:@"files"];
        [_mediaObject removeObserver:self forKeyPath:@"artworkURL"];
        [_mediaObject removeObserver:self forKeyPath:@"unread"];
    } else if ([_mediaObject isKindOfClass:[MLAlbum class]]) {
        [_mediaObject removeObserver:self forKeyPath:@"name"];
        [_mediaObject removeObserver:self forKeyPath:@"tracks"];
    } else if ([_mediaObject isKindOfClass:[MLFile class]]) {
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
        [(MLFile*)_mediaObject didHide];
    }
}

- (void)_addObserver
{
    if ([_mediaObject isKindOfClass:[MLLabel class]]) {
        [_mediaObject addObserver:self forKeyPath:@"files" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"name" options:0 context:nil];
    } else if ([_mediaObject isKindOfClass:[MLShow class]])
        [_mediaObject addObserver:self forKeyPath:@"episodes" options:0 context:nil];
    else if ([_mediaObject isKindOfClass:[MLShowEpisode class]]) {
        [_mediaObject addObserver:self forKeyPath:@"name" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"files" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"artworkURL" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"unread" options:0 context:nil];
    } else if ([_mediaObject isKindOfClass:[MLAlbum class]]) {
        [_mediaObject addObserver:self forKeyPath:@"name" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"tracks" options:0 context:nil];
    } else if ([_mediaObject isKindOfClass:[MLFile class]]) {
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
        [(MLFile*)_mediaObject willDisplay];
    }
}

- (void)setMediaObject:(MLFile *)mediaObject
{
    if (_mediaObject != mediaObject) {
        [self _removeObserver];

        _mediaObject = mediaObject;
        // prevent the cell from recycling the current snap for random contents
        self.thumbnailView.image = nil;

        [self _addObserver];
    }

    [self _updatedDisplayedInformationForKeyPath:nil];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self _updatedDisplayedInformationForKeyPath:@"editing"];

    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        if (editing) {
            if (_longPress)
                [self removeGestureRecognizer:_longPress];
        } else {
            if (!_longPress)
                _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTouchGestureAction:)];
            [self addGestureRecognizer:_longPress];
        }
    }
}

- (void)_updatedDisplayedInformationForKeyPath:(NSString *)keyPath
{
    self.thumbnailView.contentMode = UIViewContentModeScaleAspectFill;

    if ([self.mediaObject isKindOfClass:[MLFile class]]) {
        MLFile *mediaObject = (MLFile*)self.mediaObject;
        [self _configureForMLFile:mediaObject];

        if (([keyPath isEqualToString:@"computedThumbnail"] || !keyPath || (!self.thumbnailView.image && [keyPath isEqualToString:@"editing"])))
            self.thumbnailView.image = [VLCThumbnailsCache thumbnailForMediaFile:mediaObject];
    } else if ([self.mediaObject isKindOfClass:[MLLabel class]]) {
        MLLabel *mediaObject = (MLLabel *)self.mediaObject;
        [self _configureForFolder:mediaObject];

        if ([keyPath isEqualToString:@"files"] || !keyPath || (!self.thumbnailView.image && [keyPath isEqualToString:@"editing"])) {
            if (mediaObject.files.count != 0)
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

        if ([keyPath isEqualToString:@"computedThumbnail"] || !keyPath || !self.thumbnailView.image) {
            MLFile *anyFileFromTrack = mediaObject.files.anyObject;
            self.thumbnailView.image = [VLCThumbnailsCache thumbnailForMediaFile:anyFileFromTrack];
        }
    } else if ([self.mediaObject isKindOfClass:[MLShow class]]) {
        MLShow *mediaObject = (MLShow *)self.mediaObject;
        [self _configureForShow:mediaObject];

        if ([keyPath isEqualToString:@"computedThumbnail"] || [keyPath isEqualToString:@"episodes"] || !keyPath || !self.thumbnailView.image) {
            self.thumbnailView.image = [VLCThumbnailsCache thumbnailForShow:mediaObject];
        }
    } else if ([self.mediaObject isKindOfClass:[MLShowEpisode class]]) {
        MLShowEpisode *mediaObject = (MLShowEpisode *)self.mediaObject;
        [self _configureForShowEpisode:mediaObject];

        if ([keyPath isEqualToString:@"computedThumbnail"] || !keyPath || !self.thumbnailView.image) {
            MLFile *anyFileFromEpisode = mediaObject.files.anyObject;
            self.thumbnailView.image = [VLCThumbnailsCache thumbnailForMediaFile:anyFileFromEpisode];
        }
    }

    [self setNeedsDisplay];
}

+ (CGFloat)heightOfCell
{
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        return 90.;

    return 80.;
}

#pragma mark - presentation

- (void)_configureForShow:(MLShow *)show
{
    self.titleLabel.text = show.name;
    NSUInteger count = show.episodes.count;
    NSString *string = @"";
    if (show.releaseYear)
        string = [NSString stringWithFormat:@"%@ — ", show.releaseYear];
    self.subtitleLabel.text = [string stringByAppendingString:[NSString stringWithFormat:(count > 1) ? NSLocalizedString(@"LIBRARY_EPISODES", nil) : NSLocalizedString(@"LIBRARY_SINGLE_EPISODE", nil), count, show.unreadEpisodes.count]];
    self.mediaIsUnreadView.hidden = YES;
    self.progressIndicator.hidden = YES;
    self.folderIconView.image = [UIImage imageNamed:@"tvShow"];
    self.folderIconView.hidden = NO;
}

- (void)_configureForAlbumTrack:(MLAlbumTrack *)albumTrack
{
    MLFile *anyFileFromTrack = albumTrack.files.anyObject;
    self.subtitleLabel.text = [NSString stringWithFormat:@"%@ — %@ — %@", albumTrack.artist, [NSString stringWithFormat:NSLocalizedString(@"LIBRARY_TRACK_N", nil), albumTrack.trackNumber.intValue], [VLCTime timeWithNumber:[anyFileFromTrack duration]]];
    self.titleLabel.text = albumTrack.title;
    [self _showPositionOfItem:anyFileFromTrack];
    self.folderIconView.hidden = YES;
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
    self.folderIconView.hidden = YES;
}

- (void)_configureForAlbum:(MLAlbum *)album
{
    self.titleLabel.text = album.name;
    MLAlbumTrack *anyTrack = [album.tracks anyObject];
    NSUInteger count = album.tracks.count;
    NSMutableString *string = [[NSMutableString alloc] init];
    if (anyTrack) {
        if (anyTrack.artist.length > 0) {
            [string appendString:anyTrack.artist];
            [string appendString:@" — "];
        }
    }
    [string appendString:[NSString stringWithFormat:(count > 1) ? NSLocalizedString(@"LIBRARY_TRACKS", nil) : NSLocalizedString(@"LIBRARY_SINGLE_TRACK", nil), count]];
    if (album.releaseYear.length > 0)
        [string appendFormat:@" — %@", album.releaseYear];
    self.subtitleLabel.text = string;
    self.mediaIsUnreadView.hidden = YES;
    self.progressIndicator.hidden = YES;
    self.folderIconView.hidden = YES;
}

- (void)_configureForFolder:(MLLabel *)label
{
    self.titleLabel.text = label.name;
    NSUInteger count = label.files.count;
    self.subtitleLabel.text = [NSString stringWithFormat:(count == 1) ? NSLocalizedString(@"LIBRARY_SINGLE_TRACK", nil) : NSLocalizedString(@"LIBRARY_TRACKS", nil), count];
    self.mediaIsUnreadView.hidden = YES;
    self.progressIndicator.hidden = YES;
    self.folderIconView.image = [UIImage imageNamed:@"folderIcon"];
    self.folderIconView.hidden = NO;
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

    if (self.isEditing)
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
    self.folderIconView.hidden = YES;
}

- (void)_showPositionOfItem:(MLFile *)mediaLibraryFile
{
    CGFloat position = mediaLibraryFile.lastPosition.floatValue;

    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        CGFloat duration = mediaLibraryFile.duration.floatValue;
        if (position > .05f && position < .95f && (duration * position - duration) < -60000) {
            [(UITextView*)self.mediaIsUnreadView setText:[NSString stringWithFormat:NSLocalizedString(@"LIBRARY_MINUTES_LEFT", nil), [[VLCTime timeWithInt:(duration * position - duration)] minuteStringValue]]];
            self.mediaIsUnreadView.hidden = NO;
        } else if (mediaLibraryFile.unread.intValue) {
            [(UILabel *)self.mediaIsUnreadView setText:[NSLocalizedString(@"NEW", nil) capitalizedStringWithLocale:[NSLocale currentLocale]]];
            self.mediaIsUnreadView.hidden = NO;
        } else
            self.mediaIsUnreadView.hidden = YES;
    } else {
        self.progressIndicator.progress = position;
        self.progressIndicator.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
        [self.progressIndicator setNeedsDisplay];
        self.mediaIsUnreadView.hidden = !mediaLibraryFile.unread.intValue;
    }
}

- (void)longTouchGestureAction:(UIGestureRecognizer *)recognizer
{
    CGRect frame = self.frame;
    if (frame.size.height > 90.)
        frame.size.height = 90.;
    else if (recognizer.state == UIGestureRecognizerStateBegan)
        frame.size.height = 180;

    void (^animationBlock)() = ^() {
        self.frame = frame;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        self.frame = frame;
    };

    NSTimeInterval animationDuration = .2;
    [UIView animateWithDuration:animationDuration animations:animationBlock completion:completionBlock];
}

@end
