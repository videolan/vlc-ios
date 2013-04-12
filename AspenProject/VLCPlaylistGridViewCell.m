//
//  VLCGridViewCell.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 11.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCPlaylistGridViewCell.h"

@interface VLCPlaylistGridViewCell (Hack)
@property (nonatomic, retain) NSString * reuseIdentifier;
@end

@implementation VLCPlaylistGridViewCell

- (void)dealloc
{
    [_thumbnailView release];
    [_titleLabel release];
    [_subtitleLabel release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier];
    if (self == nil)
        return nil;

    _thumbnailView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.highlightedTextColor = [UIColor whiteColor];
    _titleLabel.textColor = [UIColor colorWithWhite:.95 alpha:1.];
    _titleLabel.font = [UIFont boldSystemFontOfSize:12.];
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.minimumFontSize = 10.;

    _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _subtitleLabel.highlightedTextColor = [UIColor whiteColor];
    _subtitleLabel.textColor = [UIColor colorWithWhite:.95 alpha:1.];
    _subtitleLabel.font = [UIFont systemFontOfSize:9.];
    _subtitleLabel.adjustsFontSizeToFitWidth = YES;
    _subtitleLabel.minimumFontSize = 8.;

    self.backgroundColor = [UIColor colorWithWhite:.5 alpha:1.];
    self.contentView.backgroundColor = self.backgroundColor;
    _thumbnailView.backgroundColor = self.backgroundColor;
    _titleLabel.backgroundColor = self.backgroundColor;
    _subtitleLabel.backgroundColor = self.backgroundColor;

    [self.contentView addSubview:_thumbnailView];
    [self.contentView addSubview:_titleLabel];
    [self.contentView addSubview:_subtitleLabel];

    return self;
}

- (UIImage *)thumbnail
{
    return _thumbnailView.image;
}

- (void)setThumbnail:(UIImage *)newThumb
{
    _thumbnailView.image = newThumb;
    [self setNeedsLayout];
}

- (NSString *)title
{
    return _titleLabel.text;
}

- (void)setTitle:(NSString *)newTitle
{
    _titleLabel.text = newTitle;
    [self setNeedsLayout];
}

- (NSString *)subtitle
{
    return @"";
}

- (void)setSubtitle:(NSString *)newSubtitle
{
    _subtitleLabel.text = newSubtitle;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGSize imageSize = _thumbnailView.image.size;
    CGRect bounds = CGRectInset(self.contentView.bounds, 10., 10.);

    [_titleLabel sizeToFit];
    CGRect frame = _titleLabel.frame;
    frame.size.width = MIN(frame.size.width, bounds.size.width);
    frame.origin.y = CGRectGetMaxY(bounds) - frame.size.height - 15.;
    frame.origin.x = floorf((bounds.size.width - frame.size.width) * 0.5);
    _titleLabel.frame = frame;

    [_subtitleLabel sizeToFit];
    frame = _subtitleLabel.frame;
    frame.size.width = MIN(frame.size.width, bounds.size.width);
    frame.origin.y = CGRectGetMaxY(bounds) - frame.size.height;
    frame.origin.x = floorf((bounds.size.width - frame.size.width) * 0.5);
    _subtitleLabel.frame = frame;

    bounds.size.height = frame.origin.y - bounds.origin.y;

    if ((imageSize.width <= bounds.size.width) && (imageSize.height <= bounds.size.height))
        return;

    CGFloat hRatio = bounds.size.width / imageSize.width;
    CGFloat vRatio = bounds.size.height / imageSize.height;
    CGFloat ratio = MIN(hRatio, vRatio);

    [_thumbnailView sizeToFit];
    frame = _thumbnailView.frame;
    frame.size.width = floorf(imageSize.width * ratio);
    frame.size.height = floorf(imageSize.height * ratio);
    frame.origin.x = floorf((bounds.size.width - frame.size.width) * 0.5);
    frame.origin.y = floorf((bounds.size.height - frame.size.height) * 0.5);
    _thumbnailView.frame = frame;
}

@end
