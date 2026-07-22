/*****************************************************************************
 * VLCArtworkTile.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCArtworkTile.h"
#import "VLCPlaceholderArtwork.h"
#import "VLCNetworkImageView.h"

#import "VLC-Swift.h"

static CGFloat const kVLCArtworkTileDefaultCornerRadius = 18.0;

@implementation VLCArtworkTile
{
    UIView *_artworkContainer;
    UILabel *_initialsLabel;
    UIImageView *_glyphView;
    VLCNetworkImageView *_artworkView;
    UIVisualEffectView *_playBadge;
    UIView *_pillView;
    UILabel *_pillLabel;
    UIButton *_moreButton;
    UILabel *_nameLabel;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCArtworkTile";
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _artworkCornerRadius = kVLCArtworkTileDefaultCornerRadius;
        [self setupViews];
    }
    return self;
}

- (void)setupViews
{
    _artworkContainer = [[UIView alloc] init];
    _artworkContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [_artworkContainer roundCornersWithRadius:_artworkCornerRadius];
    _artworkContainer.clipsToBounds = YES;
    [self.contentView addSubview:_artworkContainer];

    _initialsLabel = [[UILabel alloc] init];
    _initialsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _initialsLabel.textAlignment = NSTextAlignmentCenter;
    [_artworkContainer addSubview:_initialsLabel];

    _glyphView = [[UIImageView alloc] init];
    _glyphView.translatesAutoresizingMaskIntoConstraints = NO;
    _glyphView.contentMode = UIViewContentModeScaleAspectFit;
    _glyphView.hidden = YES;
    [_artworkContainer addSubview:_glyphView];

    _artworkView = [[VLCNetworkImageView alloc] init];
    _artworkView.translatesAutoresizingMaskIntoConstraints = NO;
    _artworkView.contentMode = UIViewContentModeScaleAspectFill;
    _artworkView.clipsToBounds = YES;
    [_artworkContainer addSubview:_artworkView];

    _playBadge = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    _playBadge.translatesAutoresizingMaskIntoConstraints = NO;
    _playBadge.layer.cornerRadius = 15.0;
    _playBadge.clipsToBounds = YES;
    _playBadge.hidden = YES;
    [_artworkContainer addSubview:_playBadge];

    UIImageView *playGlyph = [[UIImageView alloc] init];
    playGlyph.translatesAutoresizingMaskIntoConstraints = NO;
    playGlyph.contentMode = UIViewContentModeScaleAspectFit;
    playGlyph.tintColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        playGlyph.image = [UIImage systemImageNamed:@"play.fill"];
    }
    [_playBadge.contentView addSubview:playGlyph];

    _pillView = [[UIView alloc] init];
    _pillView.translatesAutoresizingMaskIntoConstraints = NO;
    _pillView.backgroundColor = PresentationTheme.current.colors.orangeUI;
    [_pillView roundCornersWithRadius:9.0];
    _pillView.hidden = YES;
    [_artworkContainer addSubview:_pillView];

    _pillLabel = [[UILabel alloc] init];
    _pillLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _pillLabel.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightBold];
    _pillLabel.textColor = [UIColor whiteColor];
    [_pillView addSubview:_pillLabel];

    _moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    _moreButton.tintColor = [UIColor whiteColor];
    _moreButton.hidden = YES;
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *symbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:26.0];
        [_moreButton setPreferredSymbolConfiguration:symbolConfiguration forImageInState:UIControlStateNormal];
        [_moreButton setImage:[UIImage systemImageNamed:@"ellipsis.circle.fill"] forState:UIControlStateNormal];
    }
    [_artworkContainer addSubview:_moreButton];

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

        [_glyphView.centerXAnchor constraintEqualToAnchor:_artworkContainer.centerXAnchor],
        [_glyphView.centerYAnchor constraintEqualToAnchor:_artworkContainer.centerYAnchor],
        [_glyphView.widthAnchor constraintEqualToConstant:40.0],
        [_glyphView.heightAnchor constraintEqualToConstant:40.0],

        [_artworkView.topAnchor constraintEqualToAnchor:_artworkContainer.topAnchor],
        [_artworkView.leadingAnchor constraintEqualToAnchor:_artworkContainer.leadingAnchor],
        [_artworkView.trailingAnchor constraintEqualToAnchor:_artworkContainer.trailingAnchor],
        [_artworkView.bottomAnchor constraintEqualToAnchor:_artworkContainer.bottomAnchor],

        [_playBadge.leadingAnchor constraintEqualToAnchor:_artworkContainer.leadingAnchor constant:10.0],
        [_playBadge.bottomAnchor constraintEqualToAnchor:_artworkContainer.bottomAnchor constant:-10.0],
        [_playBadge.widthAnchor constraintEqualToConstant:30.0],
        [_playBadge.heightAnchor constraintEqualToConstant:30.0],

        [playGlyph.centerYAnchor constraintEqualToAnchor:_playBadge.centerYAnchor],
        [playGlyph.centerXAnchor constraintEqualToAnchor:_playBadge.centerXAnchor constant:1.0],
        [playGlyph.widthAnchor constraintEqualToConstant:12.0],
        [playGlyph.heightAnchor constraintEqualToConstant:13.0],

        [_pillView.trailingAnchor constraintEqualToAnchor:_artworkContainer.trailingAnchor constant:-7.0],
        [_pillView.topAnchor constraintEqualToAnchor:_artworkContainer.topAnchor constant:7.0],

        [_pillLabel.leadingAnchor constraintEqualToAnchor:_pillView.leadingAnchor constant:7.0],
        [_pillLabel.trailingAnchor constraintEqualToAnchor:_pillView.trailingAnchor constant:-7.0],
        [_pillLabel.topAnchor constraintEqualToAnchor:_pillView.topAnchor constant:2.0],
        [_pillLabel.bottomAnchor constraintEqualToAnchor:_pillView.bottomAnchor constant:-2.0],

        [_moreButton.trailingAnchor constraintEqualToAnchor:_artworkContainer.trailingAnchor constant:-8.0],
        [_moreButton.topAnchor constraintEqualToAnchor:_artworkContainer.topAnchor constant:8.0],
        [_moreButton.widthAnchor constraintEqualToConstant:34.0],
        [_moreButton.heightAnchor constraintEqualToConstant:34.0],

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
                                                                   cornerRadius:_artworkCornerRadius].CGPath;
}

- (void)setArtworkCornerRadius:(CGFloat)artworkCornerRadius
{
    if (_artworkCornerRadius == artworkCornerRadius) {
        return;
    }

    _artworkCornerRadius = artworkCornerRadius;
    [_artworkContainer roundCornersWithRadius:artworkCornerRadius];
    [self setNeedsLayout];
}

- (void)setBadge:(VLCArtworkTileBadge)badge
{
    _badge = badge;
    _playBadge.hidden = badge != VLCArtworkTileBadgePlay;
}

- (void)setPillText:(NSString *)pillText
{
    _pillText = [pillText copy];
    _pillLabel.text = _pillText;
    _pillView.hidden = _pillText.length == 0;
}

- (void)setDelegate:(id<VLCArtworkTileDelegate>)delegate
{
    if (_delegate == delegate) {
        return;
    }

    _delegate = delegate;
    if (@available(iOS 14.0, *)) {
        _moreButton.hidden = delegate == nil;
        [self updateMenu];
    }
}

- (void)setRemovalActionTitle:(NSString *)removalActionTitle
{
    _removalActionTitle = [removalActionTitle copy];
    if (@available(iOS 14.0, *)) {
        [self updateMenu];
    }
}

- (void)updateMenu API_AVAILABLE(ios(14.0))
{
    NSString *title = _removalActionTitle.length > 0 ? _removalActionTitle
                                                     : NSLocalizedString(@"REMOVE_FAVORITE", nil);
    __weak typeof(self) weakSelf = self;
    UIAction *removeAction = [UIAction actionWithTitle:title
                                                 image:[UIImage systemImageNamed:@"heart.slash"]
                                            identifier:nil
                                               handler:^(__kindof UIAction *action) {
        [weakSelf.delegate artworkTileDidRequestRemoval:weakSelf];
    }];
    removeAction.attributes = UIMenuElementAttributesDestructive;

    UIDeferredMenuElement *delegateElements =
        [UIDeferredMenuElement elementWithProvider:^(void (^completion)(NSArray<UIMenuElement *> *)) {
        if ([weakSelf.delegate respondsToSelector:@selector(menuElementsForArtworkTile:)]) {
            completion([weakSelf.delegate menuElementsForArtworkTile:weakSelf] ?: @[]);
        } else {
            completion(@[]);
        }
    }];

    _moreButton.menu = [UIMenu menuWithTitle:@"" children:@[delegateElements, removeAction]];
    _moreButton.showsMenuAsPrimaryAction = YES;
}

- (void)configureWithName:(NSString *)name artworkURL:(NSURL *)artworkURL
{
    _nameLabel.text = name;
    _nameLabel.textColor = PresentationTheme.current.colors.cellTextColor;

    _glyphView.hidden = YES;
    _initialsLabel.hidden = NO;
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

- (void)configureWithName:(NSString *)name glyph:(UIImage *)glyph tintColor:(UIColor *)tintColor
{
    _nameLabel.text = name;
    _nameLabel.textColor = PresentationTheme.current.colors.cellTextColor;

    _initialsLabel.hidden = YES;
    _initialsLabel.text = nil;
    _artworkView.hidden = YES;
    _artworkContainer.backgroundColor = tintColor;

    _glyphView.hidden = NO;
    _glyphView.image = [glyph imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _glyphView.tintColor = PresentationTheme.current.colors.orangeUI;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_artworkView cancelLoading];
    _artworkView.image = nil;
    _artworkView.hidden = NO;
    _nameLabel.text = nil;
    _initialsLabel.text = nil;
    _initialsLabel.hidden = NO;
    _glyphView.image = nil;
    _glyphView.hidden = YES;
    self.pillText = nil;
}

@end
