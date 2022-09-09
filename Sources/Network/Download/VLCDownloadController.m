/*****************************************************************************
 * VLCDownloadController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDownloadController.h"
#import "VLCMediaFileDownloader.h"
#import "VLCHTTPFileDownloader.h"
#import "VLCActivityManager.h"

@interface VLCDownloadController () <VLCMediaFileDownloader>
{
    NSMutableArray *_currentDownloads;
    NSMutableArray *_downloadedMedia;
    NSMutableArray *_downloadedMediaDates;
    NSDateFormatter *_dateFormatter;

    BOOL _downloadActive;
    NSString *_humanReadableFilename;
    NSMutableDictionary *_userDefinedFileNameForDownloadItem;
    NSMutableDictionary *_expectedDownloadSizesForItem;
    NSTimeInterval _startDL;

    VLCMediaFileDownloader *_mediaDownloader;
    VLCHTTPFileDownloader *_httpDownloader;

    NSTimeInterval _lastStatsUpdate;
    NSMutableArray *_lastSpeeds;
    CGFloat _totalReceived;
    CGFloat _lastReceived;
}
@end

@implementation VLCDownloadController

#pragma mark - state management
+ (instancetype)sharedInstance
{
    static VLCDownloadController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [[VLCDownloadController alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lastSpeeds = [[NSMutableArray alloc] init];
        _currentDownloads = [[NSMutableArray alloc] init];
        _downloadedMedia = [[NSMutableArray alloc] init];
        _downloadedMediaDates = [[NSMutableArray alloc] init];
        _userDefinedFileNameForDownloadItem = [[NSMutableDictionary alloc] init];
        _expectedDownloadSizesForItem = [[NSMutableDictionary alloc] init];
        _mediaDownloader = [[VLCMediaFileDownloader alloc] init];
        _mediaDownloader.delegate = self;
        _httpDownloader = [[VLCHTTPFileDownloader alloc] init];
        _httpDownloader.delegate = self;

        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    return self;
}

#pragma mark - API to other VLC objects
- (void)addURLToDownloadList:(NSURL *)aURL fileNameOfMedia:(NSString*)fileName
{
    VLCMedia *media = [VLCMedia mediaWithURL:aURL];
    @synchronized (_currentDownloads) {
        [_currentDownloads addObject:media];

        if (fileName) {
            [_userDefinedFileNameForDownloadItem setObject:fileName forKey:aURL];
        }
    }
    [self _updateDownloadList];
}

- (void)addVLCMediaToDownloadList:(VLCMedia *)media fileNameOfMedia:(NSString*)fileName expectedDownloadSize:(long long unsigned)expectedDownloadSize
{
    @synchronized (_currentDownloads) {
        [_currentDownloads addObject:media];
        NSURL *mediaURL = media.url;
        if (fileName) {
            [_userDefinedFileNameForDownloadItem setObject:fileName forKey:mediaURL];
        }
        if (expectedDownloadSize > 0) {
            [_expectedDownloadSizesForItem setObject:@(expectedDownloadSize) forKey:mediaURL];
        }
    }
    [self _updateDownloadList];
}

- (void)cancelCurrentDownload
{
    [_mediaDownloader cancelDownload];
    [_httpDownloader cancelDownload];
}

- (NSUInteger)numberOfCompletedDownloads
{
    return _downloadedMedia.count;
}

- (NSString *)displayNameForCompletedDownloadAtIndex:(NSUInteger)index
{
    NSString *recentDownload = _downloadedMedia[index];
    return [recentDownload lastPathComponent];
}

- (NSString *)metadataForCompletedDownloadAtIndex:(NSUInteger)index
{
    return [_dateFormatter stringFromDate:_downloadedMediaDates[index]];
}

- (VLCMedia *)mediaForCompletedDownloadAtIndex:(NSUInteger)index
{
    return [VLCMedia mediaWithPath:_downloadedMedia[index]];
}

- (NSUInteger)numberOfScheduledDownloads
{
    return _currentDownloads.count;
}

- (NSString *)displayNameForDownloadAtIndex:(NSUInteger)index
{
    NSString *returnValue;
    VLCMedia *media;
    @synchronized (_currentDownloads) {
        if (_currentDownloads.count > index) {
            media = _currentDownloads[index];
        }
    }
    if (media) {
        NSURL *mediaURL = media.url;
        NSString *customFilename = [_userDefinedFileNameForDownloadItem objectForKey:mediaURL];
        if (customFilename) {
            returnValue = [customFilename stringByRemovingPercentEncoding];
        } else {
            returnValue = [[mediaURL lastPathComponent] stringByRemovingPercentEncoding];
        }
    }
    return returnValue;
}

- (NSString *)urlStringForDownloadAtIndex:(NSUInteger)index
{
    NSString *returnValue;
    VLCMedia *media;
    @synchronized (_currentDownloads) {
        if (_currentDownloads.count > index) {
            media = _currentDownloads[index];
        }
    }
    if (media) {
        returnValue = [media.url absoluteString];
    }
    return returnValue;
}

- (void)removeScheduledDownloadAtIndex:(NSUInteger)index
{
    @synchronized (_currentDownloads) {
        VLCMedia *media = _currentDownloads[index];
        NSURL *mediaURL = media.url;
        [_userDefinedFileNameForDownloadItem removeObjectForKey:mediaURL];
        [_expectedDownloadSizesForItem removeObjectForKey:mediaURL];
        [_currentDownloads removeObjectAtIndex:index];
    }
}

- (void)bringDelegateUpToDate
{
    if (_downloadActive) {
        [_delegate downloadStartedWithDisplayName:_humanReadableFilename];
    } else {
        [_delegate downloadEnded];
    }
    [_delegate listOfScheduledDownloadsChanged];
}

#pragma mark - Download management
- (void)_downloadVLCMediaItem:(VLCMedia *)media
{
    if (_mediaDownloader.downloadInProgress || _httpDownloader.downloadInProgress) {
        return;
    }

    NSURL *mediaURL = media.url;
    _humanReadableFilename = [_userDefinedFileNameForDownloadItem objectForKey:mediaURL];
    if (!_humanReadableFilename) {
        _humanReadableFilename = [mediaURL lastPathComponent];
    } else {
        _humanReadableFilename = [_humanReadableFilename stringByRemovingPercentEncoding];
    }

    long long unsigned expectedDownloadSize = [[_expectedDownloadSizesForItem objectForKey:mediaURL] unsignedLongLongValue];

    _downloadActive = YES;
    if ([mediaURL.scheme isEqualToString:@"http"]) {
        [_httpDownloader downloadFileFromVLCMedia:media withName:_humanReadableFilename expectedDownloadSize:expectedDownloadSize];
    } else {
        [_mediaDownloader downloadFileFromVLCMedia:media withName:_humanReadableFilename expectedDownloadSize:expectedDownloadSize];
    }

    [_userDefinedFileNameForDownloadItem removeObjectForKey:mediaURL];
    [_expectedDownloadSizesForItem removeObjectForKey:mediaURL];
}

- (void)_triggerNextDownload
{
    if ([_currentDownloads count] == 0) {
        _downloadActive = NO;
        [_delegate listOfScheduledDownloadsChanged];
        return;
    }

    VLCMedia *firstObject;
    @synchronized (_currentDownloads) {
        firstObject = _currentDownloads.firstObject;
    }
    [self _downloadVLCMediaItem:firstObject];

    @synchronized (_currentDownloads) {
        [_currentDownloads removeObjectAtIndex:0];
    }
    [_delegate listOfScheduledDownloadsChanged];
}

- (void)_updateDownloadList
{
    [_delegate listOfScheduledDownloadsChanged];
    if (_downloadActive == NO)
        [self _triggerNextDownload];
}

#pragma mark - VLC media downloader delegate
- (void)mediaFileDownloadStarted:(VLCMediaFileDownloader *)theDownloader
{
    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStopped];
    [activityManager networkActivityStarted];

    _startDL = [NSDate timeIntervalSinceReferenceDate];
    [_lastSpeeds removeAllObjects];
    _lastReceived = 0;
    _totalReceived = 0;

    [_delegate downloadStartedWithDisplayName:_humanReadableFilename];

    APLog(@"download started");
}

- (void)mediaFileDownloadEnded:(VLCMediaFileDownloader *)theDownloader
{
    [[VLCActivityManager defaultManager] networkActivityStopped];
    _downloadActive = NO;

    NSString *storageLocationPath = theDownloader.downloadLocationPath;
    if (storageLocationPath) {
        if ([_downloadedMedia indexOfObject:storageLocationPath] == NSNotFound) {
            [_downloadedMedia addObject:storageLocationPath];
            [_downloadedMediaDates addObject:[NSDate date]];
        }
    }

    [_delegate downloadEnded];

    APLog(@"download ended here: %@", storageLocationPath);

    [self _triggerNextDownload];
}

- (void)downloadFailedWithErrorDescription:(NSString *)description forDownloader:(VLCMediaFileDownloader *)theDownloader
{
    [_delegate downloadFailedWithDescription:description];
    [self mediaFileDownloadEnded:theDownloader];
}

- (void)progressUpdatedTo:(CGFloat)percentage receivedDataSize:(CGFloat)receivedDataSize  expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    _totalReceived += receivedDataSize;
    _lastReceived += receivedDataSize;

    if ((_lastStatsUpdate > 0 && ([NSDate timeIntervalSinceReferenceDate] - _lastStatsUpdate > .5)) || _lastStatsUpdate <= 0) {
        CGFloat speed = [self getAverageSpeed:_lastReceived / ([NSDate timeIntervalSinceReferenceDate] - _lastStatsUpdate)];

        [_delegate downloadProgressUpdatedWithPercentage:percentage
                                                    time:[self getRemainingTimeString:speed expectedDownloadSize:expectedDownloadSize]
                                                   speed:[self getSpeedString:speed]
                                          totalSizeKnown:expectedDownloadSize > 0];

        _lastStatsUpdate = [NSDate timeIntervalSinceReferenceDate];
        _lastReceived = 0;
    }
}

#pragma mark - helpers
- (CGFloat)getAverageSpeed:(CGFloat)speed
{
    [_lastSpeeds addObject:[NSNumber numberWithFloat:speed]];
    if (_lastSpeeds.count > 10) {
        [_lastSpeeds removeObjectAtIndex:0];
    }

    CGFloat averageSpeed = 0;
    NSUInteger numberOfLastSpeeds = _lastSpeeds.count;
    int i = 0;
    while (i < numberOfLastSpeeds) {
        averageSpeed += [_lastSpeeds[i] floatValue];
        i += 1;
    }
    averageSpeed /= i;
    return averageSpeed;
}

- (NSString *)getSpeedString:(CGFloat)speed
{
    NSString *string = [NSByteCountFormatter stringFromByteCount:speed
                                                      countStyle:NSByteCountFormatterCountStyleDecimal];
    return [string stringByAppendingString:@"/s"];
}

- (NSString *)getRemainingTimeString:(CGFloat)speed expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    if (expectedDownloadSize <= 0) {
        return @"--:--";
    }
    CGFloat remainingInSeconds = (expectedDownloadSize - _totalReceived)/speed;

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:remainingInSeconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    return [formatter stringFromDate:date];
}

@end
