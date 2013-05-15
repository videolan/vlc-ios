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
    return CGSizeMake(384, 240);
}

- (void)setMediaObject:(MLFile *)mediaObject
{
    [mediaObject willDisplay];

    self.titleLabel.text = mediaObject.title;
    self.subtitleLabel.text = [NSString stringWithFormat:@"%@ — %.2f MB", [VLCTime timeWithNumber:[mediaObject duration]], [mediaObject fileSizeInBytes] / 2e6];
    self.thumbnailView.image = mediaObject.computedThumbnail;
    self.progressView.progress = mediaObject.lastPosition.floatValue;

    _mediaObject = mediaObject;

    [self setNeedsDisplay];
}

- (IBAction)removeMedia:(id)sender
{
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.playlistViewController removeMediaObject:self.mediaObject];
}

@end
