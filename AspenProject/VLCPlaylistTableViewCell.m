//
//  VLCPlaylistTableViewCell.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 01.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCPlaylistTableViewCell.h"

@implementation VLCPlaylistTableViewCell

+ (VLCPlaylistTableViewCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCPlaylistTableViewCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCPlaylistTableViewCell class]], @"meh meh");
    VLCPlaylistTableViewCell *cell = (VLCPlaylistTableViewCell *)[nibContentArray lastObject];
    CGRect frame = [cell frame];
    UIView *background = [[UIView alloc] initWithFrame:frame];
    background.backgroundColor = [UIColor colorWithWhite:.05 alpha:1.];
    cell.backgroundView = background;
    UIView *highlightedBackground = [[UIView alloc] initWithFrame:frame];
    highlightedBackground.backgroundColor = [UIColor colorWithWhite:.2 alpha:1.];
    cell.selectedBackgroundView = highlightedBackground;

    return cell;
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

    [self _updatedDisplayedInformation];
}

- (void)_updatedDisplayedInformation
{
    self.titleLabel.text = self.mediaObject.title;
    self.subtitleLabel.text = [NSString stringWithFormat:@"%@ — %.2f MB", [VLCTime timeWithNumber:[self.mediaObject duration]], [self.mediaObject fileSizeInBytes] / 2e6];
    self.thumbnailView.image = self.mediaObject.computedThumbnail;
    self.progressIndicator.progress = self.mediaObject.lastPosition.floatValue;

    if (self.progressIndicator.progress < 0.1f)
        self.progressIndicator.hidden = YES;

    [self setNeedsDisplay];
}

+ (CGFloat)heightOfCell
{
    return 80.;
}

@end
