//
//  VLCGridViewCell.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 11.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCPlaylistGridView.h"

@interface VLCPlaylistGridView (Hack)
@property (nonatomic, retain) NSString * reuseIdentifier;
@end

@implementation VLCPlaylistGridView

- (UIImage *)thumbnail
{
    return _thumbnailView.image;
}

- (void)setThumbnail:(UIImage *)newThumb
{
    self.thumbnailView.image = newThumb;
    [self setNeedsDisplay];
}

- (NSString *)title
{
    return _titleLabel.text;
}

- (void)setTitle:(NSString *)newTitle
{
    self.titleLabel.text = newTitle;
    [self setNeedsDisplay];
}

- (NSString *)subtitle
{
    return @"";
}

- (void)setSubtitle:(NSString *)newSubtitle
{
    self.subtitleLabel.text = newSubtitle;
    [self setNeedsDisplay];
}

@end
