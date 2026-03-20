/*****************************************************************************
 * VLCMediaTVCollectionViewCell.m
 * VLC for tvOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Authors: Felix Paul Kuehne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMediaTVCollectionViewCell.h"
#import "VLC-Swift.h"
#import <VLCMediaLibraryKit/VLCMLMedia.h>
#import <VLCMediaLibraryKit/VLCMLArtist.h>
#import <VLCMediaLibraryKit/VLCMLAlbum.h>

NSString * const VLCMediaTVCollectionViewCellIdentifier = @"VLCMediaTVCollectionViewCell";

static const CGFloat kThumbnailSize = 200.0;
static const CGFloat kCellWidth = 250.0;

@implementation VLCMediaTVCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews
{
    ColorPalette *colors = PresentationTheme.current.colors;

    _thumbnailView = [[UIImageView alloc] init];
    _thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
    _thumbnailView.clipsToBounds = YES;
    _thumbnailView.layer.cornerRadius = kThumbnailSize / 2.0;
    _thumbnailView.adjustsImageWhenAncestorFocused = YES;
    _thumbnailView.translatesAutoresizingMaskIntoConstraints = NO;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightSemibold];
    _titleLabel.textColor = colors.cellTextColor;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    _descriptionLabel = [[UILabel alloc] init];
    _descriptionLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightRegular];
    _descriptionLabel.textColor = colors.cellDetailTextColor;
    _descriptionLabel.textAlignment = NSTextAlignmentCenter;
    _descriptionLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;

    _mediaIsNewIndicator = [[UILabel alloc] init];
    _mediaIsNewIndicator.text = NSLocalizedString(@"NEW", nil);
    _mediaIsNewIndicator.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
    _mediaIsNewIndicator.textColor = colors.orangeUI;
    _mediaIsNewIndicator.hidden = YES;
    _mediaIsNewIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    _checkboxImageView = [[UIImageView alloc] init];
    _checkboxImageView.hidden = YES;
    _checkboxImageView.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *labelsStack = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _descriptionLabel]];
    labelsStack.axis = UILayoutConstraintAxisVertical;
    labelsStack.alignment = UIStackViewAlignmentCenter;
    labelsStack.spacing = 2.0;
    labelsStack.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:_thumbnailView];
    [self.contentView addSubview:labelsStack];
    [self.contentView addSubview:_mediaIsNewIndicator];
    [self.contentView addSubview:_checkboxImageView];

    [NSLayoutConstraint activateConstraints:@[
        [_thumbnailView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [_thumbnailView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [_thumbnailView.widthAnchor constraintEqualToConstant:kThumbnailSize],
        [_thumbnailView.heightAnchor constraintEqualToConstant:kThumbnailSize],

        [labelsStack.topAnchor constraintEqualToAnchor:_thumbnailView.bottomAnchor constant:10.0],
        [labelsStack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [labelsStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],

        [_mediaIsNewIndicator.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [_mediaIsNewIndicator.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],

        [_checkboxImageView.topAnchor constraintEqualToAnchor:_thumbnailView.topAnchor constant:-4.0],
        [_checkboxImageView.trailingAnchor constraintEqualToAnchor:_thumbnailView.trailingAnchor constant:4.0],
        [_checkboxImageView.widthAnchor constraintEqualToConstant:24.0],
        [_checkboxImageView.heightAnchor constraintEqualToConstant:24.0],
    ]];
}

#pragma mark - Cell size

+ (CGSize)cellSize
{
    CGFloat height = kThumbnailSize + 10.0 + 32.0 + 26.0;
    return CGSizeMake(kCellWidth, height);
}

#pragma mark - Focus

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [coordinator addCoordinatedAnimations:^{
        ColorPalette *colors = PresentationTheme.current.colors;
        if (context.nextFocusedView == self) {
            self.titleLabel.textColor = colors.orangeUI;
        } else {
            self.titleLabel.textColor = colors.cellTextColor;
        }
    } completion:nil];
}

#pragma mark - Reuse

- (void)prepareForReuse
{
    [super prepareForReuse];
    _thumbnailView.image = nil;
    _titleLabel.text = nil;
    _descriptionLabel.text = nil;
    _mediaIsNewIndicator.hidden = YES;
    _checkboxImageView.hidden = YES;
    _selectedPreviously = NO;
}

#pragma mark - Configuration

- (void)configureWithMedia:(VLCMLMedia *)media
{
    _titleLabel.text = media.title;
    _thumbnailView.image = [media thumbnailImage];
    _mediaIsNewIndicator.hidden = !media.isNew;

    NSString *artistName = media.artist.name ?: NSLocalizedString(@"UNKNOWN_ARTIST", nil);
    NSString *albumTitle = media.album.title;
    if (albumTitle.length > 0) {
        _descriptionLabel.text = [NSString stringWithFormat:@"%@ · %@", artistName, albumTitle];
    } else {
        _descriptionLabel.text = artistName;
    }
}

- (void)toggleCheckbox
{
    _selectedPreviously = !_selectedPreviously;
    _checkboxImageView.image = _selectedPreviously
        ? [UIImage imageNamed:@"checkboxSelected"]
        : [UIImage imageNamed:@"checkboxEmpty"];
}

@end
