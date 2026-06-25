/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCTopShelfManager.h"
#import "VLCTopShelfConstants.h"
#import "VLCAppCoordinator.h"
#import "VLC-Swift.h"
#import <TVServices/TVServices.h>

static const NSUInteger VLCTopShelfItemCount = 12;
static const NSUInteger VLCTopShelfThumbnailWidth = 640;
static const NSUInteger VLCTopShelfThumbnailHeight = 360;

@interface VLCTopShelfManager () <MediaLibraryObserver>
@property (nonatomic, copy) NSSet<NSNumber *> *currentIdentifiers;
@property (nonatomic, assign) BOOL observing;
@end

@implementation VLCTopShelfManager

+ (VLCTopShelfManager *)sharedManager
{
    static VLCTopShelfManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[VLCTopShelfManager alloc] init];
    });
    return sharedManager;
}

- (void)update
{
    MediaLibraryService *service = [VLCAppCoordinator sharedInstance].mediaLibraryService;
    if (!self.observing) {
        [service addObserver:self];
        self.observing = YES;
    }
    [self writeSnapshotForService:service];
}

- (void)writeSnapshotForService:(MediaLibraryService *)service
{
    NSString *groupIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MLKitGroupIdentifier"];
    if (groupIdentifier.length == 0) {
        return;
    }

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:groupIdentifier];
    NSURL *container = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    if (defaults == nil || container == nil) {
        return;
    }

    NSURL *imageDirectory = [container URLByAppendingPathComponent:kVLCTopShelfImageDirectory isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:imageDirectory withIntermediateDirectories:YES attributes:nil error:nil];

    NSMutableSet<NSNumber *> *identifiers = [NSMutableSet set];

    NSArray<VLCMLMedia *> *recent = [service mediaOfType:VLCMLMediaTypeVideo
                                         sortingCriteria:VLCMLSortingCriteriaInsertionDate
                                                    desc:YES];
    NSMutableArray<NSDictionary *> *items = [NSMutableArray array];
    for (VLCMLMedia *media in recent) {
        if (items.count >= VLCTopShelfItemCount) {
            break;
        }
        [items addObject:[self entryForMedia:media intoDirectory:imageDirectory]];
        [identifiers addObject:@(media.identifier)];
    }

    self.currentIdentifiers = identifiers;
    [self pruneImagesInDirectory:imageDirectory keepingIdentifiers:identifiers];

    NSDictionary *snapshot = @{ kVLCTopShelfItemsKey : items,
                                kVLCTopShelfSectionTitleKey : NSLocalizedString(@"CACHED_MEDIA", nil) };
    NSData *data = [NSJSONSerialization dataWithJSONObject:snapshot options:0 error:nil];
    if (data != nil) {
        [defaults setObject:data forKey:kVLCTopShelfDefaultsKey];
    } else {
        [defaults removeObjectForKey:kVLCTopShelfDefaultsKey];
    }

    [TVTopShelfContentProvider topShelfContentDidChange];
}

- (NSDictionary *)entryForMedia:(VLCMLMedia *)media
                  intoDirectory:(NSURL *)imageDirectory
{
    NSMutableDictionary *entry = [NSMutableDictionary dictionary];
    entry[kVLCTopShelfItemIdentifierKey] = @(media.identifier);
    entry[kVLCTopShelfItemTitleKey] = media.title ?: @"";

    NSString *imageName = [self exportThumbnailForMedia:media intoDirectory:imageDirectory];
    if (imageName.length > 0) {
        entry[kVLCTopShelfItemImageKey] = imageName;
    }

    return entry;
}

- (NSString *)exportThumbnailForMedia:(VLCMLMedia *)media
                        intoDirectory:(NSURL *)directory
{
    NSURL *source = [media thumbnail];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (source == nil || ![fileManager fileExistsAtPath:source.path]) {
        if (media.thumbnailStatus == VLCMLThumbnailStatusMissing) {
            [media requestThumbnailOfType:VLCMLThumbnailSizeTypeThumbnail
                             desiredWidth:VLCTopShelfThumbnailWidth
                            desiredHeight:VLCTopShelfThumbnailHeight
                               atPosition:0.03f];
        }
        return nil;
    }

    NSString *fileName = [NSString stringWithFormat:@"%lld.jpg", (long long)media.identifier];
    NSURL *destination = [directory URLByAppendingPathComponent:fileName];

    [fileManager removeItemAtURL:destination error:nil];
    if (![fileManager copyItemAtURL:source toURL:destination error:nil]) {
        return nil;
    }

    return fileName;
}

- (void)pruneImagesInDirectory:(NSURL *)directory keepingIdentifiers:(NSSet<NSNumber *> *)identifiers
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSURL *> *files = [fileManager contentsOfDirectoryAtURL:directory
                                        includingPropertiesForKeys:nil
                                                           options:0
                                                             error:nil];
    for (NSURL *file in files) {
        NSString *base = file.URLByDeletingPathExtension.lastPathComponent;
        if (![identifiers containsObject:@(base.longLongValue)]) {
            [fileManager removeItemAtURL:file error:nil];
        }
    }
}

#pragma mark - MediaLibraryObserver

- (void)medialibrary:(MediaLibraryService *)medialibrary didAddVideos:(NSArray<VLCMLMedia *> *)videos
{
    [self writeSnapshotForService:medialibrary];
}

- (void)medialibrary:(MediaLibraryService *)medialibrary didModifyVideos:(NSArray<VLCMLMedia *> *)videos
{
    [self writeSnapshotForService:medialibrary];
}

- (void)medialibrary:(MediaLibraryService *)medialibrary didDeleteMediaWithIds:(NSArray<NSNumber *> *)ids
{
    [self writeSnapshotForService:medialibrary];
}

- (void)medialibrary:(MediaLibraryService *)medialibrary
       thumbnailReady:(VLCMLMedia *)media
                 type:(VLCMLThumbnailSizeType)type
              success:(BOOL)success
{
    if (!success || type != VLCMLThumbnailSizeTypeThumbnail) {
        return;
    }
    if (![self.currentIdentifiers containsObject:@(media.identifier)]) {
        return;
    }
    [self writeSnapshotForService:medialibrary];
}

@end
