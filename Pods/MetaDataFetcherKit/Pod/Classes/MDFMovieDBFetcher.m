/*****************************************************************************
 * MDFMovieDBFetcher.m
 *****************************************************************************
 * Copyright (C) 2015 Felix Paul Kühne
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "MDFMovieDBFetcher.h"
#import "MDFMovieDBSessionManager.h"
#import "MDFMovie.h"
#import "MDFTVShow.h"
#import "MLTitleDecrapifier.h"

@interface MDFMovieDBFetcher ()
{
    NSMutableArray<NSURLSessionTask *> *_requests;
}
@end

@implementation MDFMovieDBFetcher

- (NSString *)description
{
    NSString *ret;
    @synchronized(_requests) {
        ret = [NSString stringWithFormat:@"%s: %lu pending requests", __PRETTY_FUNCTION__, (unsigned long)_requests.count];
    }
    return ret;
}

- (void)cancelAllRequests
{
    @synchronized(_requests) {
        NSUInteger requestCount = [_requests count];
        for (NSUInteger i = 0; i < requestCount; i++) {
            [_requests[i] cancel];
        }
        _requests = [NSMutableArray array];
    }

}

- (void)searchForMovie:(NSString *)searchRequest
{
    [self searchForMovie:searchRequest releaseYear:nil language:nil includeAdult:NO];
}

- (void)searchForMovie:(NSString *)searchRequest releaseYear:(NSString *)releaseYear language:(NSString *)languageCode includeAdult:(BOOL)includeAdult
{
    if (!searchRequest)
        return;

    MDFMovieDBSessionManager *sessionManager = [MDFMovieDBSessionManager sharedInstance];
    if (!sessionManager.apiKey)
        return;

    NSString *originalSearchRequest = [searchRequest copy];

    @synchronized(_requests) {
        if (!_requests)
            _requests = [NSMutableArray array];
    }

    if (self.shouldDecrapifyInputStrings) {
        searchRequest = [MLTitleDecrapifier decrapify:searchRequest];
    }

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:sessionManager.apiKey, @"api_key",
                                       searchRequest, @"query", nil];

    if (releaseYear != nil)
        [parameters setObject:releaseYear forKey:@"year"];
    if (languageCode != nil)
        [parameters setObject:languageCode forKey:@"language"];
    if (includeAdult)
        [parameters setObject:@"true" forKey:@"include_adult"];
    else
        [parameters setObject:@"false" forKey:@"include_adult"];

    NSURLSessionTask *task = [sessionManager GET:@"search/movie"
                                      parameters:parameters
                                         success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
                                             @synchronized(_requests) {
                                                 [_requests removeObject:task];
                                             }

                                             MDFMovie *movie;

                                             if (responseObject != nil) {
                                                 NSArray *results = responseObject[@"results"];
                                                 if (results != nil) {
                                                     /* the first result is always the most popular and likely one */
                                                     NSDictionary *resultDict = [results firstObject];

                                                     movie = [[MDFMovie alloc] init];
                                                     movie.isAdultContent = [resultDict[@"adult"] boolValue];
                                                     movie.originalLanguage = resultDict[@"original_language"];
                                                     movie.originalTitle = resultDict[@"original_title"];
                                                     movie.title = resultDict[@"title"];
                                                     movie.contentDescription = resultDict[@"overview"];
                                                     movie.releaseDate = [NSDate date]; // FIXME: insert correct date
                                                     movie.posterPath = resultDict[@"poster_path"];
                                                     movie.backdropPath = resultDict[@"backdrop_path"];
                                                     movie.movieDBID = [resultDict[@"id"] integerValue];
                                                 }
                                             }

                                             if (self.dataRecipient) {
                                                 if ([self.dataRecipient respondsToSelector:@selector(MDFMovieDBFetcher:didFindMovie:forSearchRequest:)]) {
                                                     [self.dataRecipient MDFMovieDBFetcher:self
                                                                              didFindMovie:movie
                                                                          forSearchRequest:originalSearchRequest];
                                                 }
                                             }
                                         } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                             @synchronized(_requests) {
                                                 [_requests removeObject:task];
                                             }

                                             if (self.dataRecipient) {
                                                 if ([self.dataRecipient respondsToSelector:@selector(MDFMovieDBFetcher:didFailToFindMovieForSearchRequest:)]) {
                                                     [self.dataRecipient MDFMovieDBFetcher:self
                                                        didFailToFindMovieForSearchRequest:originalSearchRequest];
                                                 }
                                             }
                                         }];
    @synchronized(_requests) {
        [_requests addObject:task];
    }
}

- (void)searchForTVShow:(NSString *)searchRequest
{
    [self searchForTVShow:searchRequest firstAirYear:nil language:nil];
}

- (void)searchForTVShow:(NSString *)searchRequest firstAirYear:(NSString *)firstAirYear language:(NSString *)languageCode
{
    if (!searchRequest)
        return;

    MDFMovieDBSessionManager *sessionManager = [MDFMovieDBSessionManager sharedInstance];
    if (!sessionManager.apiKey)
        return;

    @synchronized(_requests) {
        if (!_requests)
            _requests = [NSMutableArray array];
    }
    NSString *originalSearchRequest = [searchRequest copy];

    if (self.shouldDecrapifyInputStrings) {
        NSDictionary *decrapificationResults = [MLTitleDecrapifier tvShowEpisodeInfoFromString:searchRequest];
        NSString *showName = decrapificationResults[@"tvShowName"];
        if (showName) {
            searchRequest = showName;
        }
    }

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:sessionManager.apiKey, @"api_key",
                                       searchRequest, @"query", nil];

    if (firstAirYear != nil)
        [parameters setObject:firstAirYear forKey:@"first_air_date_year"];
    if (languageCode != nil)
        [parameters setObject:languageCode forKey:@"language"];

    NSURLSessionTask *task = [sessionManager GET:@"search/tv"
                                      parameters:parameters
                                         success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
                                             @synchronized(_requests) {
                                                 [_requests removeObject:task];
                                             }

                                             MDFTVShow *tvShow;

                                             if (responseObject != nil) {
                                                 NSArray *results = responseObject[@"results"];
                                                 if (results != nil) {
                                                     /* the first result is always the most popular and likely one */
                                                     NSDictionary *resultDict = [results firstObject];

                                                     tvShow = [[MDFTVShow alloc] init];
                                                     tvShow.isAdultContent = [resultDict[@"adult"] boolValue];
                                                     tvShow.originalLanguage = resultDict[@"original_language"];
                                                     tvShow.originalTitle = resultDict[@"original_title"];
                                                     tvShow.title = resultDict[@"title"];
                                                     tvShow.contentDescription = resultDict[@"overview"];
                                                     tvShow.releaseDate = [NSDate date]; // FIXME: insert correct date
                                                     tvShow.posterPath = resultDict[@"poster_path"];
                                                     tvShow.backdropPath = resultDict[@"backdrop_path"];
                                                     tvShow.movieDBID = [resultDict[@"id"] integerValue];
                                                 }
                                             }

                                             if (self.dataRecipient) {
                                                 if ([self.dataRecipient respondsToSelector:@selector(MDFMovieDBFetcher:didFindTVShow:forSearchRequest:)]) {
                                                     [self.dataRecipient MDFMovieDBFetcher:self
                                                                             didFindTVShow:tvShow forSearchRequest:originalSearchRequest];
                                                 }
                                             }
                                         } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                             @synchronized(_requests) {
                                                 [_requests removeObject:task];
                                             }

                                             if (self.dataRecipient) {
                                                 if ([self.dataRecipient respondsToSelector:@selector(MDFMovieDBFetcher:didFailToFindTVShowForSearchRequest:)]) {
                                                     [self.dataRecipient MDFMovieDBFetcher:self
                                                       didFailToFindTVShowForSearchRequest:originalSearchRequest];
                                                 }
                                             }
                                         }];
    @synchronized(_requests) {
        [_requests addObject:task];
    }
}

@end
