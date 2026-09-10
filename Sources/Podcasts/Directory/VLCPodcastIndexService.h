/*****************************************************************************
 * VLCPodcastIndexService.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define kVLCPodcastIndexAPIKey @""
#define kVLCPodcastIndexAPISecret @""
#define kVLCPodcastIndexLanguage @"kVLCPodcastIndexLanguage"

FOUNDATION_EXPORT NSString *const VLCPodcastIndexShelvesDidUpdateNotification;

@interface VLCPodcastIndexFeed : NSObject <NSCoding>

@property (readonly) NSInteger feedIdentifier;
@property (readonly) NSURL *feedURL;
@property (readonly) NSString *title;
@property (readonly, nullable) NSString *author;
@property (readonly, nullable) NSURL *artworkURL;
@property (readonly, nullable) NSString *language;
@property (readonly) NSArray<NSString *> *categories;
@property (readonly, nullable) NSString *summary;
@property (readonly, nullable) NSURL *websiteURL;
@property (readonly, nullable) NSDate *lastUpdateDate;
@property (readonly) NSInteger episodeCount;
@property (readonly, getter=isExplicit) BOOL explicit;
@property (readonly, nullable) NSString *subtitle;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface VLCPodcastIndexShelf : NSObject <NSCoding>

@property (readonly) NSString *title;
@property (readonly, nullable) NSString *category;
@property (readonly) NSArray<VLCPodcastIndexFeed *> *feeds;

- (instancetype)init NS_UNAVAILABLE;

@end

typedef void (^VLCPodcastIndexFeedsCompletion)(NSArray<VLCPodcastIndexFeed *> *feeds, NSError *_Nullable error);
typedef void (^VLCPodcastIndexFeedCompletion)(VLCPodcastIndexFeed *_Nullable feed, NSError *_Nullable error);

@interface VLCPodcastIndexService : NSObject

@property (class, readonly, getter=isAvailable) BOOL available;

@property (readonly) NSArray<NSString *> *availableLanguageCodes;
@property (nonatomic, copy) NSString *languageCode;

@property (readonly) NSArray<VLCPodcastIndexShelf *> *shelves;
@property (readonly, getter=isLoading) BOOL loading;

- (void)loadShelvesIfNeeded;
- (void)reloadShelves;

- (void)loadTrendingForCategory:(NSString *)category
                     completion:(VLCPodcastIndexFeedsCompletion)completion;
- (nullable NSURLSessionTask *)searchFeedsMatching:(NSString *)query
                                        completion:(VLCPodcastIndexFeedsCompletion)completion;
- (void)loadDetailsForFeed:(VLCPodcastIndexFeed *)feed
                completion:(VLCPodcastIndexFeedCompletion)completion;

+ (NSArray<NSString *> *)localizedTitlesForCategoryNames:(NSArray<NSString *> *)names;

@end

NS_ASSUME_NONNULL_END
