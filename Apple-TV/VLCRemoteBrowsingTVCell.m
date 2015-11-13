/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRemoteBrowsingTVCell.h"
#import "VLCMDFBrowsingArtworkProvider.h"

NSString *const VLCRemoteBrowsingTVCellIdentifier = @"VLCRemoteBrowsingTVCell";

@interface VLCRemoteBrowsingTVCell ()
{
    VLCMDFBrowsingArtworkProvider *_artworkProvider;
}
@property (nonatomic) IBOutlet NSLayoutConstraint *aspectRationConstraint;

@end

@implementation VLCRemoteBrowsingTVCell

@synthesize thumbnailURL = _thumbnailURL, isDirectory = _isDirectory;

- (void)awakeFromNib
{
    [super awakeFromNib];
    _artworkProvider = [[VLCMDFBrowsingArtworkProvider alloc] init];
    _artworkProvider.artworkReceiver = self;
    [self prepareForReuse];
    UILayoutGuide *focusedFrameGuide = self.thumbnailImageView.focusedFrameGuide;
    NSLayoutConstraint *constraint = [self.titleLabel.topAnchor constraintEqualToAnchor:focusedFrameGuide.bottomAnchor];
    [self.contentView addConstraint:constraint];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_artworkProvider reset];
    [self.thumbnailImageView cancelLoading];
    self.title = nil;
    self.subtitle = nil;
}

- (void)setThumbnailURL:(NSURL *)thumbnailURL
{
    _thumbnailURL = thumbnailURL;
    if (_thumbnailURL) {
        [self.thumbnailImageView setImageWithURL:thumbnailURL];
    } else {
        NSString *searchString = self.title;
        if (searchString != nil && !_isDirectory) {
            [_artworkProvider searchForArtworkForVideoRelatedString:searchString];
        }
    }
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage
{
    [self.thumbnailImageView setImage:thumbnailImage];
}

-(UIImage *)thumbnailImage
{
    return self.thumbnailImageView.image;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
    if (title != nil && !_isDirectory) {
        [_artworkProvider searchForArtworkForVideoRelatedString:title];
    }
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

@end
