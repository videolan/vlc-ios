//
//  VLCGridViewCell.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 11.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCPlaylistGridView.h"
#import "VLCAppDelegate.h"

@interface VLCPlaylistGridView (Hack)
@property (nonatomic, retain) NSString *reuseIdentifier;
@end

@implementation VLCPlaylistGridView

- (void)awakeFromNib {
    [super awakeFromNib];
    _contentView = self;
    self.backgroundColor = [UIColor blackColor];
    self.reuseIdentifier = @"AQPlaylistCell";
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    self.removeMediaButton.hidden = !editing;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.removeMediaButton.hidden = YES;
}

+ (CGSize)preferredSize
{
    return CGSizeMake(384, 243);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self _updatedDisplayedInformation];
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
        [_mediaObject didHide];

        _mediaObject = mediaObject;

        [_mediaObject addObserver:self forKeyPath:@"computedThumbnail" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"lastPosition" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"duration" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"fileSizeInBytes" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"title" options:0 context:nil];
        [_mediaObject addObserver:self forKeyPath:@"thumbnailTimeouted" options:0 context:nil];
        [_mediaObject willDisplay];
    }

    [self _updatedDisplayedInformation];
}

- (void)_updatedDisplayedInformation
{
    self.titleLabel.text = self.mediaObject.title;
    self.subtitleLabel.text = [NSString stringWithFormat:@"%@ — %.2f MB", [VLCTime timeWithNumber:[self.mediaObject duration]], [self.mediaObject fileSizeInBytes] / 2e6];
    self.thumbnailView.image = self.mediaObject.computedThumbnail;
    self.progressView.progress = self.mediaObject.lastPosition.floatValue;

    if (self.progressView.progress < 0.1f)
        self.progressView.hidden = YES;

    [self setNeedsDisplay];
}

- (IBAction)removeMedia:(id)sender
{
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.playlistViewController removeMediaObject:self.mediaObject];
}

@end
