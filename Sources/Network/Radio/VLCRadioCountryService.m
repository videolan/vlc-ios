/*****************************************************************************
 * VLCRadioCountryService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRadioCountryService.h"
#import "VLCRadioCountry.h"
#import "VLCServiceBrowserRadio.h"
#import "VLCLocalNetworkServiceVLCMedia.h"
#import "VLCMigrationCursor.h"

NSString *const VLCRadioCountriesDidUpdateNotification = @"VLCRadioCountriesDidUpdateNotification";

static NSString *const VLCRadioCountriesFile = @"RadioCountries.plist";
static NSString *const VLCRadioCountriesVersionKey = @"version";
static NSString *const VLCRadioCountriesListKey = @"countries";
static NSString *const VLCRadioCountriesVisitedKey = @"visited";

static NSInteger const kVLCRadioCountriesCacheVersion = 1;
static NSUInteger const kVLCRadioVisitedCountriesCap = 8;
static NSTimeInterval const kVLCRadioCountriesDiscoveryTimeout = 20.0;

@interface VLCRadioCountryService () <VLCLocalNetworkServiceBrowserDelegate>
{
    NSArray<VLCRadioCountry *> *_allCountries;
    NSMutableArray<VLCRadioCountry *> *_visitedCountries;
    NSString *_filePath;
    VLCServiceBrowserRadio *_discoveryBrowser;
    NSTimer *_timeoutTimer;
    NSInteger _activeConsumers;
    BOOL _discovering;
    BOOL _discoveryFailed;
}
@end

@implementation VLCRadioCountryService

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheFolder = [paths firstObject];
        _filePath = [cacheFolder stringByAppendingPathComponent:VLCRadioCountriesFile];

        [self loadContent];

        if (self.hasCachedCountries && [VLCMigrationCursor isStepPending:VLCMigrationStepReloadRadioCountries]) {
            _allCountries = @[];
            [self persist];
        }
        [VLCMigrationCursor completeStep:VLCMigrationStepReloadRadioCountries];
    }
    return self;
}

- (void)loadContent
{
    _allCountries = @[];
    _visitedCountries = [NSMutableArray array];

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

    NSInteger storedVersion = [content[VLCRadioCountriesVersionKey] integerValue];
    if (storedVersion >= kVLCRadioCountriesCacheVersion) {
        NSArray *countries = content[VLCRadioCountriesListKey];
        if ([countries isKindOfClass:[NSArray class]])
            _allCountries = countries;
    }

    NSArray *visited = content[VLCRadioCountriesVisitedKey];
    if ([visited isKindOfClass:[NSArray class]])
        _visitedCountries = [NSMutableArray arrayWithArray:visited];
}

- (void)persist
{
    NSDictionary *content = @{ VLCRadioCountriesVersionKey: @(kVLCRadioCountriesCacheVersion),
                               VLCRadioCountriesListKey: _allCountries,
                               VLCRadioCountriesVisitedKey: _visitedCountries };
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
