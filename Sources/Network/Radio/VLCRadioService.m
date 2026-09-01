/*****************************************************************************
 * VLCRadioService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRadioService.h"
#import "VLCRadioCountry.h"
#import "VLCFavoriteService.h"
#import "VLCServiceBrowserRadio.h"
#import "VLCLocalNetworkServiceVLCMedia.h"
#import "VLCMigrationCursor.h"

NSString *const VLCRadioCountriesDidUpdateNotification = @"VLCRadioCountriesDidUpdateNotification";
NSString *const VLCRadioRecentStreamsDidChangeNotification = @"VLCRadioRecentStreamsDidChangeNotification";

static NSString *const VLCRadioFile = @"Radio.plist";
static NSString *const VLCRadioVersionKey = @"version";
static NSString *const VLCRadioCountriesKey = @"countries";
static NSString *const VLCRadioVisitedCountriesKey = @"visited";
static NSString *const VLCRadioRecentStreamsKey = @"recent";

static NSInteger const kVLCRadioCacheVersion = 1;
static NSUInteger const kVLCRadioVisitedCountriesCap = 8;
static NSUInteger const kVLCRadioRecentStreamsCap = 10;
static NSTimeInterval const kVLCRadioCountriesDiscoveryTimeout = 20.0;

@interface VLCRadioService () <VLCLocalNetworkServiceBrowserDelegate>
{
    NSArray<VLCRadioCountry *> *_allCountries;
    NSMutableArray<VLCRadioCountry *> *_visitedCountries;
    NSMutableArray<VLCFavorite *> *_recentStreams;
    NSString *_filePath;
    VLCServiceBrowserRadio *_discoveryBrowser;
    NSTimer *_timeoutTimer;
    NSInteger _activeConsumers;
    BOOL _discovering;
    BOOL _discoveryFailed;
}
@end

@implementation VLCRadioService

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheFolder = [paths firstObject];
        _filePath = [cacheFolder stringByAppendingPathComponent:VLCRadioFile];

        [self loadContent];

        if (self.hasCachedCountries && [VLCMigrationCursor isStepPending:VLCMigrationStepReloadRadioCountries]) {
            _allCountries = @[];
            [self persist];
        }
        [VLCMigrationCursor completeStep:VLCMigrationStepReloadRadioCountries];

        [self prepareVisitedCountryFlags];
    }
    return self;
}

- (void)loadContent
{
    _allCountries = @[];
    _visitedCountries = [NSMutableArray array];
    _recentStreams = [NSMutableArray arrayWithCapacity:kVLCRadioRecentStreamsCap];

    if (![[NSFileManager defaultManager] fileExistsAtPath:_filePath])
        return;

    NSData *data = [[NSData alloc] initWithContentsOfFile:_filePath];
    if (data == nil)
        return;

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:nil];
    unarchiver.requiresSecureCoding = NO;
    NSDictionary *content = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
    if (![content isKindOfClass:[NSDictionary class]])
        return;

    NSInteger storedVersion = [content[VLCRadioVersionKey] integerValue];
    if (storedVersion >= kVLCRadioCacheVersion) {
        NSArray *countries = content[VLCRadioCountriesKey];
        if ([countries isKindOfClass:[NSArray class]])
            _allCountries = countries;
    }

    NSArray *visited = content[VLCRadioVisitedCountriesKey];
    if ([visited isKindOfClass:[NSArray class]])
        _visitedCountries = [NSMutableArray arrayWithArray:visited];

    NSArray *recent = content[VLCRadioRecentStreamsKey];
    if ([recent isKindOfClass:[NSArray class]])
        [_recentStreams addObjectsFromArray:recent];
}

- (void)persist
{
    NSDictionary *content = @{ VLCRadioVersionKey: @(kVLCRadioCacheVersion),
                               VLCRadioCountriesKey: _allCountries,
                               VLCRadioVisitedCountriesKey: _visitedCountries,
                               VLCRadioRecentStreamsKey: _recentStreams };
    dispatch_async(dispatch_get_main_queue(), ^{
        @synchronized (self) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:content requiringSecureCoding:NO error:nil];
            [data writeToFile:self->_filePath atomically:YES];
        }
    });
}

- (BOOL)hasCachedCountries
{
    return _allCountries.count > 0;
}

#pragma mark - visited countries

- (void)markCountryVisited:(VLCRadioCountry *)country
{
    @synchronized (self) {
        NSUInteger existingIndex = NSNotFound;
        for (NSUInteger i = 0; i < _visitedCountries.count; i++) {
            if ([_visitedCountries[i].mrl isEqualToString:country.mrl]) {
                existingIndex = i;
                break;
            }
        }
        if (existingIndex != NSNotFound)
            [_visitedCountries removeObjectAtIndex:existingIndex];

        [_visitedCountries insertObject:country atIndex:0];

        while (_visitedCountries.count > kVLCRadioVisitedCountriesCap)
            [_visitedCountries removeLastObject];
    }
    [self persist];
    [self prepareVisitedCountryFlags];
}

- (void)prepareVisitedCountryFlags
{
    NSArray<VLCRadioCountry *> *visited;
    @synchronized (self) {
        visited = [_visitedCountries copy];
    }
    if (visited.count == 0)
        return;

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        for (VLCRadioCountry *country in visited) {
            [country prepareFlagImage];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:VLCRadioCountriesDidUpdateNotification object:self];
        });
    });
}

#pragma mark - recent streams

- (NSUInteger)indexOfRecentStreamWithURL:(NSURL *)url
{
    for (NSUInteger i = 0; i < _recentStreams.count; i++) {
        if ([_recentStreams[i].url isEqual:url])
            return i;
    }
    return NSNotFound;
}

- (void)markStreamPlayed:(VLCFavorite *)stream
{
    if (!stream.url)
        return;

    VLCFavorite *entry = [[VLCFavorite alloc] init];
    entry.userVisibleName = stream.userVisibleName;
    entry.url = stream.url;
    entry.groupName = stream.groupName;
    entry.artworkURL = stream.artworkURL;
    entry.mediaDescription = stream.mediaDescription;
    entry.lastPlayedDate = [NSDate date];
    entry.playable = YES;

    @synchronized (self) {
        NSUInteger existingIndex = [self indexOfRecentStreamWithURL:entry.url];
        if (existingIndex != NSNotFound)
            [_recentStreams removeObjectAtIndex:existingIndex];

        [_recentStreams insertObject:entry atIndex:0];

        while (_recentStreams.count > kVLCRadioRecentStreamsCap)
            [_recentStreams removeLastObject];
    }

    [self persist];
    [self postRecentStreamsDidChange];
}

- (void)removeRecentStream:(VLCFavorite *)stream
{
    @synchronized (self) {
        NSUInteger index = [self indexOfRecentStreamWithURL:stream.url];
        if (index == NSNotFound)
            return;

        [_recentStreams removeObjectAtIndex:index];
    }

    [self persist];
    [self postRecentStreamsDidChange];
}

- (void)postRecentStreamsDidChange
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCRadioRecentStreamsDidChangeNotification object:self];
    });
}

#pragma mark - discovery

- (void)startCountryDiscoveryIfNeeded
{
    _activeConsumers++;

    if (_allCountries.count > 0 || _discovering)
        return;

    [self beginDiscovery];
}

- (void)retryCountryDiscovery
{
    if (_allCountries.count > 0 || _discovering)
        return;

    [self beginDiscovery];
}

- (void)beginDiscovery
{
    _discoveryFailed = NO;
    _discovering = YES;
    _discoveryBrowser = [[VLCServiceBrowserRadio alloc] init];
    _discoveryBrowser.delegate = self;
    [_discoveryBrowser startDiscovery];

    _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:kVLCRadioCountriesDiscoveryTimeout
                                                     target:self
                                                   selector:@selector(discoveryTimedOut)
                                                   userInfo:nil
                                                    repeats:NO];

    [[NSNotificationCenter defaultCenter] postNotificationName:VLCRadioCountriesDidUpdateNotification object:self];
}

- (void)stopCountryDiscovery
{
    if (_activeConsumers > 0)
        _activeConsumers--;

    if (_activeConsumers > 0 || !_discovering)
        return;

    [_timeoutTimer invalidate];
    _timeoutTimer = nil;
    [self rebuildCountriesFromDiscovery];
    [_discoveryBrowser stopDiscovery];
    _discoveryBrowser = nil;
    _discovering = NO;
}

- (void)discoveryTimedOut
{
    _timeoutTimer = nil;

    if (_allCountries.count > 0)
        return;

    [_discoveryBrowser stopDiscovery];
    _discoveryBrowser = nil;
    _discovering = NO;
    _discoveryFailed = YES;

    [[NSNotificationCenter defaultCenter] postNotificationName:VLCRadioCountriesDidUpdateNotification object:self];
}

- (void)rebuildCountriesFromDiscovery
{
    NSUInteger count = _discoveryBrowser.numberOfItems;
    NSMutableArray<VLCRadioCountry *> *countries = [NSMutableArray arrayWithCapacity:count];

    for (NSUInteger i = 0; i < count; i++) {
        id<VLCLocalNetworkService> service = [_discoveryBrowser networkServiceForIndex:i];
        if (![service isKindOfClass:[VLCLocalNetworkServiceVLCMedia class]])
            continue;

        VLCMedia *media = [(VLCLocalNetworkServiceVLCMedia *)service mediaItem];
        if (media.mediaType != VLCMediaTypeDirectory)
            continue;

        NSString *mrl = media.url.absoluteString;
        if (mrl.length == 0)
            continue;

        [countries addObject:[[VLCRadioCountry alloc] initWithMrl:mrl]];
    }

    if (countries.count > 0)
        _allCountries = countries;
}

#pragma mark - VLCLocalNetworkServiceBrowserDelegate

- (void)localNetworkServiceBrowserDidUpdateServices:(id<VLCLocalNetworkServiceBrowser>)serviceBrowser
{
    [self rebuildCountriesFromDiscovery];

    if (_allCountries.count > 0) {
        [_timeoutTimer invalidate];
        _timeoutTimer = nil;
        _discoveryFailed = NO;
    }

    [self persist];
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCRadioCountriesDidUpdateNotification object:self];
}

@end
