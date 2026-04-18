/*****************************************************************************
 * VLCMovieTVCollectionViewCell.m
 * VLC for tvOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Authors: Felix Paul Kuehne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMovieTVCollectionViewCell.h"
#import "VLC-Swift.h"
#import <VLCMediaLibraryKit/VLCMLMedia.h>

NSString * const VLCMovieTVCollectionViewCellIdentifier = @"VLCMovieTVCollectionViewCell";

static const CGFloat kCellWidth = 400.0;
static const CGFloat kThumbnailAspectRatio = 9.0 / 16.0;

@implementation VLCMovieTVCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTheme) name:kVLCThemeDidChangeNotification object:nil];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupViews];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTheme) name:kVLCThemeDidChangeNotification object:nil];
    }
    return self;
}

- (void)setupViews
{
    CGFloat thumbnailHeight = kCellWidth * kThumbnailAspectRatio;

    // Thumbnail
    _thumbnailView = [[UIImageView alloc] init];
    _thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
    _thumbnailView.clipsToBounds = YES;
    _thumbnailView.layer.cornerRadius = 6.0;
    _thumbnailView.adjustsImageWhenAncestorFocused = YES;
    _thumbnailView.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *thumbnailContainer = [[UIView alloc] init];
    thumbnailContainer.translatesAutoresizingMaskIntoConstraints = NO;
    thumbnailContainer.clipsToBounds = NO;

    [self.contentView addSubview:thumbnailContainer];
    [thumbnailContainer addSubview:_thumbnailView];

    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressView.progressTintColor = [UIColor systemOrangeColor];
    _progressView.trackTintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    _progressView.translatesAutoresizingMaskIntoConstraints = NO;
    _progressView.layer.cornerRadius = 2.0;
    _progressView.clipsToBounds = YES;
    _progressView.hidden = YES;
    [self.contentView addSubview:_progressView];

    _mediaIsNewIndicator = [[UILabel alloc] init];
    _mediaIsNewIndicator.text = NSLocalizedString(@"NEW", nil);
    _mediaIsNewIndicator.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
    _mediaIsNewIndicator.hidden = YES;
    _mediaIsNewIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [_mediaIsNewIndicator setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [_mediaIsNewIndicator setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.contentView addSubview:_mediaIsNewIndicator];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightSemibold];
    _titleLabel.numberOfLines = 2;
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_titleLabel];

    _descriptionLabel = [[UILabel alloc] init];
    _descriptionLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightRegular];
    _descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_descriptionLabel];

    [self updateTheme];

    _checkboxImageView = [[UIImageView alloc] init];
    _checkboxImageView.hidden = YES;
    _checkboxImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_checkboxImageView];

    [NSLayoutConstraint activateConstraints:@[
        [thumbnailContainer.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [thumbnailContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [thumbnailContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [thumbnailContainer.heightAnchor constraintEqualToConstant:thumbnailHeight],

        [_thumbnailView.topAnchor constraintEqualToAnchor:thumbnailContainer.topAnchor],
        [_thumbnailView.leadingAnchor constraintEqualToAnchor:thumbnailContainer.leadingAnchor],
        [_thumbnailView.trailingAnchor constraintEqualToAnchor:thumbnailContainer.trailingAnchor],
        [_thumbnailView.bottomAnchor constraintEqualToAnchor:thumbnailContainer.bottomAnchor],

        [_progressView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [_progressView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [_progressView.topAnchor constraintEqualToAnchor:thumbnailContainer.bottomAnchor],
        [_progressView.heightAnchor constraintEqualToConstant:4.0],

        [_mediaIsNewIndicator.topAnchor constraintEqualToAnchor:_progressView.bottomAnchor constant:6.0],
        [_mediaIsNewIndicator.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],

        [_titleLabel.topAnchor constraintEqualToAnchor:_progressView.bottomAnchor constant:6.0],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:_mediaIsNewIndicator.leadingAnchor constant:-4.0],

        [_descriptionLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:2.0],
        [_descriptionLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [_descriptionLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],

        [_checkboxImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8.0],
        [_checkboxImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8.0],
        [_checkboxImageView.widthAnchor constraintEqualToConstant:30.0],
        [_checkboxImageView.heightAnchor constraintEqualToConstant:30.0],
    ]];
}

#pragma mark - Cell size

+ (CGSize)cellSize
{
    CGFloat thumbnailHeight = kCellWidth * kThumbnailAspectRatio;
    // thumbnail + progress(4) + padding(6) + title(~64) + padding(2) + description(~26)
    CGFloat totalHeight = thumbnailHeight + 4.0 + 6.0 + 64.0 + 2.0 + 26.0;
    return CGSizeMake(kCellWidth, totalHeight);
}

#pragma mark - Theme

- (void)updateTheme
{
    ColorPalette *colors = PresentationTheme.current.colors;
    _titleLabel.textColor = colors.cellTextColor;
    _descriptionLabel.textColor = colors.cellDetailTextColor;
    _mediaIsNewIndicator.textColor = colors.orangeUI;
}

#pragma mark - Focus

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [coordinator addCoordinatedAnimations:^{
        if (context.nextFocusedView == self) {
            CGAffineTransform transform = CGAffineTransformMakeScale(1.05, 1.05);
            self.titleLabel.transform = transform;
            self.descriptionLabel.transform = transform;
        } else {
            self.titleLabel.transform = CGAffineTransformIdentity;
            self.descriptionLabel.transform = CGAffineTransformIdentity;
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
    _progressView.hidden = YES;
    _progressView.progress = 0;
    _mediaIsNewIndicator.hidden = YES;
    _checkboxImageView.hidden = YES;
    _selectedPreviously = NO;
}

#pragma mark - Configuration

- (void)configureWithMedia:(VLCMLMedia *)media
{
    _titleLabel.text = media.title;
    _descriptionLabel.text = [media mediaDuration];
    _thumbnailView.image = [media thumbnailImage];

    BOOL continuePlayback = [[NSUserDefaults standardUserDefaults] boolForKey:KVLCContinuePlaybackWhereLeftOff];
    if (continuePlayback && media.progress > 0) {
        _progressView.hidden = NO;
        _progressView.progress = media.progress;
    } else {
        _progressView.hidden = YES;
    }

    _mediaIsNewIndicator.hidden = !media.isNew;
}

- (void)toggleCheckbox
{
    _selectedPreviously = !_selectedPreviously;
    _checkboxImageView.image = _selectedPreviously
        ? [UIImage imageNamed:@"checkboxSelected"]
        : [UIImage imageNamed:@"checkboxEmpty"];
}

@end
