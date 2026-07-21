/*****************************************************************************
 * VLCRadioFavoriteTile.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRadioFavoriteTile.h"
#import "VLCPlaceholderArtwork.h"
#import "VLCNetworkImageView.h"

#import "VLC-Swift.h"

@implementation VLCRadioFavoriteTile
{
    UIView *_artworkContainer;
    UILabel *_initialsLabel;
    VLCNetworkImageView *_artworkView;
    UILabel *_nameLabel;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCRadioFavoriteTile";
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews
{
    _artworkContainer = [[UIView alloc] init];
    _artworkContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _artworkContainer.layer.cornerRadius = 18.0;
    _artworkContainer.clipsToBounds = YES;
    [self.contentView addSubview:_artworkContainer];

    _initialsLabel = [[UILabel alloc] init];
    _initialsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _initialsLabel.textAlignment = NSTextAlignmentCenter;
    [_artworkContainer addSubview:_initialsLabel];

    _artworkView = [[VLCNetworkImageView alloc] init];
    _artworkView.translatesAutoresizingMaskIntoConstraints = NO;
    _artworkView.contentMode = UIViewContentModeScaleAspectFill;
    _artworkView.clipsToBounds = YES;
    [_artworkContainer addSubview:_artworkView];

    UIVisualEffectView *badge = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    badge.layer.cornerRadius = 15.0;
    badge.clipsToBounds = YES;
    [_artworkContainer addSubview:badge];

    UIImageView *playGlyph = [[UIImageView alloc] init];
    playGlyph.translatesAutoresizingMaskIntoConstraints = NO;
    playGlyph.contentMode = UIViewContentModeScaleAspectFit;
    playGlyph.tintColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        playGlyph.image = [UIImage systemImageNamed:@"play.fill"];
    }
    [badge.contentView addSubview:playGlyph];

    _nameLabel = [[UILabel alloc] init];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    _nameLabel.numberOfLines = 1;
    _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:_nameLabel];

    [NSLayoutConstraint activateConstraints:@[
        [_artworkContainer.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [_artworkContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [_artworkContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [_artworkContainer.heightAnchor constraintEqualToAnchor:_artworkContainer.widthAnchor],

        [_initialsLabel.leadingAnchor constraintEqualToAnchor:_artworkContainer.leadingAnchor constant:8.0],
        [_initialsLabel.trailingAnchor constraintEqualToAnchor:_artworkContainer.trailingAnchor constant:-8.0],
        [_initialsLabel.centerYAnchor constraintEqualToAnchor:_artworkContainer.centerYAnchor],

        [_artworkView.topAnchor constraintEqualToAnchor:_artworkContainer.topAnchor],
        [_artworkView.leadingAnchor constraintEqualToAnchor:_artworkContainer.leadingAnchor],
        [_artworkView.trailingAnchor constraintEqualToAnchor:_artworkContainer.trailingAnchor],
        [_artworkView.bottomAnchor constraintEqualToAnchor:_artworkContainer.bottomAnchor],

        [badge.leadingAnchor constraintEqualToAnchor:_artworkContainer.leadingAnchor constant:10.0],
        [badge.bottomAnchor constraintEqualToAnchor:_artworkContainer.bottomAnchor constant:-10.0],
        [badge.widthAnchor constraintEqualToConstant:30.0],
        [badge.heightAnchor constraintEqualToConstant:30.0],

        [playGlyph.centerYAnchor constraintEqualToAnchor:badge.centerYAnchor],
        [playGlyph.centerXAnchor constraintEqualToAnchor:badge.centerXAnchor constant:1.0],
        [playGlyph.widthAnchor constraintEqualToConstant:12.0],
        [playGlyph.heightAnchor constraintEqualToConstant:13.0],

        [_nameLabel.topAnchor constraintEqualToAnchor:_artworkContainer.bottomAnchor constant:8.0],
        [_nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:2.0],
        [_nameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-2.0],
        [_nameLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor]
    ]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    // scale the initials to the actual tile size and keep the shadow path in sync
    CGFloat tileWidth = self.contentView.bounds.size.width;
    _initialsLabel.font = [UIFont systemFontOfSize:MAX(24.0, tileWidth * 0.28)
                                            weight:UIFontWeightHeavy];

    self.contentView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.contentView.layer.shadowOffset = CGSizeMake(0, 4);
    self.contentView.layer.shadowRadius = 7.0;
    self.contentView.layer.shadowOpacity = 0.1;
    self.contentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_artworkContainer.frame
                                                                   cornerRadius:18.0].CGPath;
}

- (void)configureWithName:(NSString *)name artworkURL:(NSURL *)artworkURL
{
    _nameLabel.text = name;
    _nameLabel.textColor = PresentationTheme.current.colors.cellTextColor;

    _artworkContainer.backgroundColor = [VLCPlaceholderArtwork backgroundColorForName:name];
    _initialsLabel.textColor = [VLCPlaceholderArtwork foregroundColorForName:name];
    _initialsLabel.text = [VLCPlaceholderArtwork initialsForName:name];

    if (artworkURL) {
        _artworkView.hidden = NO;
        [_artworkView setImageWithURL:artworkURL];
    } else {
        _artworkView.hidden = YES;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_artworkView cancelLoading];
    _artworkView.image = nil;
    _artworkView.hidden = NO;
    _nameLabel.text = nil;
    _initialsLabel.text = nil;
}

@end
