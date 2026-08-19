/*****************************************************************************
 * VLCTransferController.m
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

#import "VLCTransferController.h"
#import "VLCTransferItem.h"
#import "VLCMediaFileDownloader.h"
#import "VLCHTTPFileDownloader.h"
#import "VLCActivityManager.h"
#import <AVFoundation/AVFoundation.h>
#if (TARGET_OS_IOS || TARGET_OS_WATCH) && !NO_WATCH
#import <WatchConnectivity/WatchConnectivity.h>
#endif

NSString * const VLCTransferControllerStateDidChangeNotification = @"VLCTransferControllerStateDidChangeNotification";

@interface VLCTransferController () <VLCMediaFileDownloaderDelegate>
{
    NSMutableArray<VLCMedia *> *_currentDownloads;
    NSMutableDictionary *_userDefinedFileNameForDownloadItem;
    VLCMediaFileDownloader *_mediaDownloader;
    VLCHTTPFileDownloader *_httpDownloader;

    BOOL _downloadActive;
    VLCTransferItem *_activeDownloadItem;
    BOOL _cancelInitiatedByUser;

    NSMutableDictionary<NSNumber *, VLCTransferItem *> *_activeUploads;
    NSUInteger _nextUploadToken;

    NSMutableDictionary<NSNumber *, VLCTransferItem *> *_activeExternalDownloads;
    NSUInteger _nextExternalDownloadToken;

#if (TARGET_OS_IOS || TARGET_OS_WATCH) && !NO_WATCH
    NSMapTable<WCSessionFileTransfer *, VLCTransferItem *> *_activeWatchTransfers;
    NSMutableArray<WCSessionFileTransfer *> *_observedWatchTransfers;
#endif
    NSMutableArray<VLCTransferItem *> *_completed;
    NSMutableArray<VLCTransferItem *> *_failed;

    AVSpeechSynthesizer *_speechSynthesizer;
}
@end

@implementation VLCTransferController

#pragma mark - lifecycle
- (instancetype)init
{
    self = [super init];
    if (self) {
        _currentDownloads = [[NSMutableArray alloc] init];
        _userDefinedFileNameForDownloadItem = [[NSMutableDictionary alloc] init];
        _activeUploads = [[NSMutableDictionary alloc] init];
        _activeExternalDownloads = [[NSMutableDictionary alloc] init];
#if (TARGET_OS_IOS || TARGET_OS_WATCH) && !NO_WATCH
        _activeWatchTransfers = [[NSMapTable alloc] init];
        _observedWatchTransfers = [[NSMutableArray alloc] init];
#endif
        _completed = [[NSMutableArray alloc] init];
        _failed = [[NSMutableArray alloc] init];

        _mediaDownloader = [[VLCMediaFileDownloader alloc] init];
        _mediaDownloader.delegate = self;
        _httpDownloader = [[VLCHTTPFileDownloader alloc] init];
        _httpDownloader.delegate = self;

#if (TARGET_OS_IOS || TARGET_OS_WATCH) && !NO_WATCH
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleFileTransferDidStart:)
                                                     name:kVLCFileTransferDidStartNotification
                                                   object:nil];
#endif
    }
    return self;
}

- (void)_runOnMain:(dispatch_block_t)block
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

-(void)dealloc {
#if (TARGET_OS_IOS || TARGET_OS_WATCH) && !NO_WATCH
    for (WCSessionFileTransfer *fileTransfer in _observedWatchTransfers) {
        [fileTransfer.progress removeObserver:self
                                forKeyPath:@"fractionCompleted"
                                   context:(__bridge void *)fileTransfer];
    }
#endif
}

- (void)_postStateDidChange
{
    [self _runOnMain:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCTransferControllerStateDidChangeNotification object:self];
    }];
}

#pragma mark - download source
- (void)addVLCMediaToDownloadList:(VLCMedia *)media fileNameOfMedia:(NSString *)fileName
{
    @synchronized (_currentDownloads) {
        [_currentDownloads addObject:media];
        if (fileName) {
            [_userDefinedFileNameForDownloadItem setObject:fileName forKey:media.url];
        }
    }
    [self _updateDownloadList];
}

- (void)cancelCurrentDownload
{
    if (_httpDownloader.downloadInProgress) {
        _cancelInitiatedByUser = YES;
        [_httpDownloader cancelDownload];
    } else if (_mediaDownloader.downloadInProgress) {
        _cancelInitiatedByUser = YES;
        [_mediaDownloader cancelDownload];
    }
}

- (NSString *)_displayNameForQueuedMedia:(VLCMedia *)media
{
    NSURL *mediaURL = media.url;
    NSString *customFilename = [_userDefinedFileNameForDownloadItem objectForKey:mediaURL];
    if (customFilename) {
        return [customFilename stringByRemovingPercentEncoding];
    }
    return [[mediaURL lastPathComponent] stringByRemovingPercentEncoding];
}

- (void)_updateDownloadList
{
    if (_downloadActive == NO) {
        [self _triggerNextDownload];
    } else {
        [self _postStateDidChange];
    }
}

- (void)_triggerNextDownload
{
    VLCMedia *nextMedia;
    @synchronized (_currentDownloads) {
        nextMedia = _currentDownloads.firstObject;
        if (nextMedia) {
            [_currentDownloads removeObjectAtIndex:0];
        }
    }
    if (!nextMedia) {
        _downloadActive = NO;
        [self _postStateDidChange];
        return;
    }
    [self _downloadVLCMediaItem:nextMedia];
    [self _postStateDidChange];
}

- (void)_downloadVLCMediaItem:(VLCMedia *)media
{
    if (_mediaDownloader.downloadInProgress || _httpDownloader.downloadInProgress) {
        return;
    }

    NSURL *mediaURL = media.url;
    NSString *humanReadableFilename = [_userDefinedFileNameForDownloadItem objectForKey:mediaURL];
    if (!humanReadableFilename) {
        humanReadableFilename = [mediaURL lastPathComponent];
    }
    NSString *decodedFilename = [humanReadableFilename stringByRemovingPercentEncoding];
    if (decodedFilename) {
        humanReadableFilename = decodedFilename;
    }

    [self fetchExpectedDownloadSizeForMedia:media completionHandler:^(CGFloat expectedDownloadSize) {
        self->_downloadActive = YES;
        self->_activeDownloadItem = [VLCTransferItem downloadItemWithName:humanReadableFilename];
        [self _postStateDidChange];

        NSString *scheme = media.url.scheme.lowercaseString;
        if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
#if MEDIA_DOWNLOAD_DEBUG
            APLog(@"[DownloadDebug] routing %@ (scheme '%@') to NSURLSession downloader", media.url, media.url.scheme);
#endif
            [self->_httpDownloader downloadFileFromVLCMedia:media withName:humanReadableFilename expectedDownloadSize:expectedDownloadSize];
        } else {
#if MEDIA_DOWNLOAD_DEBUG
            APLog(@"[DownloadDebug] routing %@ (scheme '%@') to libvlc media downloader", media.url, media.url.scheme);
#endif
            [self->_mediaDownloader downloadFileFromVLCMedia:media withName:humanReadableFilename expectedDownloadSize:expectedDownloadSize];
        }

        [self->_userDefinedFileNameForDownloadItem removeObjectForKey:media.url];
    }];
}

- (void)fetchExpectedDownloadSizeForMedia:(VLCMedia *)media completionHandler:(void (^)(CGFloat expectedDownloadSize))completionHandler
{
    NSURL *mediaURL = media.url;
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

#pragma mark - download completion announcement
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
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:languageCode];
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate;
    utterance.pitchMultiplier = 1.2;
    utterance.volume = 0.8;
    [_speechSynthesizer speakUtterance:utterance];
}

#pragma mark - VLCMediaFileDownloaderDelegate
- (void)mediaFileDownloaderDidStart:(VLCMediaFileDownloader *)downloader
{
    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStopped];
    [activityManager networkActivityStarted];
    [self _postStateDidChange];
    APLog(@"download started");
}

- (BOOL)_completedContainsDownloadPath:(NSString *)path
{
    for (VLCTransferItem *item in _completed) {
        if (item.direction == VLCTransferDirectionDownload && [item.filePath isEqualToString:path]) {
            return YES;
        }
    }
    return NO;
}

- (void)mediaFileDownloaderDidFinish:(VLCMediaFileDownloader *)downloader
{
    [[VLCActivityManager defaultManager] networkActivityStopped];

    NSString *storageLocationPath = downloader.downloadLocationPath;
    if (storageLocationPath
        && ![self _completedContainsDownloadPath:storageLocationPath]
        && _activeDownloadItem) {
        [_activeDownloadItem markCompletedWithFilePath:storageLocationPath];
        [_completed addObject:_activeDownloadItem];
        [self announceDownloadCompletionForFilename:downloader.filename];
    }

    APLog(@"download finished: %@", storageLocationPath);
    [self _advanceAfterDownload];
}

- (void)mediaFileDownloader:(VLCMediaFileDownloader *)downloader didFailWithDescription:(NSString *)description
{
    [[VLCActivityManager defaultManager] networkActivityStopped];

    if (_cancelInitiatedByUser) {
        _cancelInitiatedByUser = NO;
        [self _advanceAfterDownload];
        return;
    }

    if (_activeDownloadItem) {
        [_activeDownloadItem markFailedWithError:description ?: @""];
        [_failed addObject:_activeDownloadItem];
    }
    [self _advanceAfterDownload];
}

- (void)_advanceAfterDownload
{
    _downloadActive = NO;
    _activeDownloadItem = nil;
    [self _postStateDidChange];
    [self _triggerNextDownload];
}

- (void)mediaFileDownloader:(VLCMediaFileDownloader *)downloader didUpdateReceivedBytes:(int64_t)receivedBytes expectedBytes:(int64_t)expectedBytes
{
    if (!_activeDownloadItem) {
        return;
    }
    if ([_activeDownloadItem ingestReceivedBytes:receivedBytes expectedBytes:expectedBytes]) {
        [self _postStateDidChange];
    }
}

#pragma mark - upload source
- (NSUInteger)startUploadWithExpectedSize:(long long)expectedSize
{
    NSUInteger token;
    @synchronized (self) {
        token = ++_nextUploadToken;
    }
    [self _runOnMain:^{
        self->_activeUploads[@(token)] = [VLCTransferItem uploadItemWithExpectedSize:expectedSize];
        [self _postStateDidChange];
    }];
    return token;
}

- (void)updateUpload:(NSUInteger)token displayName:(NSString *)name
{
    [self _runOnMain:^{
        VLCTransferItem *item = self->_activeUploads[@(token)];
        if (!item) {
            return;
        }
        item.displayName = name ?: @"";
        [self _postStateDidChange];
    }];
}

- (void)updateUpload:(NSUInteger)token receivedBytes:(long long)received
{
    [self _runOnMain:^{
        VLCTransferItem *item = self->_activeUploads[@(token)];
        if (!item) {
            return;
        }
        BOOL refreshed = [item ingestReceivedBytes:received expectedBytes:item.expectedBytes];
        if (refreshed) {
            [self _postStateDidChange];
        }
    }];
}

- (void)finishUpload:(NSUInteger)token filePath:(NSString *)filePath
{
    [self _runOnMain:^{
        VLCTransferItem *item = self->_activeUploads[@(token)];
        if (!item) {
            return;
        }
        [self->_activeUploads removeObjectForKey:@(token)];
        [item markCompletedWithFilePath:filePath];
        [self->_completed addObject:item];
        [self _postStateDidChange];
    }];
}

- (void)failUpload:(NSUInteger)token errorDescription:(NSString *)description
{
    [self _runOnMain:^{
        VLCTransferItem *item = self->_activeUploads[@(token)];
        if (!item) {
            return;
        }
        [self->_activeUploads removeObjectForKey:@(token)];
        [item markFailedWithError:description ?: @""];
        [self->_failed addObject:item];
        [self _postStateDidChange];
    }];
}

- (void)cancelUpload:(NSUInteger)token
{
    [self _runOnMain:^{
        if (self->_activeUploads[@(token)]) {
            [self->_activeUploads removeObjectForKey:@(token)];
            [self _postStateDidChange];
        }
    }];
}

#pragma mark - external download source
- (NSUInteger)startExternalDownloadWithName:(NSString *)name
{
    NSUInteger token;
    @synchronized (self) {
        token = ++_nextExternalDownloadToken;
    }
    [self _runOnMain:^{
        self->_activeExternalDownloads[@(token)] = [VLCTransferItem downloadItemWithName:name];
        [self _postStateDidChange];
    }];
    return token;
}

- (void)updateExternalDownload:(NSUInteger)token receivedBytes:(long long)received expectedBytes:(long long)expected
{
    [self _runOnMain:^{
        VLCTransferItem *item = self->_activeExternalDownloads[@(token)];
        if (!item) {
            return;
        }
        if ([item ingestReceivedBytes:received expectedBytes:expected]) {
            [self _postStateDidChange];
        }
    }];
}

- (void)finishExternalDownload:(NSUInteger)token filePath:(NSString *)filePath
{
    [self _runOnMain:^{
        VLCTransferItem *item = self->_activeExternalDownloads[@(token)];
        if (!item) {
            return;
        }
        [self->_activeExternalDownloads removeObjectForKey:@(token)];
        [item markCompletedWithFilePath:filePath];
        [self->_completed addObject:item];
        [self _postStateDidChange];
    }];
}

- (void)failExternalDownload:(NSUInteger)token errorDescription:(NSString *)description
{
    [self _runOnMain:^{
        VLCTransferItem *item = self->_activeExternalDownloads[@(token)];
        if (!item) {
            return;
        }
        [self->_activeExternalDownloads removeObjectForKey:@(token)];
        [item markFailedWithError:description ?: @""];
        [self->_failed addObject:item];
        [self _postStateDidChange];
    }];
}
#if (TARGET_OS_IOS || TARGET_OS_WATCH) && !NO_WATCH
#pragma mark - watch source
- (void)addWatchTransferWithName:(NSString *)name fileTransfer:(WCSessionFileTransfer *)fileTransfer urlString:(NSString *)urlString transferredBytes:(long long)transferredBytes expectedSize:(long long)expectedSize
{
    [self _runOnMain:^{
        [self->_activeWatchTransfers setObject:[VLCTransferItem watchTransferItemWithName:name urlString:urlString transferredBytes:transferredBytes expectedSize:expectedSize] forKey:fileTransfer];
        [self _postStateDidChange];
    }];
}

- (void)updateWatchTransfer:(WCSessionFileTransfer *)fileTransfer receivedBytes:(long long)received expectedBytes:(long long)expected
{
    [self _runOnMain:^{
        VLCTransferItem *item = [self->_activeWatchTransfers objectForKey:fileTransfer];
        if (!item) {
            return;
        }
        if ([item ingestReceivedBytes:received expectedBytes:expected]) {
            [self _postStateDidChange];
        }
    }];
}

- (void)finishWatchTransfer:(WCSessionFileTransfer *)fileTransfer filePath:(NSString *)filePath
{
    [self _runOnMain:^{
        VLCTransferItem *item = [self->_activeWatchTransfers objectForKey:fileTransfer];
        if (!item) {
            return;
        }
        [self->_activeWatchTransfers removeObjectForKey:fileTransfer];
        [item markCompletedWithFilePath:filePath];
        [self->_completed addObject:item];
        [self _postStateDidChange];
    }];
}

- (void)failWatchTransfer:(WCSessionFileTransfer *)fileTransfer errorDescription:(NSString *)description
{
    [self _runOnMain:^{
        VLCTransferItem *item = [self->_activeWatchTransfers objectForKey:fileTransfer];
        if (!item) {
            return;
        }
        [self->_activeWatchTransfers removeObjectForKey:fileTransfer];
        [item markFailedWithError:description ?: @""];
        [self->_failed addObject:item];
        [self _postStateDidChange];
        [fileTransfer.progress removeObserver:self
                                forKeyPath:@"fractionCompleted"
                                   context:(__bridge void *)fileTransfer];
    }];
}

- (void)cancelWatchTransfer:(VLCTransferItem *)item
{
    [self _runOnMain:^{
        for (WCSessionFileTransfer *fileTransfer in self->_activeWatchTransfers) {
            if ([fileTransfer.file.fileURL.absoluteString isEqualToString:item.urlString]) {
                [fileTransfer cancel];
                [self->_activeWatchTransfers removeObjectForKey:fileTransfer];
                [self _postStateDidChange];
                [self->_failed addObject:item];
                [fileTransfer.progress removeObserver:self
                                        forKeyPath:@"fractionCompleted"
                                           context:(__bridge void *)fileTransfer];
                break;
            }
        }
    }];
}


- (void)observeOutstandingWatchTransfers
{
    if (![WCSession isSupported]) {
        return;
    }

    WCSession *session = [WCSession defaultSession];

    for (WCSessionFileTransfer *fileTransfer in session.outstandingFileTransfers) {
        [self observeWatchFileTransfer: fileTransfer];
    }
}

- (void) handleFileTransferDidStart:(NSNotification *)notification
{
    WCSessionFileTransfer *fileTransfer = notification.object;
    if (fileTransfer == nil) {
        return;
    }
    [self observeWatchFileTransfer: fileTransfer];
}

- (void) observeWatchFileTransfer:(WCSessionFileTransfer *)fileTransfer
{
    if ([_activeWatchTransfers objectForKey:fileTransfer]) {
        return;
    }

    NSString *fileName = fileTransfer.file.metadata[kVLCiPhoneMediaFileName];
    long long fileSize = [fileTransfer.file.metadata[kVLCiPhoneMediaFileSize] longLongValue];
    double progress = fileTransfer.progress.fractionCompleted;
    long long transferredBytes = fileSize * progress;

    [self addWatchTransferWithName:fileName fileTransfer:fileTransfer urlString:fileTransfer.file.fileURL.absoluteString transferredBytes: transferredBytes expectedSize:fileSize];
    [self observeWatchFileTransferProgress: fileTransfer];
}

- (void)observeWatchFileTransferProgress:(WCSessionFileTransfer *)fileTransfer
{
    [fileTransfer.progress addObserver:self
                            forKeyPath:@"fractionCompleted"
                               options:NSKeyValueObservingOptionNew
                               context:(__bridge void *)fileTransfer];
    [_observedWatchTransfers addObject:fileTransfer];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"fractionCompleted"]) {
        WCSessionFileTransfer *fileTransfer = (__bridge WCSessionFileTransfer *)context;
        long long fileSize = [fileTransfer.file.metadata[kVLCiPhoneMediaFileSize] longLongValue];
        long long transferredBytes = fileSize * [change[NSKeyValueChangeNewKey] doubleValue];
        [self updateWatchTransfer:fileTransfer receivedBytes:transferredBytes expectedBytes:fileSize];
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}
#endif

#pragma mark - list state
- (NSArray<VLCTransferItem *> *)_activeTransferItems
{
    NSMutableArray<VLCTransferItem *> *items = [NSMutableArray array];
    if (_activeDownloadItem) {
        [items addObject:_activeDownloadItem];
    }
    NSArray<NSNumber *> *downloadTokens = [_activeExternalDownloads.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSNumber *token in downloadTokens) {
        [items addObject:_activeExternalDownloads[token]];
    }
    NSArray<NSNumber *> *tokens = [_activeUploads.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSNumber *token in tokens) {
        [items addObject:_activeUploads[token]];
    }
#if (TARGET_OS_IOS || TARGET_OS_WATCH) && !NO_WATCH
    NSArray<WCSessionFileTransfer *> *fileTransfers = [[_activeWatchTransfers keyEnumerator] allObjects];
    for (WCSessionFileTransfer *fileTransfer in fileTransfers) {
        [items addObject:[_activeWatchTransfers objectForKey:fileTransfer]];
    }
#endif
    return items;
}

- (NSArray<VLCTransferItem *> *)inProgressItems
{
    NSMutableArray<VLCTransferItem *> *items = [[self _activeTransferItems] mutableCopy];
    @synchronized (_currentDownloads) {
        for (VLCMedia *media in _currentDownloads) {
            [items addObject:[VLCTransferItem queuedDownloadItemWithName:[self _displayNameForQueuedMedia:media]
                                                              urlString:media.url.absoluteString]];
        }
    }
    return items;
}

- (NSArray<VLCTransferItem *> *)completedItems
{
    return [_completed copy];
}

- (NSArray<VLCTransferItem *> *)failedItems
{
    return [_failed copy];
}

- (void)cancelInProgressItem:(VLCTransferItem *)item
{
    if (item.direction == VLCTransferDirectionDownload && !item.active) {
        @synchronized (_currentDownloads) {
            NSUInteger index = NSNotFound;
            for (NSUInteger i = 0; i < _currentDownloads.count; i++) {
                if ([[_currentDownloads[i] url].absoluteString isEqualToString:item.urlString]) {
                    index = i;
                    break;
                }
            }
            if (index != NSNotFound) {
                VLCMedia *media = _currentDownloads[index];
                [_userDefinedFileNameForDownloadItem removeObjectForKey:media.url];
                [_currentDownloads removeObjectAtIndex:index];
            }
        }
        [self _postStateDidChange];
    } else if (item.direction == VLCTransferDirectionDownload && item.active) {
        if ([[_activeExternalDownloads allValues] containsObject:item]) {
            return;
        }
        [self cancelCurrentDownload];
    } else if (item.direction == VLCTransferDirectionUpload && item.active && item.type == VLCTransferTypeWatch) {
#if (TARGET_OS_IOS || TARGET_OS_WATCH) && !NO_WATCH
        [self cancelWatchTransfer:item];
#endif
    }
}

- (void)removeFailedItem:(VLCTransferItem *)item
{
    [_failed removeObjectIdenticalTo:item];
    [self _postStateDidChange];
}

@end
