/*****************************************************************************
 * MDFHatchetFetcher.m
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

#import "MDFHatchetFetcher.h"
#import "MDFHatchetSessionManager.h"
#import "MDFArtist.h"
#import "MDFMusicAlbum.h"

@interface MDFHatchetFetcher ()
{
    NSMutableArray<NSURLSessionTask *> *_requests;
}
@end

@implementation MDFHatchetFetcher

- (NSString *)description
{
    NSString *ret;
    @synchronized(_requests) {
        ret = [NSString stringWithFormat:@"%s: %lu pending requests",
               __PRETTY_FUNCTION__,
               (unsigned long)_requests.count];
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

- (void)searchForArtist:(NSString *)artistName
{
    if (!artistName)
        return;

    MDFHatchetSessionManager *sessionManager = [MDFHatchetSessionManager sharedInstance];
    if (!sessionManager.apiKey)
        return;

    NSURLSessionTask *task = [sessionManager GET:@"artists" parameters:@{ @"name" : artistName }
                                         success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
                                             @synchronized(_requests) {
                                                 [_requests removeObject:task];
                                             }

                                             MDFArtist *artist;
                                             if (responseObject != nil) {
                                                 NSArray *artistsArray = responseObject[@"artists"];
                                                 NSArray *imagesArray = responseObject[@"images"];

                                                 if (artistsArray != nil) {
                                                     artist = [[MDFArtist alloc] init];
                                                     NSDictionary *artistDict = [artistsArray firstObject];
                                                     artist.hatchetArtistID = [artistDict[@"id"] integerValue];
                                                     artist.name = artistDict[@"name"];
                                                     artist.biography = artistDict[@"wikiabstract"];
                                                 }
                                                 if (imagesArray != nil) {
                                                     if (!artist)
                                                         artist = [[MDFArtist alloc] init];
                                                     NSMutableArray *mediumImages = [NSMutableArray array];
                                                     NSMutableArray *mediumPortraitImages = [NSMutableArray array];
                                                     NSMutableArray *mediumLandscapeImages = [NSMutableArray array];
                                                     NSMutableArray *largeImages = [NSMutableArray array];
                                                     NSMutableArray *largePortraitImages = [NSMutableArray array];
                                                     NSMutableArray *largeLandscapeImages = [NSMutableArray array];
                                                     NSUInteger imageCount = imagesArray.count;
                                                     for (NSUInteger x = 0; x < imageCount; x++) {
                                                         NSDictionary *imageDict = imagesArray[x];
                                                         NSInteger imageWidth = [imageDict[@"width"] integerValue];
                                                         NSInteger imageHeight = [imageDict[@"height"] integerValue];
                                                         NSString *imageURL = imageDict[@"url"];

                                                         if (imageWidth > 1000) {
                                                             [largeImages addObject:imageURL];
                                                             if (imageWidth > imageHeight) {
                                                                 [largeLandscapeImages addObject:imageURL];
                                                             } else {
                                                                 [largePortraitImages addObject:imageURL];
                                                             }
                                                         } else {
                                                             [mediumImages addObject:imageDict[@"url"]];
                                                             if (imageWidth > imageHeight) {
                                                                 [mediumLandscapeImages addObject:imageURL];
                                                             } else {
                                                                 [mediumPortraitImages addObject:imageURL];
                                                             }
                                                         }
                                                     }
                                                     artist.mediumSizedImages = [mediumImages copy];
                                                     artist.mediumSizedPortraitImages = [mediumPortraitImages copy];
                                                     artist.mediumSizedLandscapeImages = [mediumLandscapeImages copy];
                                                     artist.largeSizedImages = [largeImages copy];
                                                     artist.largeSizedPortraitImages = [largePortraitImages copy];
                                                     artist.largeSizedLandscapeImages = [largeLandscapeImages copy];
                                                 }
                                             }

                                             if (self.dataRecipient) {
                                                 if ([self.dataRecipient respondsToSelector:@selector(MDFHatchetFetcher:didFindArtist:forSearchRequest:)]) {
                                                     [self.dataRecipient MDFHatchetFetcher:self
                                                                             didFindArtist:artist
                                                                          forSearchRequest:artistName];
                                                 }
                                             }

                                         }
                                         failure:^(NSURLSessionDataTask *task, NSError *error) {
                                             @synchronized(_requests) {
                                                 [_requests removeObject:task];
                                             }
                                             if (self.dataRecipient) {
                                                 if ([self.dataRecipient respondsToSelector:@selector(MDFHatchetFetcher:didFailToFindArtistForSearchRequest:)]) {
                                                     [self.dataRecipient MDFHatchetFetcher:self didFailToFindArtistForSearchRequest:artistName];
                                                 }
                                             }
                                         }];
    @synchronized(_requests) {
        [_requests addObject:task];
    }
}

- (void)searchForAlbum:(NSString *)albumName ofArtist:(NSString *)artistName
{
    if (!artistName)
        return;
    if (!albumName)
        return;

    MDFHatchetSessionManager *sessionManager = [MDFHatchetSessionManager sharedInstance];
    if (!sessionManager.apiKey)
        return;

    NSURLSessionTask *task = [sessionManager GET:@"albums" parameters:@{ @"artist_name" : artistName,
                                                                         @"name" : albumName }
                                         success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
                                             @synchronized(_requests) {
                                                 [_requests removeObject:task];
                                             }

                                             MDFMusicAlbum *musicAlbum = [[MDFMusicAlbum alloc] init];
                                             MDFArtist *artist;
                                             if (responseObject != nil) {
                                                 NSArray *albumsArray = responseObject[@"albums"];
                                                 NSArray *imagesArray = responseObject[@"images"];
                                                 NSArray *artistsArray = responseObject[@"artists"];

                                                 NSInteger albumArtImageID = 0;
                                                 if (albumsArray != nil) {
                                                     NSDictionary *albumDict = [albumsArray firstObject];
                                                     musicAlbum.name = albumDict[@"name"];
                                                     musicAlbum.releaseDate = [NSDate date]; // FIXME: enter correct date from "releasedate" key
                                                     musicAlbum.hatchetAlbumID = [albumDict[@"id"] integerValue];
                                                     NSArray *albumImages = albumDict[@"images"];
                                                     if (albumImages != nil) {
                                                         if (albumImages.count > 0 ) {
                                                             albumArtImageID = [[albumImages firstObject] integerValue];
                                                         }
                                                     }
                                                 }

                                                 if (imagesArray != nil) {
                                                     NSUInteger imageCount = imagesArray.count;
                                                     NSMutableArray *mediumImages = [NSMutableArray array];
                                                     NSMutableArray *mediumPortraitImages = [NSMutableArray array];
                                                     NSMutableArray *mediumLandscapeImages = [NSMutableArray array];
                                                     NSMutableArray *largeImages = [NSMutableArray array];
                                                     NSMutableArray *largePortraitImages = [NSMutableArray array];
                                                     NSMutableArray *largeLandscapeImages = [NSMutableArray array];
                                                     for (NSUInteger x = 0; x < imageCount; x++) {
                                                         NSDictionary *imageDict = imagesArray[x];
                                                         if (albumArtImageID > 0) {
                                                             if ([imageDict[@"id"] integerValue] == albumArtImageID) {
                                                                 musicAlbum.artworkImage = imageDict[@"url"];
                                                                 albumArtImageID = 0; // speed-up the further processing
                                                                 continue;
                                                             }
                                                             NSMutableArray *mediumImages = [NSMutableArray array];
                                                             NSMutableArray *mediumPortraitImages = [NSMutableArray array];
                                                             NSMutableArray *mediumLandscapeImages = [NSMutableArray array];
                                                             NSMutableArray *largeImages = [NSMutableArray array];
                                                             NSMutableArray *largePortraitImages = [NSMutableArray array];
                                                             NSMutableArray *largeLandscapeImages = [NSMutableArray array];
                                                             NSUInteger imageCount = imagesArray.count;
                                                             for (NSUInteger x = 0; x < imageCount; x++) {
                                                                 NSDictionary *imageDict = imagesArray[x];
                                                                 NSInteger imageWidth = [imageDict[@"width"] integerValue];
                                                                 NSInteger imageHeight = [imageDict[@"height"] integerValue];
                                                                 NSString *imageURL = imageDict[@"url"];

                                                                 if (imageWidth > 1000) {
                                                                     [largeImages addObject:imageURL];
                                                                     if (imageWidth > imageHeight) {
                                                                         [largeLandscapeImages addObject:imageURL];
                                                                     } else {
                                                                         [largePortraitImages addObject:imageURL];
                                                                     }
                                                                 } else {
                                                                     [mediumImages addObject:imageDict[@"url"]];
                                                                     if (imageWidth > imageHeight) {
                                                                         [mediumLandscapeImages addObject:imageURL];
                                                                     } else {
                                                                         [mediumPortraitImages addObject:imageURL];
                                                                     }
                                                                 }
                                                             }
                                                         }
                                                         musicAlbum.mediumSizedArtistImages = [mediumImages copy];
                                                         musicAlbum.mediumSizedPortraitArtistImages = [mediumPortraitImages copy];
                                                         musicAlbum.mediumSizedLandscapeArtistImages = [mediumLandscapeImages copy];
                                                         musicAlbum.largeSizedArtistImages = [largeImages copy];
                                                         musicAlbum.largeSizedPortraitArtistImages = [largePortraitImages copy];
                                                         musicAlbum.largeSizedLandscapeArtistImages = [largeLandscapeImages copy];
                                                     }
                                                 }

                                                 if (artistsArray != nil) {
                                                     NSDictionary *artistDict = [artistsArray firstObject];
                                                     artist = [[MDFArtist alloc] init];
                                                     artist.name = artistDict[@"name"];
                                                     artist.hatchetArtistID = [artistDict[@"id"] integerValue];
                                                     artist.biography = artistDict[@"wikiabstract"];
                                                 }



                                                 if (self.dataRecipient) {
                                                     if ([self.dataRecipient respondsToSelector:@selector(MDFHatchetFetcher:didFindAlbum:byArtist:forSearchRequest:)]) {
                                                         [self.dataRecipient MDFHatchetFetcher:self
                                                                                  didFindAlbum:musicAlbum
                                                                                      byArtist:artist
                                                                              forSearchRequest:artistName];
                                                     }
                                                 }
                                             }
                                         }
                                         failure:^(NSURLSessionDataTask *task, NSError *error) {
                                             @synchronized(_requests) {
                                                 [_requests removeObject:task];
                                             }
                                             if (self.dataRecipient) {
                                                 if ([self.dataRecipient respondsToSelector:@selector(MDFHatchetFetcher:didFailToFindAlbum:forArtistName:)]) {
                                                     [self.dataRecipient MDFHatchetFetcher:self
                                                                        didFailToFindAlbum:albumName
                                                                             forArtistName:artistName];
                                                 }
                                             }
                                         }];
    @synchronized(_requests) {
        [_requests addObject:task];
    }
}

@end
