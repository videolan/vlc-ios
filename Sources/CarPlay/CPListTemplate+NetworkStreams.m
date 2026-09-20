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
#import "VLCCarPlayBrowserController.h"
#import "VLCPlaybackService.h"
#import "VLCFavoriteService.h"
#import "VLCRadioService.h"
#import "VLCThumbnailsCache.h"
#import "VLCAppCoordinator.h"

@implementation CPListTemplate (NetworkStreams)

+ (CPListTemplate *)streamList
{
    CPListTemplate *template = [[CPListTemplate alloc] initWithTitle:NSLocalizedString(@"STREAMS", nil)
                                                            sections:[self streamSections]];
    template.tabTitle = NSLocalizedString(@"STREAMS", nil);
    template.tabImage = [UIImage systemImageNamed:@"antenna.radiowaves.left.and.right"];
    return template;
}

+ (NSArray<CPListSection *> *)streamSections
{
    NSUInteger remainingItemCount = [VLCCarPlayBrowserController maximumItemCount];
    NSMutableArray<CPListSection *> *sections = [[NSMutableArray alloc] initWithCapacity:3];

    VLCFavoriteService *favoriteService = [VLCAppCoordinator sharedInstance].favoriteService;
    NSArray *radioStations = [self listOfRadioStations:[favoriteService favoritesInGroupWithIdentifier:VLCFavoriteGroupRadio]
                                             withLimit:remainingItemCount];
    if (radioStations.count > 0) {
        [sections addObject:[[CPListSection alloc] initWithItems:radioStations
                                                          header:NSLocalizedString(@"RADIO", nil)
                                               sectionIndexTitle:nil]];
        remainingItemCount -= radioStations.count;
    }

    VLCRadioService *radioService = [VLCAppCoordinator sharedInstance].radioService;
    NSArray *recentStations = [self listOfRadioStations:radioService.recentStreams
                                              withLimit:remainingItemCount];
    if (recentStations.count > 0) {
        [sections addObject:[[CPListSection alloc] initWithItems:recentStations
                                                          header:NSLocalizedString(@"RECENTS", nil)
                                               sectionIndexTitle:nil]];
        remainingItemCount -= recentStations.count;
    }

    NSArray *recentStreams = [self listOfNetworkStreamsWithLimit:remainingItemCount];
    if (recentStreams.count > 0) {
        [sections addObject:[[CPListSection alloc] initWithItems:recentStreams
                                                          header:NSLocalizedString(@"RECENT_STREAMS", nil)
                                               sectionIndexTitle:nil]];
    }

    return sections;
}

+ (CPListItem *)listItemForFavorite:(VLCFavorite *)favorite image:(UIImage *)image
{
    CPListItem *listItem = [[CPListItem alloc] initWithText:favorite.userVisibleName
                                                 detailText:favorite.url.host
                                                      image:image];
    listItem.handler = ^(id <CPSelectableListItem> item,
                         dispatch_block_t completionBlock) {
        VLCAppCoordinator *coordinator = [VLCAppCoordinator sharedInstance];
        [coordinator.favoriteService playFavorite:favorite];
        [coordinator.radioService markStreamPlayed:favorite];
        completionBlock();
    };
    return listItem;
}

+ (CPListItem *)listItemForStreamURL:(NSURL *)url
                               title:(NSString *)title
                          detailText:(nullable NSString *)detailText
                               image:(UIImage *)image
{
    CPListItem *listItem = [[CPListItem alloc] initWithText:title
                                                 detailText:detailText
                                                      image:image];
    listItem.handler = ^(id <CPSelectableListItem> item,
                         dispatch_block_t completionBlock) {
        VLCMedia *media = [VLCMedia mediaWithURL:url];
        media.metaData.title = title;
        VLCMediaList *medialist = [[VLCMediaList alloc] init];
        [medialist addMedia:media];

        [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
        completionBlock();
    };
    return listItem;
}

+ (NSArray *)listOfRadioStations:(NSArray<VLCFavorite *> *)stations withLimit:(NSUInteger)limit
{
    NSUInteger count = MIN(stations.count, limit);
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    NSString *symbol = @"antenna.radiowaves.left.and.right";
    if (@available(iOS 16.0, *)) {
        symbol = @"radio";
    }
    UIImage *radioIcon = [VLCCarPlayBrowserController placeholderForSymbol:symbol];

    for (NSUInteger x = 0; x < count; x++) {
        VLCFavorite *favorite = stations[x];
        if (!favorite.playable) {
            continue;
        }

        CPListItem *listItem = [self listItemForFavorite:favorite image:radioIcon];
        NSURL *artworkURL = favorite.artworkURL;
        if (artworkURL) {
            [self setArtworkFromURL:artworkURL onListItem:listItem];
        }

        [itemList addObject:listItem];
    }

    return itemList;
}

+ (UIImage *)artworkScaledToIconSize:(UIImage *)artwork
{
    CGSize iconSize = [VLCCarPlayBrowserController listItemIconSize];
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:iconSize];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        CGSize artworkSize = artwork.size;
        CGFloat scale = MIN(iconSize.width / artworkSize.width, iconSize.height / artworkSize.height);
        CGSize scaledSize = CGSizeMake(artworkSize.width * scale, artworkSize.height * scale);
        [artwork drawInRect:CGRectMake((iconSize.width - scaledSize.width) / 2.0,
                                       (iconSize.height - scaledSize.height) / 2.0,
                                       scaledSize.width, scaledSize.height)];
    }];
}

+ (void)setArtworkFromURL:(NSURL *)artworkURL onListItem:(CPListItem *)listItem
{
    UIImage *cachedArtwork = [VLCThumbnailsCache cachedImageForURL:artworkURL];
    if (cachedArtwork) {
        [listItem setImage:[self artworkScaledToIconSize:cachedArtwork]];
        return;
    }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:artworkURL
                                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        if (error || (httpResponse && httpResponse.statusCode != 200)) {
            return;
        }

        UIImage *artwork = [VLCThumbnailsCache imageFromData:data forURL:artworkURL maxPixelSize:0.];
        if (!artwork) {
            return;
        }

        UIImage *scaledArtwork = [self artworkScaledToIconSize:artwork];
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

    UIImage *streamIcon = [VLCCarPlayBrowserController placeholderForSymbol:@"antenna.radiowaves.left.and.right"];

    for (NSUInteger x = 0; x < count; x++) {
        NSString *recentURLString = recentURLs[x];
        NSString *content = [recentURLString stringByRemovingPercentEncoding];
        NSString *possibleTitle = recentURLTitles[@(x).stringValue];

        [itemList addObject:[self listItemForStreamURL:[NSURL URLWithString:recentURLString]
                                                 title:possibleTitle ?: [content lastPathComponent]
                                            detailText:content
                                                 image:streamIcon]];
    }

    return itemList;
}

@end
