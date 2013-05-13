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
@property (nonatomic, retain) NSString * reuseIdentifier;
@end

@implementation VLCPlaylistGridView

- (BOOL)editable
{
    return !self.removeMediaButton.hidden;
}

- (void)setEditable:(BOOL)editable
{
    self.removeMediaButton.hidden = !editable;
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
