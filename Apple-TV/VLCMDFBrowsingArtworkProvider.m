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

@interface VLCMDFBrowsingArtworkProvider () <MDFMovieDBFetcherDataRecipient>
{
    MDFMovieDBFetcher *_tmdbFetcher;
}

@end

@implementation VLCMDFBrowsingArtworkProvider

- (void)reset
{
    if (_tmdbFetcher) {
        [_tmdbFetcher cancelAllRequests];
    } else {
        _tmdbFetcher = [[MDFMovieDBFetcher alloc] init];
        _tmdbFetcher.dataRecipient = self;
        _tmdbFetcher.shouldDecrapifyInputStrings = YES;
    }
}

- (void)setSearchForAudioMetadata:(BOOL)searchForAudioMetadata
{
    NSLog(@"there is currently no audio metadata fetcher :-(");
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
}

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFindTVShow:(MDFTVShow *)details forSearchRequest:(NSString *)searchRequest
{
    if (details == nil) {
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
}

@end
