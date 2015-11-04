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

#import "VLCServerBrowsingTVCell.h"
#import "MetaDataFetcherKit.h"

NSString *const VLCServerBrowsingTVCellIdentifier = @"VLCServerBrowsingTVCell";

@interface VLCServerBrowsingTVCell () <MDFMovieDBFetcherDataRecipient>
{
    MDFMovieDBFetcher *_metadataFetcher;
}
@end

@implementation VLCServerBrowsingTVCell
@synthesize thumbnailURL = _thumbnailURL, isDirectory = _isDirectory;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    [self prepareForReuse];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    if (_metadataFetcher) {
        [_metadataFetcher cancelAllRequests];
    } else {
        _metadataFetcher = [[MDFMovieDBFetcher alloc] init];
        _metadataFetcher.dataRecipient = self;
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
    if (!imagePath)
        imagePath = details.backdropPath;
    if (!imagePath)
        return;

    NSString *thumbnailURLString = [NSString stringWithFormat:@"%@%@%@",
                                    sessionManager.imageBaseURL,
                                    sessionManager.posterSizes.firstObject,
                                    details.posterPath];
    self.thumbnailURL = [NSURL URLWithString:thumbnailURLString];
}

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFailToFindMovieForSearchRequest:(NSString *)searchRequest
{
    APLog(@"Failed to find a movie for '%@'", searchRequest);
}

-(void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFindTVShow:(MDFTVShow *)details forSearchRequest:(NSString *)searchRequest
{
    if (details == nil)
        return;
    [aFetcher cancelAllRequests];
    MDFMovieDBSessionManager *sessionManager = [MDFMovieDBSessionManager sharedInstance];
    if (!sessionManager.hasFetchedProperties)
        return;

    NSString *imagePath = details.posterPath;
    if (!imagePath)
        imagePath = details.backdropPath;
    if (!imagePath)
        return;

    NSString *thumbnailURLString = [NSString stringWithFormat:@"%@%@%@",
                                    sessionManager.imageBaseURL,
                                    sessionManager.posterSizes.firstObject,
                                    details.posterPath];
    self.thumbnailURL = [NSURL URLWithString:thumbnailURLString];
}

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFailToFindTVShowForSearchRequest:(NSString *)searchRequest
{
    APLog(@"failed to find TV show");
}

@end
