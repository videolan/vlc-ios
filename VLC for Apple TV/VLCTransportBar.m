/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCTransportBar.h"
#import "VLCBufferingBar.h"

@interface VLCTransportBar ()
@property (nonatomic) VLCBufferingBar *bufferingBar;
@property (nonatomic) UIView *playbackPositionMarker;
@property (nonatomic) UIView *scrubbingPostionMarker;
@end

@implementation VLCTransportBar

static const CGFloat VLCTransportBarMarkerWidth = 2.0;

static inline void sharedSetup(VLCTransportBar *self) {
    CGRect bounds = self.bounds;

    // Bar:
    VLCBufferingBar *bar = [[VLCBufferingBar alloc] initWithFrame:bounds];
    UIColor *barColor =  [UIColor lightGrayColor];
    bar.bufferColor = barColor;
    bar.borderColor = barColor;
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bar.bufferStartFraction = self.bufferStartFraction;
    bar.bufferEndFraction = self.bufferEndFraction;
    self.bufferingBar = bar;
    [self addSubview:bar];

    // Marker:
    UIColor *markerColor = [UIColor whiteColor];
    UIView *playbackMarker = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VLCTransportBarMarkerWidth, CGRectGetHeight(bounds))];
    playbackMarker.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    playbackMarker.backgroundColor = markerColor;
    [self addSubview:playbackMarker];
    self.playbackPositionMarker = playbackMarker;

    UIView *scrubbingMarker = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VLCTransportBarMarkerWidth, CGRectGetHeight(bounds))];
    [self addSubview:scrubbingMarker];
    scrubbingMarker.backgroundColor = markerColor;
    self.scrubbingPostionMarker = scrubbingMarker;

    // Labels:
    CGFloat size = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout].pointSize;
    UIFont *font = [UIFont monospacedDigitSystemFontOfSize:size weight:UIFontWeightSemibold];
    UIColor *textColor = [UIColor whiteColor];

    UILabel *markerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    markerLabel.font = font;
    markerLabel.textColor = textColor;
    [self addSubview:markerLabel];
    self->_markerTimeLabel = markerLabel;

    UILabel *remainingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    remainingLabel.font = font;
    remainingLabel.textColor = textColor;
    [self addSubview:remainingLabel];
    self->_remainingTimeLabel = remainingLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        sharedSetup(self);
    }
    return self;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    sharedSetup(self);
}

- (void)setBufferStartFraction:(CGFloat)bufferStartFraction {
    _bufferStartFraction = bufferStartFraction;
    self.bufferingBar.bufferStartFraction = bufferStartFraction;
}
- (void)setBufferEndFraction:(CGFloat)bufferEndFraction {
    _bufferEndFraction = bufferEndFraction;
    self.bufferingBar.bufferEndFraction = bufferEndFraction;
}
- (void)setPlaybackFraction:(CGFloat)playbackFraction {
    _playbackFraction = playbackFraction;
    if (!self.scrubbing) {
        [self setScrubbingFraction:playbackFraction];
    }
    [self setNeedsLayout];
}
- (void)setScrubbingFraction:(CGFloat)scrubbingFraction {
    _scrubbingFraction = scrubbingFraction;
    [self setNeedsLayout];
}
- (void)setScrubbing:(BOOL)scrubbing {
    _scrubbing = scrubbing;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    const CGRect bounds = self.bounds;
    const CGFloat width = CGRectGetWidth(bounds)-VLCTransportBarMarkerWidth;

    self.playbackPositionMarker.center = CGPointMake(width*self.playbackFraction+VLCTransportBarMarkerWidth/2.0,
                                                     CGRectGetMidY(bounds));


    const BOOL withThumbnail = NO;
    const CGRect scrubberFrame = scrubbingMarkerFrameForBounds_fraction_withThumb(bounds,
                                                                                  self.scrubbingFraction,
                                                                                  withThumbnail);
    self.scrubbingPostionMarker.frame = scrubberFrame;


    UILabel *remainingLabel = self.remainingTimeLabel;
    [remainingLabel sizeToFit];
    CGRect remainingLabelFrame = remainingLabel.frame;
    remainingLabelFrame.origin.y = CGRectGetMaxY(bounds)+15.0;
    remainingLabelFrame.origin.x = width-CGRectGetWidth(remainingLabelFrame);
    remainingLabel.frame = remainingLabelFrame;

    UILabel *markerLabel = self.markerTimeLabel;
    [markerLabel sizeToFit];

    CGPoint timeLabelCenter = remainingLabel.center;
    timeLabelCenter.x = self.scrubbingPostionMarker.center.x;
    markerLabel.center = timeLabelCenter;

    CGFloat remainingAlfa = CGRectIntersectsRect(markerLabel.frame, remainingLabelFrame) ? 0.0 : 1.0;
    remainingLabel.alpha = remainingAlfa;
}


static CGRect scrubbingMarkerFrameForBounds_fraction_withThumb(CGRect bounds, CGFloat fraction, BOOL withThumbnail) {
    const CGFloat width = CGRectGetWidth(bounds)-VLCTransportBarMarkerWidth;
    const CGFloat height = CGRectGetHeight(bounds);

    // when scrubbing marker is 4x instead of 3x bar heigt
    const CGFloat scrubbingHeight = height * (withThumbnail ? 4.0 : 3.0);

    // x position is always center of marker == view width * fraction
    const CGFloat scrubbingXPosition = width*fraction;
    CGFloat scrubbingYPosition = 0;
    if (withThumbnail) {
        // scrubbing marker bottom and bar buttom are same
        scrubbingYPosition = height-scrubbingHeight;
    } else {
        // scrubbing marker y center == bar y center
        scrubbingYPosition = height/2.0 - scrubbingHeight/2.0;
    }
    return CGRectMake(scrubbingXPosition,
                      scrubbingYPosition,
                      VLCTransportBarMarkerWidth,
                      scrubbingHeight);
}

@end