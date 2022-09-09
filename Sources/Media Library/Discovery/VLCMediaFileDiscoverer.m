/*****************************************************************************
 * VLCMediaFileDiscoverer.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMediaFileDiscoverer.h"
#import "NSString+SupportedMedia.h"
#import "VLC-Swift.h"

const float MediaTimerInterval = 2.f;

@interface VLCMediaFileDiscoverer () {
    NSMutableArray *_observers;
    dispatch_source_t _directorySource;

    NSArray *_directoryFiles;
    NSMutableDictionary *_addedFilesMapping;
    NSTimer *_addMediaTimer;
    NSArray *_discoveredFilePath;
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
        instance.filterResultsForPlayability = YES;
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

- (void)startDiscovering
{
    if (!_directoryPath) {
        APLog(@"file discovery failed, no path was set");
        return;
    } else
        APLog(@"will discover files in path: '%@'", _directoryPath);

    _directoryFiles = [self directoryFiles];

    int const folderDescriptor = open([_directoryPath fileSystemRepresentation], O_EVTONLY);
    _directorySource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, folderDescriptor,
                                              DISPATCH_VNODE_WRITE, DISPATCH_TARGET_QUEUE_DEFAULT);

    dispatch_source_set_event_handler(_directorySource, ^(){
        unsigned long const data = dispatch_source_get_data(self->_directorySource);
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

        for (NSString *fileName in deletedFiles)
            [self notifyFileDeleted:fileName];
    } else if (_directoryFiles.count < foundFiles.count) { // File was added
        [NSFileManager.defaultManager createFileAtPath:[NSString pathWithComponents:@[_directoryPath, NSLocalizedString(@"MEDIALIBRARY_ADDING_PLACEHOLDER", "")]] contents:nil attributes:nil];
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"not (self in %@)", _directoryFiles];
        NSMutableArray *addedFiles = [NSMutableArray arrayWithArray:[foundFiles filteredArrayUsingPredicate:filterPredicate]];

        for (NSString *fileName in addedFiles) {
            BOOL isDirectory = NO;
            NSString *directoryPath = [self directoryPath];
            NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];

            if (exists && !isDirectory) {
                if (self.filterResultsForPlayability) {
                    if ([fileName isSupportedMediaFormat] || [fileName isSupportedAudioMediaFormat] || [fileName isSupportedPlaylistFormat]) {
                        [_addedFilesMapping setObject:@(0) forKey:fileName];
                        [self notifyFileAdded:fileName loading:YES];
                    }
                } else {
                    [_addedFilesMapping setObject:@(0) forKey:fileName];
                    [self notifyFileAdded:fileName loading:YES];
                }
            } else if (exists && isDirectory) {
                // add folders
                NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
                for (NSString* file in files) {
                    NSString *fullFilePath = [directoryPath stringByAppendingPathComponent:file];
                    isDirectory = NO;
                    exists = [[NSFileManager defaultManager] fileExistsAtPath:fullFilePath isDirectory:&isDirectory];
                    //only add folders or files in folders
                    if ((exists && isDirectory) || ![filePath.lastPathComponent isEqualToString:@"Documents"]) {
                        NSString *folderpath = [filePath stringByReplacingOccurrencesOfString:directoryPath withString:@""];
                        if (![folderpath isEqualToString:@""]) {
                            folderpath = [folderpath stringByAppendingString:@"/"];
                        }
                        NSString *path = [folderpath stringByAppendingString:file];
                        [_addedFilesMapping setObject:@(0) forKey:path];
                        [self notifyFileAdded:path loading:YES];
                    }
                }
            }
            BOOL backupMediaLibrary = [NSUserDefaults.standardUserDefaults boolForKey:kVLCSettingBackupMediaLibrary];
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            [fileURL setExcludedFromBackup:!backupMediaLibrary recursive:NO onlyFirstLevel:NO :nil];

            // Let time to user when he copies a file with Files.app to see that the file has successfully been copied
            NSDictionary *info = [NSDictionary dictionaryWithObject:fileURL forKey:@"fileURL"];
            [NSTimer scheduledTimerWithTimeInterval:5
                                             target:self
                                           selector:@selector(didAddMedia:)
                                           userInfo:info
                                            repeats:NO];
        }

        if (![_addMediaTimer isValid]) {
            _addMediaTimer = [NSTimer scheduledTimerWithTimeInterval:MediaTimerInterval
                                                              target:self selector:@selector(addFileTimerFired)
                                                            userInfo:nil repeats:YES];
        }
    }

    _directoryFiles = foundFiles;
}

- (void)didAddMedia:(NSTimer*)timer
{
#if TARGET_OS_IOS
    BOOL hideMediaLibrary = [NSUserDefaults.standardUserDefaults boolForKey:kVLCSettingHideLibraryInFilesApp];
    [(NSURL*)[timer.userInfo valueForKey:@"fileURL"] setHidden:hideMediaLibrary recursive:NO onlyFirstLevel:NO :nil];
#endif
    [NSFileManager.defaultManager removeItemAtPath:[NSString pathWithComponents:@[_directoryPath, NSLocalizedString(@"MEDIALIBRARY_ADDING_PLACEHOLDER", "")]] error:nil];
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

#pragma mark - media list management

- (void)updateMediaList
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];
        return;
    }

    NSString *directoryPath = [self directoryPath];
    NSMutableArray *foundFiles = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil]];
    NSMutableArray *filePaths = [NSMutableArray array];
    while (foundFiles.count) {
        NSString *fileName = foundFiles.firstObject;
        NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
        [foundFiles removeObject:fileName];

        BOOL isDirectory = NO;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];

        if (exists && !isDirectory) {
            if (self.filterResultsForPlayability) {
                if ([fileName isSupportedMediaFormat] || [fileName isSupportedAudioMediaFormat]) {
                    [filePaths addObject:filePath];
                }
            } else {
                [filePaths addObject:filePath];
            }
        } else if (exists && isDirectory) {
            // add folders
            NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
            for (NSString* file in files) {
                NSString *fullFilePath = [directoryPath stringByAppendingPathComponent:file];
                isDirectory = NO;
                exists = [[NSFileManager defaultManager] fileExistsAtPath:fullFilePath isDirectory:&isDirectory];
                //only add folders or files in folders
                if ((exists && isDirectory) || ![filePath.lastPathComponent isEqualToString:@"Documents"]) {
                    NSString *folderpath = [filePath stringByReplacingOccurrencesOfString:directoryPath withString:@""];
                    if (![folderpath isEqualToString:@""]) {
                        folderpath = [folderpath stringByAppendingString:@"/"];
                    }
                    NSString *path = [folderpath stringByAppendingString:file];
                    [foundFiles addObject:path];
                }
            }
        }
    }
    if (![_discoveredFilePath isEqualToArray:filePaths]) {
        _discoveredFilePath = filePaths;
        for (id<VLCMediaFileDiscovererDelegate> delegate in _observers) {
            if ([delegate respondsToSelector:@selector(mediaFilesFoundRequiringAdditionToStorageBackend:)]) {
                [delegate mediaFilesFoundRequiringAdditionToStorageBackend:[filePaths copy]];
            }
        }
    }
}

@end
