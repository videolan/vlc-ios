/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMDFBrowsingArtworkProvider.h"
#import "MetaDataFetcherKit.h"

@interface VLCMDFBrowsingArtworkProvider () <MDFMovieDBFetcherDataRecipient, MDFHatchetFetcherDataRecipient>
{
    MDFMovieDBFetcher *_tmdbFetcher;
    MDFHatchetFetcher *_hatchetFetcher;
}

@end

@implementation VLCMDFBrowsingArtworkProvider

- (void)reset
{
    if (_tmdbFetcher) {
        [_tmdbFetcher cancelAllRequests];
        if (_hatchetFetcher)
            [_hatchetFetcher cancelAllRequests];
    } else {
        _tmdbFetcher = [[MDFMovieDBFetcher alloc] init];
        _tmdbFetcher.dataRecipient = self;
        _tmdbFetcher.shouldDecrapifyInputStrings = YES;

        if (_searchForAudioMetadata) {
            _hatchetFetcher = [[MDFHatchetFetcher alloc] init];
            _hatchetFetcher.dataRecipient = self;
        }
    }
}

- (void)setSearchForAudioMetadata:(BOOL)searchForAudioMetadata
{
    if (searchForAudioMetadata) {
        _hatchetFetcher = [[MDFHatchetFetcher alloc] init];
        _hatchetFetcher.dataRecipient = self;
    }
    _searchForAudioMetadata = searchForAudioMetadata;
}

- (void)searchForArtworkForVideoRelatedString:(NSString *)string
{
    [_tmdbFetcher searchForMovie:string];
}

#pragma mark - MDFMovieDB

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFindMovie:(MDFMovie *)details forSearchRequest:(NSString *)searchRequest
{
    if (details == nil) {
        return;
    }
    [aFetcher cancelAllRequests];
    MDFMovieDBSessionManager *sessionManager = [MDFMovieDBSessionManager sharedInstance];
    if (!sessionManager.hasFetchedProperties) {
        return;
    }

    if (details.movieDBID == 0) {
        /* we found nothing, let's see if it's a TV show */
        [_tmdbFetcher searchForTVShow:searchRequest];
        return;
    }

    NSString *imagePath = details.posterPath;
    NSArray *sizes = sessionManager.posterSizes;
    NSString *imageSize;

    if (sizes != nil) {
        NSUInteger count = sizes.count;
        if (count > 1) {
            imageSize = sizes[1];
        } else if (count > 0) {
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
    if (!imagePath) {
        return;
    }

    NSString *thumbnailURLString = [NSString stringWithFormat:@"%@%@%@",
                                    sessionManager.imageBaseURL,
                                    imageSize,
                                    imagePath];
    self.artworkReceiver.thumbnailURL = [NSURL URLWithString:thumbnailURLString];
}

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFailToFindMovieForSearchRequest:(NSString *)searchRequest
{
    APLog(@"Failed to find a movie for '%@'", searchRequest);

    if (_searchForAudioMetadata) {
        [_hatchetFetcher searchForArtist:searchRequest];
    }
}

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFindTVShow:(MDFTVShow *)details forSearchRequest:(NSString *)searchRequest
{
    if (details == nil) {
        if (_searchForAudioMetadata) {
            [_hatchetFetcher searchForArtist:searchRequest];
        }
        return;
    }

    [aFetcher cancelAllRequests];
    MDFMovieDBSessionManager *sessionManager = [MDFMovieDBSessionManager sharedInstance];
    if (!sessionManager.hasFetchedProperties)
        return;

    NSString *imagePath = details.posterPath;
    NSArray *sizes = sessionManager.posterSizes;
    NSString *imageSize;

    if (sizes != nil) {
        NSUInteger count = sizes.count;
        if (count > 1) {
            imageSize = sizes[1];
        } else if (count > 0) {
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
    if (!imagePath) {
        if (_searchForAudioMetadata) {
            [_hatchetFetcher searchForArtist:searchRequest];
        }
        return;
    }

    NSString *thumbnailURLString = [NSString stringWithFormat:@"%@%@%@",
                                    sessionManager.imageBaseURL,
                                    imageSize,
                                    imagePath];
    self.artworkReceiver.thumbnailURL = [NSURL URLWithString:thumbnailURLString];
}

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFailToFindTVShowForSearchRequest:(NSString *)searchRequest
{
    APLog(@"failed to find TV show");

    if (_searchForAudioMetadata) {
        [_hatchetFetcher searchForArtist:searchRequest];
    }
}

- (void)MDFHatchetFetcher:(MDFHatchetFetcher *)aFetcher didFindArtist:(MDFArtist *)artist forSearchRequest:(NSString *)searchRequest
{
    /* we have no match */
    if (!artist) {
        [self _simplifyMetaDataSearchString:searchRequest];
        return;
    }

    NSArray *imageURLStrings = artist.largeSizedImages;
    NSString *imageURLString;

    if (imageURLStrings.count > 0) {
        imageURLString = imageURLStrings.firstObject;
    } else {
        imageURLStrings = artist.mediumSizedImages;
        if (imageURLStrings.count > 0) {
            imageURLString = imageURLStrings.firstObject;
        }
    }

    if (imageURLString) {
        self.artworkReceiver.thumbnailURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?height=300&width=250",imageURLString]];
    } else {
        [self _simplifyMetaDataSearchString:searchRequest];
    }
}

- (void)MDFHatchetFetcher:(MDFHatchetFetcher *)aFetcher didFailToFindArtistForSearchRequest:(NSString *)searchRequest
{
    [self _simplifyMetaDataSearchString:searchRequest];
}

- (void)_simplifyMetaDataSearchString:(NSString *)searchString
{
    NSRange lastRange = [searchString rangeOfString:@" " options:NSBackwardsSearch];
    if (lastRange.location != NSNotFound)
        [_hatchetFetcher searchForArtist:[searchString substringToIndex:lastRange.location]];
}

@end
