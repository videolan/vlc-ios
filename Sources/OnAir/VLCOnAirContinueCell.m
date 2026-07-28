/*****************************************************************************
 * VLCOnAirContinueCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOnAirContinueCell.h"
#import "VLCPlaceholderArtwork.h"
#import "VLCNetworkImageView.h"

#import "VLC-Swift.h"

static CGFloat const kVLCOnAirContinuePadding = 12.0;
static CGFloat const kVLCOnAirContinueSideMargin = 20.0;
static CGFloat const kVLCOnAirContinueArtworkSide = 62.0;
static CGFloat const kVLCOnAirContinueArtworkRadius = 12.0;
static CGFloat const kVLCOnAirContinuePlaySide = 44.0;
static CGFloat const kVLCOnAirContinueTrackHeight = 4.0;

@implementation VLCOnAirContinueCell
{
    UIView *_cardView;
    VLCNetworkImageView *_artworkView;
    UILabel *_eyebrowLabel;
    UILabel *_titleLabel;
    UILabel *_metaLabel;
    UIButton *_playButton;
    UIView *_trackView;
    UIView *_trackFillView;
    NSLayoutConstraint *_trackHeightConstraint;
    NSLayoutConstraint *_trackFillWidthConstraint;
    NSLayoutConstraint *_trackArtworkSpacingConstraint;
    NSLayoutConstraint *_trackMetaSpacingConstraint;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCOnAirContinueCell";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView = [[UIView alloc] init];
        self.backgroundView.backgroundColor = [UIColor clearColor];
        if (@available(iOS 14.0, *)) {
            self.backgroundConfiguration = [UIBackgroundConfiguration clearConfiguration];
        }
        [self setupViews];
    }
    return self;
}

- (void)setupViews
{
    _cardView = [[UIView alloc] init];
    _cardView.translatesAutoresizingMaskIntoConstraints = NO;
    [_cardView roundCornersWithRadius:16.0];
    [self.contentView addSubview:_cardView];

    _artworkView = [[VLCNetworkImageView alloc] init];
    _artworkView.translatesAutoresizingMaskIntoConstraints = NO;
    _artworkView.contentMode = UIViewContentModeScaleAspectFill;
    _artworkView.clipsToBounds = YES;
    _artworkView.layer.cornerRadius = kVLCOnAirContinueArtworkRadius;
    [_cardView addSubview:_artworkView];

    _eyebrowLabel = [[UILabel alloc] init];
    _eyebrowLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _eyebrowLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
    _eyebrowLabel.text = [NSLocalizedString(@"ONAIR_CONTINUE", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    [_cardView addSubview:_eyebrowLabel];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold];
    _titleLabel.numberOfLines = 1;
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [_cardView addSubview:_titleLabel];

    _metaLabel = [[UILabel alloc] init];
    _metaLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _metaLabel.font = [UIFont systemFontOfSize:14.0];
    _metaLabel.numberOfLines = 1;
    _metaLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [_cardView addSubview:_metaLabel];

    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.translatesAutoresizingMaskIntoConstraints = NO;
    _playButton.layer.cornerRadius = kVLCOnAirContinuePlaySide / 2.0;
    _playButton.accessibilityLabel = NSLocalizedString(@"PLAY_BUTTON", nil);
    if (@available(iOS 13.0, *)) {
        [_playButton setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
    }
    [_playButton addTarget:self action:@selector(playAction) forControlEvents:UIControlEventTouchUpInside];
    [_cardView addSubview:_playButton];

    _trackView = [[UIView alloc] init];
    _trackView.translatesAutoresizingMaskIntoConstraints = NO;
    _trackView.layer.cornerRadius = kVLCOnAirContinueTrackHeight / 2.0;
    _trackView.clipsToBounds = YES;
    [_cardView addSubview:_trackView];

    _trackFillView = [[UIView alloc] init];
    _trackFillView.translatesAutoresizingMaskIntoConstraints = NO;
    [_trackView addSubview:_trackFillView];

    _trackHeightConstraint = [_trackView.heightAnchor constraintEqualToConstant:kVLCOnAirContinueTrackHeight];
    _trackFillWidthConstraint = [_trackFillView.widthAnchor constraintEqualToAnchor:_trackView.widthAnchor multiplier:0.0];
    _trackArtworkSpacingConstraint = [_trackView.topAnchor constraintGreaterThanOrEqualToAnchor:_artworkView.bottomAnchor
                                                                                       constant:kVLCOnAirContinuePadding];
    _trackMetaSpacingConstraint = [_trackView.topAnchor constraintGreaterThanOrEqualToAnchor:_metaLabel.bottomAnchor
                                                                                   constant:kVLCOnAirContinuePadding];

    [NSLayoutConstraint activateConstraints:@[
        [_cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [_cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [_cardView.leadingAnchor constraintEqualToAnchor:self.contentView.safeAreaLayoutGuide.leadingAnchor constant:kVLCOnAirContinueSideMargin],
        [_cardView.trailingAnchor constraintEqualToAnchor:self.contentView.safeAreaLayoutGuide.trailingAnchor constant:-kVLCOnAirContinueSideMargin],

        [_artworkView.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:kVLCOnAirContinuePadding],
        [_artworkView.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:kVLCOnAirContinuePadding],
        [_artworkView.widthAnchor constraintEqualToConstant:kVLCOnAirContinueArtworkSide],
        [_artworkView.heightAnchor constraintEqualToConstant:kVLCOnAirContinueArtworkSide],

        [_playButton.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-kVLCOnAirContinuePadding],
        [_playButton.centerYAnchor constraintEqualToAnchor:_artworkView.centerYAnchor],
        [_playButton.widthAnchor constraintEqualToConstant:kVLCOnAirContinuePlaySide],
        [_playButton.heightAnchor constraintEqualToConstant:kVLCOnAirContinuePlaySide],

        [_eyebrowLabel.leadingAnchor constraintEqualToAnchor:_artworkView.trailingAnchor constant:14.0],
        [_eyebrowLabel.trailingAnchor constraintEqualToAnchor:_playButton.leadingAnchor constant:-12.0],
        [_eyebrowLabel.topAnchor constraintEqualToAnchor:_artworkView.topAnchor constant:2.0],

        [_titleLabel.leadingAnchor constraintEqualToAnchor:_eyebrowLabel.leadingAnchor],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:_eyebrowLabel.trailingAnchor],
        [_titleLabel.topAnchor constraintEqualToAnchor:_eyebrowLabel.bottomAnchor constant:3.0],

        [_metaLabel.leadingAnchor constraintEqualToAnchor:_eyebrowLabel.leadingAnchor],
        [_metaLabel.trailingAnchor constraintEqualToAnchor:_eyebrowLabel.trailingAnchor],
        [_metaLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:1.0],

        [_trackView.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:kVLCOnAirContinuePadding],
        [_trackView.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-kVLCOnAirContinuePadding],
        [_trackView.bottomAnchor constraintEqualToAnchor:_cardView.bottomAnchor constant:-kVLCOnAirContinuePadding],
        _trackArtworkSpacingConstraint,
        _trackMetaSpacingConstraint,
        _trackHeightConstraint,

        [_trackFillView.topAnchor constraintEqualToAnchor:_trackView.topAnchor],
        [_trackFillView.bottomAnchor constraintEqualToAnchor:_trackView.bottomAnchor],
        [_trackFillView.leadingAnchor constraintEqualToAnchor:_trackView.leadingAnchor],
        _trackFillWidthConstraint
    ]];
}

- (void)configureWithName:(NSString *)name
               artworkURL:(NSURL *)artworkURL
                     meta:(NSString *)meta
                 progress:(float)progress
{
    ColorPalette *themeColors = PresentationTheme.current.colors;
    UIColor *accent = themeColors.orangeUI;

    if (@available(iOS 13.0, *)) {
        _cardView.backgroundColor = UIColor.tertiarySystemBackgroundColor;
    } else {
        _cardView.backgroundColor = themeColors.cellBackgroundA;
    }

    _artworkView.image = [VLCPlaceholderArtwork placeholderImageForName:name
                                                                   size:CGSizeMake(kVLCOnAirContinueArtworkSide, kVLCOnAirContinueArtworkSide)
                                                           cornerRadius:kVLCOnAirContinueArtworkRadius
                                                               fontSize:22.0];
    if (artworkURL) {
        [_artworkView setImageWithURL:artworkURL];
    }

    _eyebrowLabel.textColor = accent;

    _titleLabel.text = name;
    _titleLabel.textColor = themeColors.cellTextColor;

    _metaLabel.text = meta;
    _metaLabel.textColor = themeColors.cellDetailTextColor;

    [_playButton styleAsPrimaryAction];

    _trackView.backgroundColor = themeColors.separatorColor;
    _trackFillView.backgroundColor = accent;

    BOOL showsTrack = progress > 0.0;
    _trackView.hidden = !showsTrack;
    _trackHeightConstraint.constant = showsTrack ? kVLCOnAirContinueTrackHeight : 0.0;
    _trackArtworkSpacingConstraint.constant = showsTrack ? kVLCOnAirContinuePadding : 0.0;
    _trackMetaSpacingConstraint.constant = showsTrack ? kVLCOnAirContinuePadding : 0.0;

    _trackFillWidthConstraint.active = NO;
    _trackFillWidthConstraint = [_trackFillView.widthAnchor constraintEqualToAnchor:_trackView.widthAnchor
                                                                        multiplier:MIN(MAX(progress, 0.0), 1.0)];
    _trackFillWidthConstraint.active = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_artworkView cancelLoading];
    _artworkView.image = nil;
    _titleLabel.text = nil;
    _metaLabel.text = nil;
}

- (void)playAction
{
    [self.delegate continueCellDidTapPlay:self];
}

@end
