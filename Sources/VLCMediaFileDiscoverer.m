/*****************************************************************************
 * VLCMediaFileDiscoverer.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMediaFileDiscoverer.h"
#import "NSString+SupportedMedia.h"

const float MediaTimerInterval = 2.f;

@interface VLCMediaFileDiscoverer () {
    NSMutableArray *_observers;
    dispatch_source_t _directorySource;

    NSString *_directoryPath;
    NSArray *_directoryFiles;
    NSMutableDictionary *_addedFilesMapping;
    NSTimer *_addMediaTimer;
}

@end

@implementation VLCMediaFileDiscoverer

- (id)init
{
    self = [super init];
    if (self) {
        _observers = [NSMutableArray array];
        _addedFilesMapping = [NSMutableDictionary dictionary];
    }

    return self;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static VLCMediaFileDiscoverer *instance;
    dispatch_once(&onceToken, ^{
        instance = [VLCMediaFileDiscoverer new];
    });

    return instance;
}

#pragma mark - observation

- (void)addObserver:(id<VLCMediaFileDiscovererDelegate>)delegate
{
    [_observers addObject:delegate];
}

- (void)removeObserver:(id<VLCMediaFileDiscovererDelegate>)delegate
{
    [_observers removeObject:delegate];
}

- (void)notifyFileDeleted:(NSString *)fileName
{
    if (![fileName isSupportedMediaFormat] && ![fileName isSupportedAudioMediaFormat])
        return;

    for (id<VLCMediaFileDiscovererDelegate> delegate in _observers) {
        if ([delegate respondsToSelector:@selector(mediaFileDeleted:)]) {
            [delegate mediaFileDeleted:[self filePath:fileName]];
        }
    }
}

- (void)notifyFileAdded:(NSString *)fileName loading:(BOOL)isLoading
{
    for (id<VLCMediaFileDiscovererDelegate> delegate in _observers) {
        if ([delegate respondsToSelector:@selector(mediaFileAdded:loading:)]) {
            [delegate mediaFileAdded:[self filePath:fileName] loading:isLoading];
        }
    }
}

- (void)notifySizeChanged:(NSString *)fileName size:(unsigned long long)size
{
    for (id<VLCMediaFileDiscovererDelegate> delegate in _observers) {
        if ([delegate respondsToSelector:@selector(mediaFileChanged:size:)]) {
            [delegate mediaFileChanged:[self filePath:fileName] size:size];
        }
    }
}

#pragma mark - discovering

- (void)startDiscovering:(NSString *)directoryPath
{
    _directoryPath = directoryPath;
     _directoryFiles = [self directoryFiles];

    int const folderDescriptor = open([directoryPath fileSystemRepresentation], O_EVTONLY);
    _directorySource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, folderDescriptor,
                                              DISPATCH_VNODE_WRITE, DISPATCH_TARGET_QUEUE_DEFAULT);

    dispatch_source_set_event_handler(_directorySource, ^(){
        unsigned long const data = dispatch_source_get_data(_directorySource);
        if (data & DISPATCH_VNODE_WRITE) {
            // Do all the work on the main thread,
            // including timer scheduling, notifications delivering
            dispatch_async(dispatch_get_main_queue(), ^{
                [self directoryDidChange];
            });
        }
    });

    dispatch_source_set_cancel_handler(_directorySource, ^(){
        close(folderDescriptor);
    });

    dispatch_resume(_directorySource);
}

- (void)stopDiscovering
{
    dispatch_source_cancel(_directorySource);

    [self invalidateTimer];
}

#pragma mark -

- (NSArray *)directoryFiles
{
    NSArray *foundFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_directoryPath
                                                                              error:nil];
    return foundFiles;
}

- (NSString *)filePath:(NSString *)fileName
{
    return [_directoryPath stringByAppendingPathComponent:fileName];
}

#pragma mark - directory watcher delegate

- (void)directoryDidChange
{
    NSArray *foundFiles = [self directoryFiles];

    if (_directoryFiles.count > foundFiles.count) { // File was deleted
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"not (self in %@)", foundFiles];
        NSArray *deletedFiles = [_directoryFiles filteredArrayUsingPredicate:filterPredicate];

        for (NSString *fileName in deletedFiles) {
            [self notifyFileDeleted:fileName];
        }

    } else if (_directoryFiles.count < foundFiles.count) { // File was added
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"not (self in %@)", _directoryFiles];
        NSArray *addedFiles = [foundFiles filteredArrayUsingPredicate:filterPredicate];

        for (NSString *fileName in addedFiles) {
            if ([fileName isSupportedMediaFormat] || [fileName isSupportedAudioMediaFormat]) {
                [_addedFilesMapping setObject:@(0) forKey:fileName];
                [self notifyFileAdded:fileName loading:YES];
            }
        }

        if (![_addMediaTimer isValid]) {
            _addMediaTimer = [NSTimer scheduledTimerWithTimeInterval:MediaTimerInterval
                                          target:self selector:@selector(addFileTimerFired)
                                                            userInfo:nil repeats:YES];
        }
    }

    _directoryFiles = foundFiles;
}

#pragma mark - media timer

- (void)addFileTimerFired
{
    NSArray *allKeys = [_addedFilesMapping allKeys];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    for (NSString *fileName in allKeys) {
        NSString *filePath = [self filePath:fileName];
        if (![fileManager fileExistsAtPath:filePath]) {
            [_addedFilesMapping removeObjectForKey:fileName];
            continue;
        }

        NSNumber *prevFetchedSize = [_addedFilesMapping objectForKey:fileName];

        NSDictionary *attribs = [fileManager attributesOfItemAtPath:filePath error:nil];
        NSNumber *updatedSize = [attribs objectForKey:NSFileSize];
        if (!updatedSize)
            continue;

        [self notifySizeChanged:fileName size:[updatedSize unsignedLongLongValue]];

        if ([prevFetchedSize compare:updatedSize] == NSOrderedSame) {
            [_addedFilesMapping removeObjectForKey:fileName];
            [self notifyFileAdded:fileName loading:NO];

        } else
            [_addedFilesMapping setObject:updatedSize forKey:fileName];
    }

    if (_addedFilesMapping.count == 0)
        [self invalidateTimer];
}

- (void)invalidateTimer
{
    [_addMediaTimer invalidate];
    _addMediaTimer = nil;
}

@end
