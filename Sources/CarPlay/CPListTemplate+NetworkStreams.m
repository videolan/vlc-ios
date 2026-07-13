/*****************************************************************************
 * CPListTemplate+NetworkStreams.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022, 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "CPListTemplate+NetworkStreams.h"
#import "VLCCarPlayListLimit.h"
#import "UIImage+PaddedImage.h"
#import "VLCPlaybackService.h"
#import "VLCFavoriteService.h"
#import "VLCAppCoordinator.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@implementation CPListTemplate (NetworkStreams)

+ (CPListTemplate *)streamList
{
    NSUInteger remainingItemCount = VLCCarPlayMaximumItemCountLimit();
    NSMutableArray<CPListSection *> *sections = [[NSMutableArray alloc] initWithCapacity:2];

    NSArray *radioStations = [self listOfFavoritedRadioStationsWithLimit:remainingItemCount];
    if (radioStations.count > 0) {
        [sections addObject:[[CPListSection alloc] initWithItems:radioStations
                                                          header:NSLocalizedString(@"RADIO", nil)
                                               sectionIndexTitle:nil]];
        remainingItemCount -= radioStations.count;
    }

    NSArray *recentStreams = [self listOfNetworkStreamsWithLimit:remainingItemCount];
    if (recentStreams.count > 0) {
        [sections addObject:[[CPListSection alloc] initWithItems:recentStreams
                                                          header:NSLocalizedString(@"RECENT_STREAMS", nil)
                                               sectionIndexTitle:nil]];
    }

    CPListTemplate *template = [[CPListTemplate alloc] initWithTitle:NSLocalizedString(@"STREAMS", nil)
                                                            sections:sections];
    template.tabTitle = NSLocalizedString(@"STREAMS", nil);
    template.tabImage = [UIImage systemImageNamed:@"antenna.radiowaves.left.and.right"];
    return template;
}

+ (CGSize)listItemIconSize
{
    if (@available(iOS 14.0, *)) {
        return [CPListItem maximumImageSize];
    }
    return CGSizeMake(80.0, 80.0);
}

+ (CPListItem *)listItemWithTitle:(NSString *)title
                       detailText:(nullable NSString *)detailText
                            image:(UIImage *)image
                              URL:(NSURL *)url
{
    CPListItem *listItem = [[CPListItem alloc] initWithText:title
                                                 detailText:detailText
                                                      image:image];
    listItem.userInfo = url;
    listItem.handler = ^(id <CPSelectableListItem> item,
                         dispatch_block_t completionBlock) {
        VLCMedia *media = [VLCMedia mediaWithURL:item.userInfo];
        VLCMediaList *medialist = [[VLCMediaList alloc] init];
        [medialist addMedia:media];

        [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
        completionBlock();
    };
    return listItem;
}

+ (NSArray *)listOfFavoritedRadioStationsWithLimit:(NSUInteger)limit
{
    VLCFavoriteService *favoriteService = [VLCAppCoordinator sharedInstance].favoriteService;
    NSArray<VLCFavorite *> *favorites = [favoriteService favoritesInGroupWithIdentifier:VLCFavoriteGroupRadio];
    NSUInteger count = MIN(favorites.count, limit);
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    NSString *symbol = @"antenna.radiowaves.left.and.right";
    if (@available(iOS 16.0, *)) {
        symbol = @"radio";
    }
    UIImage *radioIcon = [UIImage paddedImageForSymbol:symbol ofSize:[self listItemIconSize]];

    for (NSUInteger x = 0; x < count; x++) {
        VLCFavorite *favorite = favorites[x];
        if (!favorite.playable) {
            continue;
        }

        CPListItem *listItem = [self listItemWithTitle:favorite.userVisibleName
                                            detailText:favorite.url.host
                                                 image:radioIcon
                                                   URL:favorite.url];
        NSURL *artworkURL = favorite.artworkURL;
        if (artworkURL) {
            if (@available(iOS 14.0, *)) {
                [self setArtworkFromURL:artworkURL onListItem:listItem];
            }
        }

        [itemList addObject:listItem];
    }

    return itemList;
}

+ (void)setArtworkFromURL:(NSURL *)artworkURL onListItem:(CPListItem *)listItem API_AVAILABLE(ios(14.0))
{
    CGSize iconSize = [self listItemIconSize];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:artworkURL
                                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        if (error || (httpResponse && httpResponse.statusCode != 200)) {
            return;
        }

        UIImage *artwork = data ? [UIImage imageWithData:data] : nil;
        if (!artwork) {
            return;
        }

        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:iconSize];
        UIImage *scaledArtwork = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
            CGSize artworkSize = artwork.size;
            CGFloat scale = MIN(iconSize.width / artworkSize.width, iconSize.height / artworkSize.height);
            CGSize scaledSize = CGSizeMake(artworkSize.width * scale, artworkSize.height * scale);
            [artwork drawInRect:CGRectMake((iconSize.width - scaledSize.width) / 2.0,
                                           (iconSize.height - scaledSize.height) / 2.0,
                                           scaledSize.width, scaledSize.height)];
        }];

        dispatch_async(dispatch_get_main_queue(), ^{
            [listItem setImage:scaledArtwork];
        });
    }];
    [task resume];
}

+ (NSArray *)listOfNetworkStreamsWithLimit:(NSUInteger)limit
{
    NSArray *recentURLs;
    NSDictionary *recentURLTitles;

    if ([[NSFileManager defaultManager] ubiquityIdentityToken] != nil) {
        /* force store update */
        NSUbiquitousKeyValueStore *ubiquitousKeyValueStore = [NSUbiquitousKeyValueStore defaultStore];
        [ubiquitousKeyValueStore synchronize];

        /* fetch data from cloud */
        recentURLs = [ubiquitousKeyValueStore arrayForKey:kVLCRecentURLs];
        recentURLTitles = [ubiquitousKeyValueStore dictionaryForKey:kVLCRecentURLTitles];
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        recentURLs = [defaults objectForKey:kVLCRecentURLs];
        recentURLTitles = [defaults objectForKey:kVLCRecentURLTitles];
    }

    NSUInteger count = MIN(recentURLs.count, limit);
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    UIImage *streamIcon = [UIImage paddedImageForSymbol:@"antenna.radiowaves.left.and.right" ofSize:[self listItemIconSize]];

    for (NSUInteger x = 0; x < count; x++) {
        NSString *recentURLString = recentURLs[x];
        NSString *content = [recentURLString stringByRemovingPercentEncoding];
        NSString *possibleTitle = recentURLTitles[@(x).stringValue];

        [itemList addObject:[self listItemWithTitle:possibleTitle ?: [content lastPathComponent]
                                         detailText:content
                                              image:streamIcon
                                                URL:[NSURL URLWithString:recentURLString]]];
    }

    return itemList;
}

@end

#pragma clang diagnostic pop
