/*****************************************************************************
 * VLCPodcastIndexService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPodcastIndexService.h"
#import "VLCHTTPClient.h"

#import <CommonCrypto/CommonDigest.h>

NSString *const VLCPodcastIndexShelvesDidUpdateNotification = @"VLCPodcastIndexShelvesDidUpdateNotification";

static NSString *const VLCPodcastIndexBaseURL = @"https://api.podcastindex.org/api/1.0/";
static NSString *const VLCPodcastIndexFile = @"PodcastIndex.plist";
static NSString *const VLCPodcastIndexVersionKey = @"version";
static NSString *const VLCPodcastIndexShelvesKey = @"shelves";
static NSString *const VLCPodcastIndexFetchDateKey = @"fetchDate";
static NSString *const VLCPodcastIndexLanguageKey = @"language";

static NSInteger const kVLCPodcastIndexCacheVersion = 1;
static NSTimeInterval const kVLCPodcastIndexCacheTimeout = 6 * 60 * 60;
static NSUInteger const kVLCPodcastIndexShelfLimit = 25;
static NSUInteger const kVLCPodcastIndexChartLimit = 50;
static NSUInteger const kVLCPodcastIndexListLimit = 100;
static NSUInteger const kVLCPodcastIndexTitleMatchLimit = 25;
static NSUInteger const kVLCPodcastIndexCategoryBatch = 4;

@interface VLCPodcastIndexFeed ()

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

@interface VLCPodcastIndexShelf ()

- (instancetype)initWithTitle:(NSString *)title
                     category:(nullable NSString *)category
                        feeds:(NSArray<VLCPodcastIndexFeed *> *)feeds;

@end

@implementation VLCPodcastIndexFeed

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    NSString *url = dictionary[@"url"];
    NSString *title = dictionary[@"title"];
    if (![url isKindOfClass:[NSString class]] || ![title isKindOfClass:[NSString class]]) {
        return nil;
    }

    NSURL *feedURL = [NSURL URLWithString:url];
    if (!feedURL.scheme || !feedURL.host) {
        return nil;
    }

    self = [super init];
    if (self) {
        _feedIdentifier = [dictionary[@"id"] integerValue];
        _feedURL = feedURL;
        _title = [title copy];

        NSString *author = dictionary[@"author"];
        _author = [author isKindOfClass:[NSString class]] && author.length > 0 ? [author copy] : nil;

        NSString *language = dictionary[@"language"];
        _language = [language isKindOfClass:[NSString class]] && language.length > 0 ? [language copy] : nil;

        NSString *artwork = dictionary[@"artwork"];
        if (![artwork isKindOfClass:[NSString class]] || artwork.length == 0) {
            artwork = dictionary[@"image"];
        }
        _artworkURL = [artwork isKindOfClass:[NSString class]] && artwork.length > 0 ? [NSURL URLWithString:artwork] : nil;

        NSDictionary *categories = dictionary[@"categories"];
        _categories = [categories isKindOfClass:[NSDictionary class]] ? [categories.allValues copy] : @[];

        NSString *summary = dictionary[@"description"];
        _summary = [summary isKindOfClass:[NSString class]] && summary.length > 0 ? [summary copy] : nil;

        NSString *link = dictionary[@"link"];
        _websiteURL = [link isKindOfClass:[NSString class]] && link.length > 0 ? [NSURL URLWithString:link] : nil;

        NSNumber *lastUpdate = dictionary[@"lastUpdateTime"];
        if (![lastUpdate isKindOfClass:[NSNumber class]]) {
            lastUpdate = dictionary[@"newestItemPublishTime"];
        }
        _lastUpdateDate = [lastUpdate isKindOfClass:[NSNumber class]] && lastUpdate.doubleValue > 0
            ? [NSDate dateWithTimeIntervalSince1970:lastUpdate.doubleValue] : nil;

        _episodeCount = [dictionary[@"episodeCount"] integerValue];
        _explicit = [dictionary[@"explicit"] boolValue];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _feedIdentifier = [coder decodeIntegerForKey:@"feedIdentifier"];
        _feedURL = [coder decodeObjectForKey:@"feedURL"];
        _title = [coder decodeObjectForKey:@"title"];
        _author = [coder decodeObjectForKey:@"author"];
        _artworkURL = [coder decodeObjectForKey:@"artworkURL"];
        _language = [coder decodeObjectForKey:@"language"];
        _categories = [coder decodeObjectForKey:@"categories"] ?: @[];
        _summary = [coder decodeObjectForKey:@"summary"];
        _websiteURL = [coder decodeObjectForKey:@"websiteURL"];
        _lastUpdateDate = [coder decodeObjectForKey:@"lastUpdateDate"];
        _episodeCount = [coder decodeIntegerForKey:@"episodeCount"];
        _explicit = [coder decodeBoolForKey:@"explicit"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:_feedIdentifier forKey:@"feedIdentifier"];
    [coder encodeObject:_feedURL forKey:@"feedURL"];
    [coder encodeObject:_title forKey:@"title"];
    [coder encodeObject:_author forKey:@"author"];
    [coder encodeObject:_artworkURL forKey:@"artworkURL"];
    [coder encodeObject:_language forKey:@"language"];
    [coder encodeObject:_categories forKey:@"categories"];
    [coder encodeObject:_summary forKey:@"summary"];
    [coder encodeObject:_websiteURL forKey:@"websiteURL"];
    [coder encodeObject:_lastUpdateDate forKey:@"lastUpdateDate"];
    [coder encodeInteger:_episodeCount forKey:@"episodeCount"];
    [coder encodeBool:_explicit forKey:@"explicit"];
}

- (NSString *)subtitle
{
    if (_author) {
        return _author;
    }

    NSArray<NSString *> *categories = [VLCPodcastIndexService localizedTitlesForCategoryNames:_categories];
    return categories.count > 0 ? [categories componentsJoinedByString:@" · "] : nil;
}

@end

@implementation VLCPodcastIndexShelf

- (instancetype)initWithTitle:(NSString *)title
                     category:(NSString *)category
                        feeds:(NSArray<VLCPodcastIndexFeed *> *)feeds
{
    self = [super init];
    if (self) {
        _title = [title copy];
        _category = [category copy];
        _feeds = feeds;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _title = [coder decodeObjectForKey:@"title"];
        _category = [coder decodeObjectForKey:@"category"];
        _feeds = [coder decodeObjectForKey:@"feeds"] ?: @[];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_title forKey:@"title"];
    [coder encodeObject:_category forKey:@"category"];
    [coder encodeObject:_feeds forKey:@"feeds"];
}

@end

@implementation VLCPodcastIndexService
{
    VLCHTTPClient *_client;
    NSString *_filePath;
    NSDate *_fetchDate;
    NSArray<VLCPodcastIndexFeed *> *_chartFeeds;
    NSArray<VLCPodcastIndexFeed *> *_recentFeeds;
    NSArray<NSString *> *_shelfCategories;
    NSMutableDictionary<NSString *, VLCPodcastIndexShelf *> *_categoryShelves;
}

+ (BOOL)isAvailable
{
    return kVLCPodcastIndexAPIKey.length > 0 && kVLCPodcastIndexAPISecret.length > 0;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _filePath = [[paths firstObject] stringByAppendingPathComponent:VLCPodcastIndexFile];

        _client = [[VLCHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:VLCPodcastIndexBaseURL]];
        _shelves = @[];
        _languageCode = [self storedLanguageCode];

        [self loadContent];
    }
    return self;
}

#pragma mark - languages

+ (NSDictionary<NSString *, NSArray<NSString *> *> *)regionalVariants
{
    static NSDictionary *variants;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *collected = [NSMutableDictionary dictionary];

        for (NSString *identifier in [NSLocale availableLocaleIdentifiers]) {
            NSDictionary *components = [NSLocale componentsFromLocaleIdentifier:identifier];
            NSString *language = components[NSLocaleLanguageCode];
            if (language.length == 0) {
                continue;
            }

            NSMutableSet *regions = collected[language];
            if (!regions) {
                regions = [NSMutableSet set];
                collected[language] = regions;
            }

            NSString *country = components[NSLocaleCountryCode];
            if (country.length > 0) {
                [regions addObject:[NSString stringWithFormat:@"%@-%@", language, country.lowercaseString]];
            }
        }

        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:collected.count];
        [collected enumerateKeysAndObjectsUsingBlock:^(NSString *language, NSMutableSet *regions, BOOL *stop) {
            result[language] = [regions.allObjects sortedArrayUsingSelector:@selector(compare:)];
        }];
        variants = result;
    });
    return variants;
}

- (NSArray<NSString *> *)availableLanguageCodes
{
    NSLocale *locale = [NSLocale currentLocale];
    NSMutableDictionary<NSString *, NSString *> *names = [NSMutableDictionary dictionary];

    for (NSString *code in [VLCPodcastIndexService regionalVariants]) {
        NSString *name = [locale localizedStringForLanguageCode:code];
        if (name.length > 0 && ![name isEqualToString:code]) {
            names[code] = name;
        }
    }

    return [names.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        return [names[a] localizedCaseInsensitiveCompare:names[b]];
    }];
}

- (NSString *)storedLanguageCode
{
    NSString *stored = [[NSUserDefaults standardUserDefaults] stringForKey:kVLCPodcastIndexLanguage];
    if (stored.length > 0) {
        return stored;
    }

    NSString *preferred = [[NSLocale preferredLanguages] firstObject];
    NSString *code = [[NSLocale componentsFromLocaleIdentifier:preferred] objectForKey:NSLocaleLanguageCode];
    return code.length > 0 ? code : @"en";
}

- (void)setLanguageCode:(NSString *)languageCode
{
    if (languageCode.length == 0 || [languageCode isEqualToString:_languageCode]) {
        return;
    }

    _languageCode = [languageCode copy];
    [[NSUserDefaults standardUserDefaults] setObject:_languageCode forKey:kVLCPodcastIndexLanguage];

    _shelves = @[];
    _fetchDate = nil;
    [self reloadShelves];
}

- (NSString *)languageQuery
{
    NSArray<NSString *> *variants = [VLCPodcastIndexService regionalVariants][_languageCode];
    return [[@[_languageCode] arrayByAddingObjectsFromArray:variants ?: @[]] componentsJoinedByString:@","];
}

#pragma mark - persistence

- (void)loadContent
{
    NSData *data = [[NSData alloc] initWithContentsOfFile:_filePath];
    if (data == nil) {
        return;
    }

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:nil];
    unarchiver.requiresSecureCoding = NO;
    NSDictionary *content = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
    if (![content isKindOfClass:[NSDictionary class]]) {
        return;
    }

    if ([content[VLCPodcastIndexVersionKey] integerValue] != kVLCPodcastIndexCacheVersion) {
        return;
    }

    if (![content[VLCPodcastIndexLanguageKey] isEqualToString:_languageCode]) {
        return;
    }

    NSArray *shelves = content[VLCPodcastIndexShelvesKey];
    if ([shelves isKindOfClass:[NSArray class]]) {
        _shelves = shelves;
        _fetchDate = content[VLCPodcastIndexFetchDateKey];
    }
}

- (void)persist
{
    NSMutableDictionary *content = [NSMutableDictionary dictionaryWithDictionary:
                                    @{ VLCPodcastIndexVersionKey: @(kVLCPodcastIndexCacheVersion),
                                       VLCPodcastIndexLanguageKey: _languageCode,
                                       VLCPodcastIndexShelvesKey: _shelves }];
    if (_fetchDate) {
        content[VLCPodcastIndexFetchDateKey] = _fetchDate;
    }

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:content requiringSecureCoding:NO error:nil];
    [data writeToFile:_filePath atomically:YES];
}

#pragma mark - requests

- (NSDictionary<NSString *, NSString *> *)authenticationHeaders
{
    NSString *timestamp = @((SInt64)[NSDate date].timeIntervalSince1970).stringValue;
    NSString *payload = [NSString stringWithFormat:@"%@%@%@", kVLCPodcastIndexAPIKey, kVLCPodcastIndexAPISecret, timestamp];
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];

    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(payloadData.bytes, (CC_LONG)payloadData.length, digest);

    NSMutableString *signature = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [signature appendFormat:@"%02x", digest[i]];
    }

    return @{ @"X-Auth-Date": timestamp,
              @"X-Auth-Key": kVLCPodcastIndexAPIKey,
              @"Authorization": signature };
}

+ (NSArray<VLCPodcastIndexFeed *> *)feedsFromResponse:(NSDictionary *)response
{
    NSArray *rawFeeds = response[@"feeds"];
    if (![rawFeeds isKindOfClass:[NSArray class]]) {
        return @[];
    }

    NSMutableArray<VLCPodcastIndexFeed *> *feeds = [NSMutableArray arrayWithCapacity:rawFeeds.count];
    for (NSDictionary *rawFeed in rawFeeds) {
        if (![rawFeed isKindOfClass:[NSDictionary class]]) {
            continue;
        }

        VLCPodcastIndexFeed *feed = [[VLCPodcastIndexFeed alloc] initWithDictionary:rawFeed];
        if (feed) {
            [feeds addObject:feed];
        }
    }
    return feeds;
}

- (NSDictionary *)parametersForCategory:(NSString *)category limit:(NSUInteger)limit
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{ @"max": @(limit),
                                                                                      @"lang": [self languageQuery] }];
    if (category) {
        parameters[@"cat"] = category;
    }
    return parameters;
}

- (NSURLSessionTask *)requestPath:(NSString *)path
                       parameters:(NSDictionary *)parameters
                       completion:(VLCPodcastIndexFeedsCompletion)completion
{
    return [_client GET:path
             parameters:parameters
                headers:[self authenticationHeaders]
                success:^(NSDictionary *jsonResponse) {
        completion([VLCPodcastIndexService feedsFromResponse:jsonResponse], nil);
    }
                failure:^(NSError *error) {
        APLog(@"podcast index: %@ failed with %@", path, error.localizedDescription);
        completion(@[], error);
    }];
}

- (void)loadTrendingForCategory:(NSString *)category
                     completion:(VLCPodcastIndexFeedsCompletion)completion
{
    if (!VLCPodcastIndexService.isAvailable) {
        return;
    }

    [self requestPath:@"podcasts/trending"
           parameters:[self parametersForCategory:category limit:kVLCPodcastIndexListLimit]
           completion:completion];
}

- (NSURLSessionTask *)searchFeedsMatching:(NSString *)query
                               completion:(VLCPodcastIndexFeedsCompletion)completion
{
    if (!VLCPodcastIndexService.isAvailable) {
        return nil;
    }

    return [self requestPath:@"search/byterm"
                  parameters:@{ @"q": query, @"max": @(kVLCPodcastIndexListLimit), @"similar": [NSNull null] }
                  completion:completion];
}

- (void)loadDetailsForFeed:(VLCPodcastIndexFeed *)feed
                completion:(VLCPodcastIndexFeedCompletion)completion
{
    if (!VLCPodcastIndexService.isAvailable) {
        return;
    }

    [self requestPath:@"search/bytitle"
           parameters:@{ @"q": feed.title, @"max": @(kVLCPodcastIndexTitleMatchLimit), @"fulltext": [NSNull null] }
           completion:^(NSArray<VLCPodcastIndexFeed *> *feeds, NSError *error) {
        for (VLCPodcastIndexFeed *candidate in feeds) {
            if (candidate.feedIdentifier == feed.feedIdentifier) {
                completion(candidate, nil);
                return;
            }
        }

        [self loadRecordForFeed:feed completion:completion];
    }];
}

- (void)loadRecordForFeed:(VLCPodcastIndexFeed *)feed
               completion:(VLCPodcastIndexFeedCompletion)completion
{
    [_client GET:@"podcasts/byfeedid"
      parameters:@{ @"id": @(feed.feedIdentifier) }
         headers:[self authenticationHeaders]
         success:^(NSDictionary *jsonResponse) {
        NSDictionary *rawFeed = jsonResponse[@"feed"];
        if (![rawFeed isKindOfClass:[NSDictionary class]]) {
            completion(nil, nil);
            return;
        }

        completion([[VLCPodcastIndexFeed alloc] initWithDictionary:rawFeed], nil);
    }
         failure:^(NSError *error) {
        APLog(@"podcast index: podcasts/byfeedid failed with %@", error.localizedDescription);
        completion(nil, error);
    }];
}

#pragma mark - shelves

- (void)loadShelvesIfNeeded
{
    BOOL isFresh = _shelves.count > 0 && _fetchDate
        && [[NSDate date] timeIntervalSinceDate:_fetchDate] < kVLCPodcastIndexCacheTimeout;
    if (self.isLoading || isFresh) {
        [self postUpdate];
        return;
    }

    [self reloadShelves];
}

- (void)reloadShelves
{
    if (!VLCPodcastIndexService.isAvailable) {
        [self postUpdate];
        return;
    }

    _loading = YES;
    [self postUpdate];

    [self fetchOverviewShelves];
}

- (void)fetchOverviewShelves
{
    _chartFeeds = @[];
    _recentFeeds = @[];
    _categoryShelves = [NSMutableDictionary dictionary];

    dispatch_group_t group = dispatch_group_create();

    dispatch_group_enter(group);
    [self requestPath:@"podcasts/trending"
           parameters:[self parametersForCategory:nil limit:kVLCPodcastIndexChartLimit]
           completion:^(NSArray<VLCPodcastIndexFeed *> *feeds, NSError *error) {
        if (self.isLoading) {
            self->_chartFeeds = feeds;
        }
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [self requestPath:@"recent/feeds"
           parameters:[self parametersForCategory:nil limit:kVLCPodcastIndexShelfLimit]
           completion:^(NSArray<VLCPodcastIndexFeed *> *feeds, NSError *error) {
        if (self.isLoading) {
            self->_recentFeeds = feeds;
        }
        dispatch_group_leave(group);
    }];

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (!self.isLoading) {
            return;
        }

        self->_shelfCategories = [self rankedCategories];
        [self fetchCategoryShelvesFromIndex:0];
    });
}

+ (NSDictionary<NSString *, NSString *> *)topLevelCategories
{
    return @{ @"Arts": @"Arts",
              @"Business": @"Business",
              @"Comedy": @"Comedy",
              @"Culture": @"Society,Culture",
              @"Education": @"Education",
              @"Family": @"Kids,Family",
              @"Fiction": @"Fiction",
              @"Film": @"TV,Film",
              @"Fitness": @"Health,Fitness",
              @"Government": @"Government",
              @"Health": @"Health,Fitness",
              @"History": @"History",
              @"Kids": @"Kids,Family",
              @"Leisure": @"Leisure",
              @"Music": @"Music",
              @"News": @"News",
              @"Religion": @"Religion,Spirituality",
              @"Science": @"Science",
              @"Society": @"Society,Culture",
              @"Spirituality": @"Religion,Spirituality",
              @"Sports": @"Sports",
              @"TV": @"TV,Film",
              @"Technology": @"Technology",
              @"True Crime": @"True Crime" };
}

+ (NSString *)localizedTitleForCategory:(NSString *)category
{
    static NSDictionary<NSString *, NSString *> *titles;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        titles = @{
            @"Arts": NSLocalizedString(@"PODCAST_CATEGORY_ARTS", nil),
            @"Business": NSLocalizedString(@"PODCAST_CATEGORY_BUSINESS", nil),
            @"Comedy": NSLocalizedString(@"PODCAST_CATEGORY_COMEDY", nil),
            @"Education": NSLocalizedString(@"PODCAST_CATEGORY_EDUCATION", nil),
            @"Fiction": NSLocalizedString(@"PODCAST_CATEGORY_FICTION", nil),
            @"Government": NSLocalizedString(@"PODCAST_CATEGORY_GOVERNMENT", nil),
            @"Health,Fitness": NSLocalizedString(@"PODCAST_CATEGORY_HEALTH_FITNESS", nil),
            @"History": NSLocalizedString(@"PODCAST_CATEGORY_HISTORY", nil),
            @"Kids,Family": NSLocalizedString(@"PODCAST_CATEGORY_KIDS_FAMILY", nil),
            @"Leisure": NSLocalizedString(@"PODCAST_CATEGORY_LEISURE", nil),
            @"Music": NSLocalizedString(@"PODCAST_CATEGORY_MUSIC", nil),
            @"News": NSLocalizedString(@"PODCAST_CATEGORY_NEWS", nil),
            @"Religion,Spirituality": NSLocalizedString(@"PODCAST_CATEGORY_RELIGION_SPIRITUALITY", nil),
            @"Science": NSLocalizedString(@"PODCAST_CATEGORY_SCIENCE", nil),
            @"Society,Culture": NSLocalizedString(@"PODCAST_CATEGORY_SOCIETY_CULTURE", nil),
            @"Sports": NSLocalizedString(@"PODCAST_CATEGORY_SPORTS", nil),
            @"TV,Film": NSLocalizedString(@"PODCAST_CATEGORY_TV_FILM", nil),
            @"Technology": NSLocalizedString(@"PODCAST_CATEGORY_TECHNOLOGY", nil),
            @"True Crime": NSLocalizedString(@"PODCAST_CATEGORY_TRUE_CRIME", nil)
        };
    });
    return titles[category] ?: category;
}

+ (NSArray<NSString *> *)localizedTitlesForCategoryNames:(NSArray<NSString *> *)names
{
    NSDictionary<NSString *, NSString *> *topLevel = [VLCPodcastIndexService topLevelCategories];
    NSMutableArray<NSString *> *titles = [NSMutableArray array];

    for (NSString *name in names) {
        NSString *category = topLevel[name];
        if (!category) {
            continue;
        }

        NSString *title = [VLCPodcastIndexService localizedTitleForCategory:category];
        if (![titles containsObject:title]) {
            [titles addObject:title];
        }
    }

    return titles;
}

- (NSArray<NSString *> *)rankedCategories
{
    NSDictionary<NSString *, NSString *> *topLevel = [VLCPodcastIndexService topLevelCategories];
    NSMutableDictionary<NSString *, NSNumber *> *grouped = [NSMutableDictionary dictionary];

    for (VLCPodcastIndexFeed *feed in _chartFeeds) {
        for (NSString *category in feed.categories) {
            NSString *topCategory = topLevel[category];
            if (topCategory) {
                grouped[topCategory] = @(grouped[topCategory].unsignedIntegerValue + 1);
            }
        }
    }

    return [grouped.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        NSUInteger countA = grouped[a].unsignedIntegerValue;
        NSUInteger countB = grouped[b].unsignedIntegerValue;
        if (countA != countB) {
            return countA > countB ? NSOrderedAscending : NSOrderedDescending;
        }
        return [[VLCPodcastIndexService localizedTitleForCategory:a] localizedCaseInsensitiveCompare:
                [VLCPodcastIndexService localizedTitleForCategory:b]];
    }];
}

- (void)fetchCategoryShelvesFromIndex:(NSUInteger)index
{
    if (index >= _shelfCategories.count) {
        [self finishReload];
        return;
    }

    NSArray<VLCPodcastIndexShelf *> *partial = [self assembledShelves];
    if (partial.count > 0) {
        _shelves = partial;
        [self postUpdate];
    }

    NSUInteger end = MIN(index + kVLCPodcastIndexCategoryBatch, _shelfCategories.count);
    NSMutableDictionary<NSString *, VLCPodcastIndexShelf *> *collected = _categoryShelves;
    dispatch_group_t group = dispatch_group_create();

    for (NSUInteger position = index; position < end; position++) {
        NSString *category = _shelfCategories[position];
        dispatch_group_enter(group);
        [self requestPath:@"podcasts/trending"
               parameters:[self parametersForCategory:category limit:kVLCPodcastIndexShelfLimit]
               completion:^(NSArray<VLCPodcastIndexFeed *> *feeds, NSError *error) {
            if (self.isLoading && feeds.count > 0) {
                collected[category] = [[VLCPodcastIndexShelf alloc] initWithTitle:[VLCPodcastIndexService localizedTitleForCategory:category]
                                                                    category:category
                                                                       feeds:feeds];
            }
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (!self.isLoading) {
            return;
        }
        [self fetchCategoryShelvesFromIndex:end];
    });
}

- (NSArray<VLCPodcastIndexShelf *> *)assembledShelves
{
    NSMutableArray<VLCPodcastIndexShelf *> *shelves = [NSMutableArray array];

    if (_chartFeeds.count > 0) {
        [shelves addObject:[[VLCPodcastIndexShelf alloc] initWithTitle:NSLocalizedString(@"PODCAST_DIRECTORY_TOP_CHARTS", nil)
                                                              category:nil
                                                                 feeds:_chartFeeds]];
    }

    if (_recentFeeds.count > 0) {
        [shelves addObject:[[VLCPodcastIndexShelf alloc] initWithTitle:NSLocalizedString(@"PODCAST_DIRECTORY_NEW", nil)
                                                              category:nil
                                                                 feeds:_recentFeeds]];
    }

    for (NSString *category in _shelfCategories) {
        VLCPodcastIndexShelf *shelf = _categoryShelves[category];
        if (shelf) {
            [shelves addObject:shelf];
        }
    }

    return shelves;
}

- (void)finishReload
{
    _loading = NO;

    NSArray<VLCPodcastIndexShelf *> *shelves = [self assembledShelves];
    if (shelves.count > 0) {
        _shelves = shelves;
        _fetchDate = [NSDate date];
    }

    [self persist];
    [self postUpdate];
}

- (void)postUpdate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPodcastIndexShelvesDidUpdateNotification object:self];
}

@end
