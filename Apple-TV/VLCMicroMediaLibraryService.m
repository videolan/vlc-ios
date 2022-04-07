/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMicroMediaLibraryService.h"
#import "VLCMediaFileDiscoverer.h"
#import "NSString+SupportedMedia.h"
#import "VLC-Swift.h"

@interface VLCMicroMediaLibraryService() <VLCMediaFileDiscovererDelegate>

@property (strong, nonatomic) SortedMediaFiles *discoveredFiles;
@property (strong, nonatomic) VLCMediaThumbnailerCache *thumbnailerCache;

@end

@implementation VLCMicroMediaLibraryService

+ (instancetype)sharedInstance
{
    static VLCMicroMediaLibraryService *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCMicroMediaLibraryService new];
        [sharedInstance setup];
    });

    return sharedInstance;
}

- (void)setup
{
    self.thumbnailerCache = [VLCMediaThumbnailerCache alloc];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(thumbnailerUpdated)
                                                 name:@"thumbnailIComplete" object:nil];

    VLCMediaFileDiscoverer *discoverer = [VLCMediaFileDiscoverer sharedInstance];
    discoverer.filterResultsForPlayability = NO;

    self.discoveredFiles = [[SortedMediaFiles alloc] init];

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    discoverer.directoryPath = [[searchPaths firstObject] stringByAppendingPathComponent:kVLCHTTPUploadDirectory];
    [discoverer addObserver:self];
    [discoverer startDiscovering];
}

- (void)updateMediaList
{
    [[VLCMediaFileDiscoverer sharedInstance] updateMediaList];
}

- (NSInteger)numberOfDiscoveredMedia
{
    NSInteger ret = 0;
    @synchronized(self.discoveredFiles) {
        ret = self.discoveredFiles.count;
    }
    return ret;
}

- (NSString *)filenameOfItemAtIndex:(NSInteger)index
{
    NSString *ret = nil;
    @synchronized(self.discoveredFiles) {
        if (index < self.discoveredFiles.count) {
            ret = [self.discoveredFiles[index] lastPathComponent];
        }
    }
    return ret;
}

- (void)deleteFileAtIndex:(NSInteger)index
{
    NSString *fileToDelete = nil;
    @synchronized(self.discoveredFiles) {
        fileToDelete = self.discoveredFiles[index];
        [self.discoveredFiles remove:fileToDelete];
    }
    [[NSFileManager defaultManager] removeItemAtPath:fileToDelete error:nil];
}

- (VLCMediaList *)mediaList
{
    NSURL *url;
    VLCMediaList *medialist = [[VLCMediaList alloc] init];

    @synchronized(self.discoveredFiles) {
        NSUInteger count = self.discoveredFiles.count;
        for (NSUInteger x = 0; x < count; x++) {
            url = [NSURL fileURLWithPath:self.discoveredFiles[x]];
            [medialist addMedia:[VLCMedia mediaWithURL:url]];
        }
    }

    return medialist;
}

- (NSArray *)rawListOfFiles
{
    NSArray *ret;
    @synchronized (self.discoveredFiles) {
        ret = self.discoveredFiles.readonlycopy;
    }

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kVLCSaveDebugLogs]) {
        ret = [self injectLogsToMedia:ret];
    }

    return ret;
}

#pragma mark - thumbnail cache

- (void)thumbnailerUpdated
{
    [self.delegate mediaListUpdatedForService:self];
}

#pragma mark - media file discovery
- (void)mediaFilesFoundRequiringAdditionToStorageBackend:(NSArray<NSString *> *)foundFiles
{
    @synchronized(self.discoveredFiles) {
        self.discoveredFiles = [SortedMediaFiles fromArray:foundFiles];
            for (int cnt = 0; cnt < [self.discoveredFiles count]; cnt++) {
                NSString *path = self.discoveredFiles[cnt];
                if (path.isSupportedMediaFormat) {
                    [self.thumbnailerCache getVideoThumbnail:path];
                }
            }
    }

    [self.delegate mediaListUpdatedForService:self];
}

- (void)mediaFileAdded:(NSString *)filePath loading:(BOOL)isLoading
{
    @synchronized(self.discoveredFiles) {
        [self.discoveredFiles add:filePath];
    }

    [self.delegate mediaListUpdatedForService:self];
}

- (void)mediaFileDeleted:(NSString *)filePath
{
    @synchronized(self.discoveredFiles) {
        [self.discoveredFiles remove:filePath];
        [self.thumbnailerCache removeThumbnail:filePath];
    }

    [self.delegate mediaListUpdatedForService:self];
}

- (NSURL *)thumbnailURLForItemAtIndex:(NSInteger)index
{
    NSURL *thumbnailURL = nil;
    NSString *title;

    @synchronized(self.discoveredFiles) {
        if (self.discoveredFiles.count > index) {
            NSString * file = self.discoveredFiles[index];
            title = [file lastPathComponent];
            if (title.isSupportedMediaFormat) {
                thumbnailURL = [self.thumbnailerCache getThumbnailURL:file];
            }
        }
    }
    return thumbnailURL;
}

- (NSURL *)thumbnailURLForItemWithPath:(NSString *)path
{
    return [self.thumbnailerCache getThumbnailURL:path];
}

- (NSString *)titleForItemAtIndex:(NSInteger)index
{
    NSString *title;
    @synchronized(self.discoveredFiles) {
        if (self.discoveredFiles.count > index) {
            NSString *file = self.discoveredFiles[index];
            title = [file lastPathComponent];
        }
    }
    return title;
}

- (UIImage *)placeholderImageForItemWithTitle:(NSString *)title
{
    if (title.isSupportedMediaFormat) {
        return [UIImage imageNamed:@"movie"];
    } else if (title.isSupportedAudioMediaFormat) {
        return [UIImage imageNamed:@"audio"];
    }

    return [UIImage imageNamed:@"blank"];
}

#pragma mark - debug log exposure

- (NSArray *)injectLogsToMedia:(NSArray *)media
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* logFilePath = [searchPaths.firstObject stringByAppendingPathComponent:@"Logs"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL ret = [fileManager fileExistsAtPath:logFilePath];
    if (!ret) {
        /* we don't have logs, return early */
        return media;
    }
    NSArray *listOfLogs = [fileManager contentsOfDirectoryAtPath:logFilePath error:nil];
    NSUInteger logCount = listOfLogs.count;
    NSMutableArray *logsWithPaths = [NSMutableArray arrayWithCapacity:logCount];
    for (NSUInteger x = 0; x < logCount; x++) {
        [logsWithPaths addObject:[logFilePath stringByAppendingPathComponent:listOfLogs[x]]];
    }
    return [media arrayByAddingObject:[logsWithPaths copy]];
}

@end
