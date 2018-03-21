/*****************************************************************************
 * MDFMovieDBSessionManager.m
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

#import "MDFMovieDBSessionManager.h"

static NSString * const MovieDBBaseURLString = @"https://api.themoviedb.org/3/";

@implementation MDFMovieDBSessionManager

+ (instancetype)sharedInstance
{
    static MDFMovieDBSessionManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[MDFMovieDBSessionManager alloc] initWithBaseURL:[NSURL URLWithString:MovieDBBaseURLString]];
        _sharedClient.requestSerializer = [AFJSONRequestSerializer serializer];

        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        securityPolicy.validatesDomainName = NO;
        securityPolicy.allowInvalidCertificates = YES;
        _sharedClient.securityPolicy = securityPolicy;
    });

    return _sharedClient;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%s: fetched Properties: %i", __PRETTY_FUNCTION__, _hasFetchedProperties];
}

- (void)fetchProperties
{
    if (!self.apiKey)
        return;

    [self GET:@"configuration" parameters:@{ @"api_key" : self.apiKey}
      success:^(NSURLSessionDataTask * __unused task, NSDictionary * responseObject) {
          NSDictionary *images = responseObject[@"images"];
          if (images != nil) {
              _secureImageBaseURL = images[@"secure_base_url"];
              _imageBaseURL = images[@"base_url"];
              _backdropSizes = images[@"backdrop_sizes"];
              _logoSizes = images[@"logo_sizes"];
              _posterSizes = images[@"poster_sizes"];
              _profileSizes = images[@"profile_sizes"];
              _stillSizes = images[@"still_sizes"];
              _hasFetchedProperties = YES;
          }
      } failure:^(NSURLSessionDataTask * __unused task, NSError *error) {
          NSLog(@"%@", error);
          _hasFetchedProperties = NO;
      }];
}

@end
