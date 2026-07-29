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
    VLCNetworkImageView *_artworkView;
    UIVisualEffectView *_badgeView;
    UIImageView *_badgeGlyph;
    NSLayoutConstraint *_badgeGlyphCenterX;
    NSLayoutConstraint *_badgeGlyphWidth;
    NSLayoutConstraint *_badgeGlyphHeight;
    UIView *_pillView;
    UILabel *_pillLabel;
    UIButton *_accessoryButton;
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

    _artworkView = [[VLCNetworkImageView alloc] init];
    _artworkView.translatesAutoresizingMaskIntoConstraints = NO;
    _artworkView.contentMode = UIViewContentModeScaleAspectFill;
    _artworkView.clipsToBounds = YES;
    [_artworkContainer addSubview:_artworkView];

    _badgeView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    _badgeView.translatesAutoresizingMaskIntoConstraints = NO;
    _badgeView.layer.cornerRadius = 15.0;
    _badgeView.clipsToBounds = YES;
    _badgeView.hidden = YES;
    [_artworkContainer addSubview:_badgeView];

    _badgeGlyph = [[UIImageView alloc] init];
    _badgeGlyph.translatesAutoresizingMaskIntoConstraints = NO;
    _badgeGlyph.contentMode = UIViewContentModeScaleAspectFit;
    _badgeGlyph.tintColor = [UIColor whiteColor];
    [_badgeView.contentView addSubview:_badgeGlyph];

    _badgeGlyphCenterX = [_badgeGlyph.centerXAnchor constraintEqualToAnchor:_badgeView.centerXAnchor constant:1.0];
    _badgeGlyphWidth = [_badgeGlyph.widthAnchor constraintEqualToConstant:12.0];
    _badgeGlyphHeight = [_badgeGlyph.heightAnchor constraintEqualToConstant:13.0];

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

    _accessoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _accessoryButton.translatesAutoresizingMaskIntoConstraints = NO;
    _accessoryButton.userInteractionEnabled = NO;
    _accessoryButton.hidden = YES;
    [self applyAccessoryButtonStyle];
    [_artworkContainer addSubview:_accessoryButton];

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

        [_artworkView.topAnchor constraintEqualToAnchor:_artworkContainer.topAnchor],
        [_artworkView.leadingAnchor constraintEqualToAnchor:_artworkContainer.leadingAnchor],
        [_artworkView.trailingAnchor constraintEqualToAnchor:_artworkContainer.trailingAnchor],
        [_artworkView.bottomAnchor constraintEqualToAnchor:_artworkContainer.bottomAnchor],

        [_badgeView.leadingAnchor constraintEqualToAnchor:_artworkContainer.leadingAnchor constant:10.0],
        [_badgeView.bottomAnchor constraintEqualToAnchor:_artworkContainer.bottomAnchor constant:-10.0],
        [_badgeView.widthAnchor constraintEqualToConstant:30.0],
        [_badgeView.heightAnchor constraintEqualToConstant:30.0],

        [_badgeGlyph.centerYAnchor constraintEqualToAnchor:_badgeView.centerYAnchor],
        _badgeGlyphCenterX,
        _badgeGlyphWidth,
        _badgeGlyphHeight,

        [_pillView.trailingAnchor constraintEqualToAnchor:_artworkContainer.trailingAnchor constant:-7.0],
        [_pillView.topAnchor constraintEqualToAnchor:_artworkContainer.topAnchor constant:7.0],

        [_pillLabel.leadingAnchor constraintEqualToAnchor:_pillView.leadingAnchor constant:7.0],
        [_pillLabel.trailingAnchor constraintEqualToAnchor:_pillView.trailingAnchor constant:-7.0],
        [_pillLabel.topAnchor constraintEqualToAnchor:_pillView.topAnchor constant:2.0],
        [_pillLabel.bottomAnchor constraintEqualToAnchor:_pillView.bottomAnchor constant:-2.0],

        [_accessoryButton.trailingAnchor constraintEqualToAnchor:_artworkContainer.trailingAnchor constant:-10.0],
        [_accessoryButton.bottomAnchor constraintEqualToAnchor:_artworkContainer.bottomAnchor constant:-10.0],
        [_accessoryButton.widthAnchor constraintEqualToConstant:30.0],
        [_accessoryButton.heightAnchor constraintEqualToConstant:30.0],

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

- (void)applyAccessoryButtonStyle
{
#if !TARGET_OS_VISION
    if (@available(iOS 26.0, *)) {
        UIButtonConfiguration *glass = [UIButtonConfiguration glassButtonConfiguration];
        glass.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
        glass.baseForegroundColor = PresentationTheme.current.colors.orangeUI;
        _accessoryButton.configuration = glass;
        return;
    }
#endif
    _accessoryButton.tintColor = PresentationTheme.current.colors.orangeUI;
    _accessoryButton.backgroundColor = PresentationTheme.current.colors.transparentDarkBackgroundColor;
    _accessoryButton.layer.cornerRadius = 15.0;
    _accessoryButton.clipsToBounds = YES;
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

- (NSString *)symbolNameForBadge:(VLCArtworkTileBadge)badge
{
    switch (badge) {
        case VLCArtworkTileBadgePlay:
            return @"play.fill";
        case VLCArtworkTileBadgeFolder:
            return @"folder.fill";
        case VLCArtworkTileBadgeServer:
            if (@available(iOS 14.0, *)) {
                return @"server.rack";
            }
            return @"network";
        case VLCArtworkTileBadgeNone:
            return nil;
    }
}

- (void)setBadge:(VLCArtworkTileBadge)badge
{
    _badge = badge;
    _badgeView.hidden = badge == VLCArtworkTileBadgeNone;

    if (badge == VLCArtworkTileBadgeNone) {
        return;
    }

    BOOL isPlay = badge == VLCArtworkTileBadgePlay;
    _badgeGlyphCenterX.constant = isPlay ? 1.0 : 0.0;
    _badgeGlyphWidth.constant = isPlay ? 12.0 : 15.0;
    _badgeGlyphHeight.constant = 13.0;

    if (@available(iOS 13.0, *)) {
        _badgeGlyph.image = [UIImage systemImageNamed:[self symbolNameForBadge:badge]];
    }
}

- (void)setPillText:(NSString *)pillText
{
    _pillText = [pillText copy];
    _pillLabel.text = _pillText;
    _pillView.hidden = _pillText.length == 0;
}

- (void)setAccessoryGlyphName:(NSString *)accessoryGlyphName
{
    _accessoryGlyphName = [accessoryGlyphName copy];

    UIImage *image = nil;
    if (@available(iOS 13.0, *)) {
        if (_accessoryGlyphName.length > 0) {
            UIImageSymbolConfiguration *symbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:14.0];
            image = [UIImage systemImageNamed:_accessoryGlyphName withConfiguration:symbolConfiguration];
        }
    }

#if TARGET_OS_VISION
    [_accessoryButton setImage:image forState:UIControlStateNormal];
#else
    if (@available(iOS 26.0, *)) {
        UIButtonConfiguration *glass = _accessoryButton.configuration;
        glass.image = image;
        _accessoryButton.configuration = glass;
    } else {
        [_accessoryButton setImage:image forState:UIControlStateNormal];
    }
#endif
    _accessoryButton.hidden = image == nil;
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
    self.pillText = nil;
    self.accessoryGlyphName = nil;
    self.badge = VLCArtworkTileBadgeNone;
    self.delegate = nil;
    self.removalActionTitle = nil;
}

@end
