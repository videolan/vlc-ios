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
#import <AVFoundation/AVFoundation.h>

NSString * const VLCDownloadControllerStateDidChangeNotification = @"VLCDownloadControllerStateDidChangeNotification";

@interface VLCDownloadController () <VLCMediaFileDownloader>
{
    NSMutableArray *_currentDownloads;
    NSMutableArray *_downloadedMedia;
    NSMutableArray *_downloadedMediaDates;
    NSMutableArray<NSDictionary *> *_failedDownloads;
    NSDateFormatter *_dateFormatter;
    NSByteCountFormatter *_byteCountFormatter;
    NSDateFormatter *_remainingTimeFormatter;

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

    AVSpeechSynthesizer *_speechSynthesizer;

    CGFloat _activePercentage;
    BOOL _activeSizeKnown;
    NSString *_activeSpeed;
    NSString *_activeTime;
    CGFloat _activeExpectedSize;
    BOOL _cancelInitiatedByUser;
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
        _failedDownloads = [[NSMutableArray alloc] init];
        _userDefinedFileNameForDownloadItem = [[NSMutableDictionary alloc] init];
        _expectedDownloadSizesForItem = [[NSMutableDictionary alloc] init];
        _mediaDownloader = [[VLCMediaFileDownloader alloc] init];
        _mediaDownloader.delegate = self;
        _httpDownloader = [[VLCHTTPFileDownloader alloc] init];
        _httpDownloader.delegate = self;

        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterMediumStyle;

        _byteCountFormatter = [[NSByteCountFormatter alloc] init];
        _byteCountFormatter.countStyle = NSByteCountFormatterCountStyleFile;
        _byteCountFormatter.allowsNonnumericFormatting = NO;

        _remainingTimeFormatter = [[NSDateFormatter alloc] init];
        _remainingTimeFormatter.dateFormat = @"HH:mm:ss";
        _remainingTimeFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
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
    _cancelInitiatedByUser = YES;
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

#pragma mark - Failed downloads
- (NSUInteger)numberOfFailedDownloads
{
    return _failedDownloads.count;
}

- (NSString *)displayNameForFailedDownloadAtIndex:(NSUInteger)index
{
    if (index >= _failedDownloads.count) {
        return nil;
    }
    return _failedDownloads[index][@"name"];
}

- (NSString *)errorDescriptionForFailedDownloadAtIndex:(NSUInteger)index
{
    if (index >= _failedDownloads.count) {
        return nil;
    }
    return _failedDownloads[index][@"error"];
}

- (void)removeFailedDownloadAtIndex:(NSUInteger)index
{
    if (index >= _failedDownloads.count) {
        return;
    }
    [_failedDownloads removeObjectAtIndex:index];
    [self _postStateDidChange];
}

#pragma mark - Banner-facing state
- (BOOL)hasActiveDownload
{
    return _downloadActive;
}

- (NSString *)activeDownloadDisplayName
{
    return _downloadActive ? _humanReadableFilename : nil;
}

- (CGFloat)activeDownloadPercentage
{
    return _activePercentage;
}

- (BOOL)activeDownloadSizeKnown
{
    return _activeSizeKnown;
}

- (NSString *)activeDownloadSpeedString
{
    return _downloadActive ? _activeSpeed : nil;
}

- (NSString *)activeDownloadTimeString
{
    return _downloadActive ? _activeTime : nil;
}

- (NSString *)activeDownloadBytesString
{
    if (!_downloadActive) {
        return nil;
    }
    NSString *received = [_byteCountFormatter stringFromByteCount:(long long)_totalReceived];
    if (_activeExpectedSize > 0) {
        NSString *total = [_byteCountFormatter stringFromByteCount:(long long)_activeExpectedSize];
        return [NSString stringWithFormat:@"%@ / %@", received, total];
    }
    return received;
}

- (void)_resetActiveDownloadState
{
    _startDL = [NSDate timeIntervalSinceReferenceDate];
    [_lastSpeeds removeAllObjects];
    _lastReceived = 0;
    _totalReceived = 0;
    _lastStatsUpdate = 0;
    _activePercentage = 0.0;
    _activeSizeKnown = NO;
    _activeSpeed = nil;
    _activeTime = nil;
    _activeExpectedSize = 0.0;
    _cancelInitiatedByUser = NO;
}

- (void)_postStateDidChange
{
    if ([NSThread isMainThread]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCDownloadControllerStateDidChangeNotification object:self];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:VLCDownloadControllerStateDidChangeNotification object:self];
        });
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

    [self fetchExpectedDownloadSizeForMedia:media completionHandler:^(CGFloat expectedDownloadSize) {
        self->_downloadActive = YES; // Allow download regardless of the expected size

        // Single start point common to both downloaders; the HTTP one does not
        // call mediaFileDownloadStarted:.
        [self _resetActiveDownloadState];

        if ([media.url.scheme isEqualToString:@"http"]) {
            [self->_httpDownloader downloadFileFromVLCMedia:media withName:self->_humanReadableFilename expectedDownloadSize:expectedDownloadSize];
        } else {
            [self->_mediaDownloader downloadFileFromVLCMedia:media withName:self->_humanReadableFilename expectedDownloadSize:expectedDownloadSize];
        }

        [self->_userDefinedFileNameForDownloadItem removeObjectForKey:media.url];
        [self->_expectedDownloadSizesForItem removeObjectForKey:media.url];
    }];
}

- (void)fetchExpectedDownloadSizeForMedia:(VLCMedia *)media completionHandler:(void (^)(CGFloat expectedDownloadSize))completionHandler
{
    NSURL *mediaURL = media.url;

    // Check if the URL scheme is either "http" or "https" before making the HEAD request
    if (![mediaURL.scheme isEqualToString:@"http"] && ![mediaURL.scheme isEqualToString:@"https"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(0.0);
        });
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:mediaURL];
    request.HTTPMethod = @"HEAD";
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        CGFloat expectedDownloadSize = 0.0;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                NSString *contentLength = [httpResponse.allHeaderFields valueForKey:@"Content-Length"];
                expectedDownloadSize = [contentLength doubleValue];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(expectedDownloadSize);
        });
    }];

    [dataTask resume];
}

- (void)_triggerNextDownload
{
    if ([_currentDownloads count] == 0) {
        _downloadActive = NO;
        [_delegate listOfScheduledDownloadsChanged];
        [self _postStateDidChange];
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
    [self _postStateDidChange];
}

- (void)_updateDownloadList
{
    [_delegate listOfScheduledDownloadsChanged];
    // _triggerNextDownload posts the resulting state; nothing to do here when
    // a download is already running (queue size is delegate-driven, not banner-driven).
    if (_downloadActive == NO) {
        [self _triggerNextDownload];
    } else {
        [self _postStateDidChange];
    }
}

#pragma mark - Download completion announcement
- (void)announceDownloadCompletionForFilename:(NSString *)filename
{
    if (!UIAccessibilityIsVoiceOverRunning()) {
        return;
    }
    if (!_speechSynthesizer) {
        _speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    }
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *languageCode = [currentLocale objectForKey:NSLocaleLanguageCode];
    NSString *announcement = [NSString stringWithFormat:NSLocalizedString(@"DOWNLOAD_COMPLETED_ANNOUNCEMENT", comment: ""), filename];
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:announcement];
    AVSpeechSynthesisVoice *customVoice = [AVSpeechSynthesisVoice voiceWithLanguage:languageCode];
    utterance.voice = customVoice;
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate;
    utterance.pitchMultiplier = 1.2;
    utterance.volume = 0.8;
    [_speechSynthesizer speakUtterance:utterance];
}

#pragma mark - VLC media downloader delegate
- (void)mediaFileDownloadStarted:(VLCMediaFileDownloader *)theDownloader
{
    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStopped];
    [activityManager networkActivityStarted];

    [_delegate downloadStartedWithDisplayName:_humanReadableFilename];
    [self _postStateDidChange];

    APLog(@"download started");
}

- (void)mediaFileDownloadEnded:(VLCMediaFileDownloader *)theDownloader
{
    [[VLCActivityManager defaultManager] networkActivityStopped];
    _downloadActive = NO;
    _activePercentage = 0.0;
    _activeSizeKnown = NO;
    _activeExpectedSize = 0.0;
    // _triggerNextDownload below will post the resulting state.

    NSString *storageLocationPath = theDownloader.downloadLocationPath;
    // downloadLocationPath is the intended destination, set even on failure,
    // so we probe the filesystem to tell a real success apart from a cancel.
    if (storageLocationPath
        && [[NSFileManager defaultManager] fileExistsAtPath:storageLocationPath]
        && [_downloadedMedia indexOfObject:storageLocationPath] == NSNotFound) {
        [_downloadedMedia addObject:storageLocationPath];
        [_downloadedMediaDates addObject:[NSDate date]];
        [self announceDownloadCompletionForFilename:theDownloader.filename];
    }

    [_delegate downloadEnded];

    APLog(@"download ended here: %@", storageLocationPath);

    [self _triggerNextDownload];
}

- (void)downloadFailedWithErrorDescription:(NSString *)description forDownloader:(VLCMediaFileDownloader *)theDownloader
{
    if (_cancelInitiatedByUser) {
        _cancelInitiatedByUser = NO;
        [self mediaFileDownloadEnded:theDownloader];
        return;
    }

    NSString *failedName = _humanReadableFilename;
    if (!failedName) {
        failedName = theDownloader.filename ?: @"";
    }
    NSString *failedError = description ?: @"";
    [_failedDownloads addObject:@{@"name": failedName, @"error": failedError}];
    [self _postStateDidChange];

    [_delegate downloadFailedWithDescription:description];
    [self mediaFileDownloadEnded:theDownloader];
}

- (void)progressUpdatedTo:(CGFloat)percentage receivedDataSize:(CGFloat)receivedDataSize expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    _totalReceived += receivedDataSize;
    _lastReceived += receivedDataSize;

    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    if (currentTime - _lastStatsUpdate > 0.5 || _lastStatsUpdate <= 0) {
        CGFloat speed = [self getAverageSpeed:_lastReceived / (currentTime - _lastStatsUpdate)];
        percentage = fmin(fmax(percentage, 0.0), 100.0);
        _activePercentage = percentage;
        _activeSizeKnown = expectedDownloadSize > 0;
        _activeExpectedSize = expectedDownloadSize;
        NSString *timeStr = [self getRemainingTimeString:speed expectedDownloadSize:expectedDownloadSize];
        NSString *speedStr = [self getSpeedString:speed];
        _activeSpeed = speedStr;
        _activeTime = timeStr;
        [_delegate downloadProgressUpdatedWithPercentage:percentage
                                                    time:timeStr
                                                   speed:speedStr
                                          totalSizeKnown:expectedDownloadSize > 0];
        [self _postStateDidChange];

        _lastStatsUpdate = currentTime;
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
    return [_remainingTimeFormatter stringFromDate:date];
}

@end
