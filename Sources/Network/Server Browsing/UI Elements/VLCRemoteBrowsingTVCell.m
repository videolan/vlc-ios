/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRemoteBrowsingTVCell.h"
#import "VLCMDFBrowsingArtworkProvider.h"
#import "VLC-Swift.h"

NSString *const VLCRemoteBrowsingTVCellIdentifier = @"VLCRemoteBrowsingTVCell";

@interface VLCRemoteBrowsingTVCell ()
{
    VLCMDFBrowsingArtworkProvider *_artworkProvider;
}
@property (nonatomic) IBOutlet NSLayoutConstraint *aspectRationConstraint;

@end

@implementation VLCRemoteBrowsingTVCell

@synthesize thumbnailURL = _thumbnailURL, isDirectory = _isDirectory, couldBeAudioOnlyMedia = _couldBeAudioOnlyMedia;

- (void)awakeFromNib
{
    [super awakeFromNib];
    _artworkProvider = [[VLCMDFBrowsingArtworkProvider alloc] init];
    _artworkProvider.artworkReceiver = self;
    self.medianew.hidden = YES;
    self.checkBoxImageView.hidden = YES;
    _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFit;
    _favorite.hidden = YES;
    self.selectedPreviously = NO;
    [self prepareForReuse];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_artworkProvider reset];
    [self.thumbnailImageView cancelLoading];
    self.title = nil;
    self.subtitle = nil;
    self.downloadArtwork = NO;
    self.selectedPreviously = NO;
}

- (void)setCouldBeAudioOnlyMedia:(BOOL)couldBeAudioOnlyMedia
{
    _artworkProvider.searchForAudioMetadata = _couldBeAudioOnlyMedia;
    if (_couldBeAudioOnlyMedia != couldBeAudioOnlyMedia) {
        [_artworkProvider reset];
    }
    _couldBeAudioOnlyMedia = couldBeAudioOnlyMedia;
}

- (void)setIsFavorable:(BOOL)isFavorable
{
    _favorite.hidden = !isFavorable;
}

- (void)setThumbnailURL:(NSURL *)thumbnailURL
{
    _thumbnailURL = thumbnailURL;
    if (_thumbnailURL) {
        [self.thumbnailImageView setImageWithURL:thumbnailURL];
    } else {
        NSString *searchString = self.title;
        if (searchString != nil && !_isDirectory && _downloadArtwork) {
            [_artworkProvider searchForArtworkForVideoRelatedString:searchString];
        }
    }
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage
{
    [self.thumbnailImageView setImage:thumbnailImage];
}

-(void)setCachedThumbnail:(VLCMLMedia *)forMedia
{
    [self.thumbnailImageView requestCachedThumbnail:forMedia];
}

-(UIImage *)thumbnailImage
{
    return self.thumbnailImageView.image;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
    if (title != nil && !_isDirectory && _downloadArtwork) {
        [_artworkProvider searchForArtworkForVideoRelatedString:title];
    }
}

-(void)setMediaProgress:(float)mediaProgress
{
    self.progressView.progress = mediaProgress;
}

-(void)setMediaisNew:(BOOL)mediaisNew
{
    self.medianew.hidden = mediaisNew;
}

-(void)setCheckBoxImageView
{
    self.checkBoxImageView.image =  self.selectedPreviously ? [UIImage imageNamed:@"checkboxEmpty"] : [UIImage imageNamed:@"checkboxSelected"];
    self.selectedPreviously = !_selectedPreviously;
}

-(void)setProgressViewHidden:(BOOL)progressViewHidden
{
    self.progressView.hidden = progressViewHidden;
}

- (NSString *)title
{
    return self.titleLabel.text;
}

- (void)setSubtitle:(NSString *)subtitle
{
    self.subtitleLabel.text = subtitle;
}

- (NSString *)subtitle
{
    return self.subtitleLabel.text;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [coordinator addCoordinatedAnimations:^{
        CGAffineTransform transform = context.nextFocusedView != self ? CGAffineTransformIdentity : CGAffineTransformMakeScale(1.05, 1.05);
        self.titleLabel.transform = transform;
        self.subtitleLabel.transform = transform;
        self.favorite.transform = transform;
    } completion:nil];
}

@synthesize isFavorable;
@synthesize mediaProgress;

@synthesize mediaisNew;

@synthesize progressViewHidden;

@synthesize forMedia;

@end
