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
        [_mediaObject didHide];

        _mediaObject = mediaObject;

        [_mediaObject addObserver:self forKeyPath:@"computedThumbnail" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"lastPosition" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"duration" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"fileSizeInBytes" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"title" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"thumbnailTimeouted" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"unread" options:0 context:nil];
        [_mediaObject willDisplay];
    }

    [self _updatedDisplayedInformationForKeyPath:NULL];
}

- (void)_updatedDisplayedInformationForKeyPath:(NSString *)keyPath
{
    MLFile *mediaObject = self.mediaObject;

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
        static NSMutableArray *_thumbnailCacheIndex;
        static NSMutableDictionary *_thumbnailCache;
        if (!_thumbnailCache)
            _thumbnailCache = [[NSMutableDictionary alloc] initWithCapacity:MAX_CACHE_SIZE];
        if (!_thumbnailCacheIndex)
            _thumbnailCacheIndex = [[NSMutableArray alloc] initWithCapacity:MAX_CACHE_SIZE];

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
            if (displayedImage) {
                [_thumbnailCache setObject:displayedImage forKey:objID];
                [_thumbnailCacheIndex insertObject:objID atIndex:0];
            }
        }
        self.thumbnailView.image = displayedImage;
    }
    CGFloat position = mediaObject.lastPosition.floatValue;
    self.progressView.progress = position;
    self.progressView.hidden = ((position < .1f) || (position > .95f)) ? YES : NO;
    [self.progressView setNeedsDisplay];
    self.mediaIsUnreadView.hidden = !mediaObject.unread.intValue;

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
