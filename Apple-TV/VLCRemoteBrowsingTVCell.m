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
#import "MetaDataFetcherKit.h"

NSString *const VLCRemoteBrowsingTVCellIdentifier = @"VLCRemoteBrowsingTVCell";

@interface VLCRemoteBrowsingTVCell () <MDFMovieDBFetcherDataRecipient>
{
    MDFMovieDBFetcher *_metadataFetcher;
}
@property (nonatomic) IBOutlet NSLayoutConstraint *aspectRationConstraint;

@end

@implementation VLCRemoteBrowsingTVCell

@synthesize thumbnailURL = _thumbnailURL, isDirectory = _isDirectory;

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self prepareForReuse];
    UILayoutGuide *focusedFrameGuide = self.thumbnailImageView.focusedFrameGuide;
    NSLayoutConstraint *constraint = [self.titleLabel.topAnchor constraintEqualToAnchor:focusedFrameGuide.bottomAnchor];
    [self.contentView addConstraint:constraint];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    if (_metadataFetcher) {
        [_metadataFetcher cancelAllRequests];
    } else {
        _metadataFetcher = [[MDFMovieDBFetcher alloc] init];
        _metadataFetcher.dataRecipient = self;
        _metadataFetcher.shouldDecrapifyInputStrings = YES;
    }
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
            [_metadataFetcher searchForMovie:searchString];
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
        [_metadataFetcher searchForMovie:title];
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

#pragma mark - MDFMovieDB

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFindMovie:(MDFMovie *)details forSearchRequest:(NSString *)searchRequest
{
    if (details == nil)
        return;
    [aFetcher cancelAllRequests];
    MDFMovieDBSessionManager *sessionManager = [MDFMovieDBSessionManager sharedInstance];
    if (!sessionManager.hasFetchedProperties)
        return;

    if (details.movieDBID == 0) {
        /* we found nothing, let's see if it's a TV show */
        [_metadataFetcher searchForTVShow:searchRequest];
        return;
    }

    NSString *imagePath = details.posterPath;
    NSArray *sizes = sessionManager.posterSizes;
    NSString *imageSize;

    if (sizes != nil) {
        if (sizes.count > 1) {
            imageSize = sizes[1];
        } else if (sizes.count > 0) {
            imageSize = sizes.firstObject;
        }
    }

    if (!imagePath) {
        imagePath = details.backdropPath;
        sizes = sessionManager.backdropSizes;
        if (sizes != nil && sizes.count > 0) {
            imageSize = sizes.firstObject;
        }
    }
    if (!imagePath)
        return;

    NSString *thumbnailURLString = [NSString stringWithFormat:@"%@%@%@",
                                    sessionManager.imageBaseURL,
                                    imageSize,
                                    imagePath];
    self.thumbnailURL = [NSURL URLWithString:thumbnailURLString];
}

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFailToFindMovieForSearchRequest:(NSString *)searchRequest
{
    APLog(@"Failed to find a movie for '%@'", searchRequest);
}

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFindTVShow:(MDFTVShow *)details forSearchRequest:(NSString *)searchRequest
{
    if (details == nil)
        return;
    [aFetcher cancelAllRequests];
    MDFMovieDBSessionManager *sessionManager = [MDFMovieDBSessionManager sharedInstance];
    if (!sessionManager.hasFetchedProperties)
        return;

    NSString *imagePath = details.posterPath;
    NSArray *sizes = sessionManager.posterSizes;
    NSString *imageSize;

    if (sizes != nil) {
        if (sizes.count > 1) {
            imageSize = sizes[1];
        } else if (sizes.count > 0) {
            imageSize = sizes.firstObject;
        }
    }

    if (!imagePath) {
        imagePath = details.backdropPath;
        sizes = sessionManager.backdropSizes;
        if (sizes != nil && sizes.count > 0) {
            imageSize = sizes.firstObject;
        }
    }
    if (!imagePath)
        return;

    NSString *thumbnailURLString = [NSString stringWithFormat:@"%@%@%@",
                                    sessionManager.imageBaseURL,
                                    imageSize,
                                    imagePath];
    self.thumbnailURL = [NSURL URLWithString:thumbnailURLString];
}

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFailToFindTVShowForSearchRequest:(NSString *)searchRequest
{
    APLog(@"failed to find TV show");
}

@end
