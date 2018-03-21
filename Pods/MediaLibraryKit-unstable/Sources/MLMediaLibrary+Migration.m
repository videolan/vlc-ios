/*****************************************************************************
 * MLMediaLibrary+Migration.m
 * MobileMediaLibraryKit
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "MLMediaLibrary+Migration.h"
#import "MLTitleDecrapifier.h"
#import "MLFile.h"
#import "MLLabel.h"
#import "MLShowEpisode.h"
#import "MLShow.h"
#import "MLThumbnailerQueue.h"
#import "MLAlbumTrack.h"
#import "MLAlbum.h"
#if HAVE_BLOCK
#import "MLMovieInfoGrabber.h"
#import "MLTVShowInfoGrabber.h"
#import "MLTVShowEpisodesInfoGrabber.h"
#endif

@implementation MLMediaLibrary (Migration)

- (void)_setupLibraryPathPriorToMigration
{
    NSString *basePath = nil;
    NSString *groupPath = [self _groupURL].path;
    if ([self _migrationToGroupsNeeded] || groupPath == nil) {
        basePath = [self _oldBasePath];
    } else {
        basePath = groupPath;
    }
    self.libraryBasePath = basePath;
}

- (BOOL)_libraryMigrationNeeded
{
    BOOL migrationNeeded = [self _migrationToGroupsNeeded];
    if (!migrationNeeded) {
        NSError *error;
        migrationNeeded = [self _migrationNeeded:&error];
        if (error!=nil) {
            APLog(@"Failed to check if model migration is needed %@", error);
        }
    }
    return migrationNeeded;
}

- (void)_migrateLibrary
{
    // triggers automatic model migration
    [self persistentStoreCoordinator];

    if (![self _migrationToGroupsNeeded]) {
        return;
    }

    NSError *error;
    NSString *groupPath = [self _groupURL].path;
    if ([self _migrateLibraryToBasePath:groupPath error:&error]) {
        APLog(@"Failed to migrate to group path with error: %@",error);
    }
}

#pragma mark - model version migrations

- (BOOL)_migrationNeeded:(NSError **) migrationCheckError
{
    BOOL migrationNeeded = NO;

    if ([[NSFileManager defaultManager] fileExistsAtPath:((MLMediaLibrary *)[MLMediaLibrary sharedMediaLibrary]).persistentStoreURL.path]) {
        NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                                  URL:((MLMediaLibrary *)[MLMediaLibrary sharedMediaLibrary]).persistentStoreURL
                                                                                                error:migrationCheckError];
        if (*migrationCheckError) {
            return NO;
        }
        NSManagedObjectModel *destinationModel = [[MLMediaLibrary sharedMediaLibrary] managedObjectModel];
        migrationNeeded = ![destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
    }

    return migrationNeeded;
}


#pragma mark - group path migration

- (BOOL)_migrationToGroupsNeeded
{
    /*
     * We can't and don't need to migrate to groups on pre-iOS 7
     */
    if (![[NSFileManager defaultManager] respondsToSelector:@selector(containerURLForSecurityApplicationGroupIdentifier:)]) {
        return NO;
    }

    if ([self _groupURL] == nil) {
        return NO;
    }

    NSString *oldPersistentStorePath = [[self _oldBasePath] stringByAppendingPathComponent: @"MediaLibrary.sqlite"];
    return [[NSFileManager defaultManager] fileExistsAtPath:oldPersistentStorePath];
}

- (NSString *)_oldBasePath
{
    NSSearchPathDirectory directory = NSLibraryDirectory;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    return paths.firstObject;
}

- (NSURL *)_groupURL {
    if (![[NSFileManager defaultManager] respondsToSelector:@selector(containerURLForSecurityApplicationGroupIdentifier:)]) {
        return nil;
    }

    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:self.applicationGroupIdentifier];
#if TARGET_IPHONE_SIMULATOR
    // if something went wrong with the entitlements in the Simulator
    if (!groupURL) {
        NSArray *pathComponents = [[[NSBundle mainBundle] bundlePath] pathComponents];
        pathComponents = [pathComponents subarrayWithRange:NSMakeRange(0, pathComponents.count-4)];
        NSString *groupComponent = [@"Shared/AppGroup/fake-" stringByAppendingString:self.applicationGroupIdentifier];
        NSString *groupPath = [[NSString pathWithComponents:pathComponents] stringByAppendingPathComponent:groupComponent];
        groupURL = [NSURL fileURLWithPath:groupPath];
        [[NSFileManager defaultManager] createDirectoryAtURL:groupURL withIntermediateDirectories:YES attributes:nil error:nil];
    }
#endif
    return groupURL;
}

- (BOOL)_migrateLibraryToBasePath:(NSString *)basePath error:(NSError *__autoreleasing *)migrationError
{
    BOOL success = YES;
    NSPersistentStoreCoordinator *coordinater = [self persistentStoreCoordinator];
    if (!coordinater) {
        APLog(@"no persistent store coordinator found, migration will fail");
        return NO;
    }
    NSURL *oldStoreURL = self.persistentStoreURL;
    NSPersistentStore *oldStore = [coordinater persistentStoreForURL:oldStoreURL];
    NSString *oldThumbnailPath = self.thumbnailFolderPath;

    self.libraryBasePath = basePath;

    NSURL *newURL = self.persistentStoreURL;
    NSError *error = nil;

#ifdef DEBUG
    // when debugging we want to clean the new base path before doing the migration
    NSError *deleteError;
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:basePath] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
    for (NSString *pathToDelete in enumerator) {
        if (![[NSFileManager defaultManager] removeItemAtPath:pathToDelete error:&deleteError]) {
            APLog(@"Failed to clear object from new base path for migration debugging: %@",deleteError);
        }
    }
#endif

    NSURL *directoryURL = [newURL URLByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
        APLog(@"Failed to created new directories for url: %@",directoryURL);
    }
    NSPersistentStore *newStore = [coordinater migratePersistentStore:oldStore
                                                                toURL:newURL
                                                              options:oldStore.options
                                                             withType:oldStore.type
                                                                error:&error];
    if (!newStore) {
        success = NO;
        APLog(@"Failed to migrate library to new path with error: %@",error);
    } else {
        NSString *oldStorePath = [oldStoreURL path];
        // remove all sqlite remainings
        for (NSString *extension in @[@"",@"-wal",@"-shm"]) {
            NSString *path = [oldStorePath stringByAppendingString:extension];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path] && ![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
                APLog(@"Failed to remove old library with error: %@",error);
            }
        }
    }

    NSString *newThumbnailPath = self.thumbnailFolderPath;
    if (![[NSFileManager defaultManager] moveItemAtPath:oldThumbnailPath toPath:newThumbnailPath error:&error]) {
        success = NO;
        APLog(@"Failed to move thumbnails to new path with error: %@",error);
    }

    if (migrationError != nil && error) {
        *migrationError = error;
    }
    return success;
}

@end
