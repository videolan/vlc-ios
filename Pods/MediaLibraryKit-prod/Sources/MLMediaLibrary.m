/*****************************************************************************
 * MLMediaLibrary.m
 * MobileMediaLibraryKit
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2010-2015 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "MLMediaLibrary.h"
#import "MLTitleDecrapifier.h"
#import "MLFile.h"
#import "MLLabel.h"
#import "MLShowEpisode.h"
#import "MLShow.h"
#import "MLThumbnailerQueue.h"
#import "MLAlbumTrack.h"
#import "MLAlbum.h"
#import "MLFileParserQueue.h"
#import "MLCrashPreventer.h"
#import "MLMediaLibrary+Migration.h"
#import <sys/sysctl.h> // for sysctlbyname

#if TARGET_OS_IOS
#import <CoreSpotlight/CoreSpotlight.h>
#endif

#if HAVE_BLOCK
#import "MLMovieInfoGrabber.h"
#import "MLTVShowInfoGrabber.h"
#import "MLTVShowEpisodesInfoGrabber.h"
#endif

@interface MLMediaLibrary ()
{
    NSManagedObjectContext *_managedObjectContext;
    NSManagedObjectModel   *_managedObjectModel;

    BOOL _allowNetworkAccess;
    int _deviceSpeedCategory;

    NSString *_thumbnailFolderPath;
    NSString *_databaseFolderPath;
    NSString *_documentFolderPath;
    NSString *_libraryBasePath;
}
@end


// Pref key
static NSString *kLastTVDBUpdateServerTime = @"MLLastTVDBUpdateServerTime";
static NSString *kDecrapifyTitles = @"MLDecrapifyTitles";

#if HAVE_BLOCK
@interface MLMediaLibrary () <MLMovieInfoGrabberDelegate, MLTVShowEpisodesInfoGrabberDelegate, MLTVShowInfoGrabberDelegate>
#else
@interface MLMediaLibrary ()
#endif
- (NSManagedObjectContext *)managedObjectContext;
- (NSString *)databaseFolderPath;
@end

@implementation MLMediaLibrary
+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{kDecrapifyTitles : @YES}];
}

+ (id)sharedMediaLibrary
{
    static id sharedMediaLibrary = nil;
    if (!sharedMediaLibrary) {
        sharedMediaLibrary = [[[self class] alloc] init];

        // Also force to init the crash preventer
        // Because it will correctly set up the parser and thumbnail queue
        [MLCrashPreventer sharedPreventer];
    }
    return sharedMediaLibrary;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

        NSString *key = @"MLKitGroupIdentifier";
        _applicationGroupIdentifier = [[[NSBundle bundleForClass:self.class] infoDictionary] valueForKey:key];
        if (!_applicationGroupIdentifier) {
            _applicationGroupIdentifier = [[[NSBundle mainBundle] infoDictionary] valueForKey:key];
        }
        if (!_applicationGroupIdentifier) {
            _applicationGroupIdentifier = @"group.org.videolan.vlc-ios";
        }

        [self _setupLibraryPathPriorToMigration];
        APLog(@"Initializing db in %@", [self databaseFolderPath]);
    }
    return self;
}

- (void)dealloc
{
    if (_managedObjectContext)
        [_managedObjectContext removeObserver:self forKeyPath:@"hasChanges"];
}

- (NSFetchRequest *)fetchRequestForEntity:(NSString *)entity
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [self managedObjectContext];
    if (!moc || moc.persistentStoreCoordinator == nil)
        return nil;

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entity inManagedObjectContext:moc];
    if (!entityDescription)
        return nil;
    [request setEntity:entityDescription];
    return request;
}

- (id)createObjectForEntity:(NSString *)entity
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    if (!moc || moc.persistentStoreCoordinator == nil)
        return nil;

    return [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:moc];
}

- (void)removeObject:(NSManagedObject *)object
{
    NSManagedObjectContext *moc = [self managedObjectContext];

    if (moc)
        [[self managedObjectContext] deleteObject:object];
}

#pragma mark - helper
- (int)deviceSpeedCategory
{
    if (_deviceSpeedCategory > 0)
        return _deviceSpeedCategory;

    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);

    char *answer = malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);

    NSString *currentMachine = @(answer);
    free(answer);

    if ([currentMachine hasPrefix:@"iPhone2"] || [currentMachine hasPrefix:@"iPhone3"] || [currentMachine hasPrefix:@"iPhone4"] || [currentMachine hasPrefix:@"iPod3"] || [currentMachine hasPrefix:@"iPod4"] || [currentMachine hasPrefix:@"iPad2"]) {
        // iPhone 3GS, iPhone 4, 3rd and 4th generation iPod touch, iPad 2, iPad mini (1st gen)
        _deviceSpeedCategory = 1;
    } else if ([currentMachine hasPrefix:@"iPad3,1"] || [currentMachine hasPrefix:@"iPad3,2"] || [currentMachine hasPrefix:@"iPad3,3"] || [currentMachine hasPrefix:@"iPod5"]) {
        // iPod 5, iPad 3
        _deviceSpeedCategory = 2;
    } else if ([currentMachine hasPrefix:@"iPhone5"] || [currentMachine hasPrefix:@"iPhone6"] || [currentMachine hasPrefix:@"iPad4"]) {
        // iPhone 5 + 5S, iPad 4, iPad Air, iPad mini 2G
        _deviceSpeedCategory = 3;
    } else
        // iPhone 6, 2014 iPads
        _deviceSpeedCategory = 4;

    return _deviceSpeedCategory;
}

#pragma mark -
#pragma mark Media Library
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel)
        return _managedObjectModel;

    NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:@"MediaLibrary" ofType:@"momd"];
    NSURL *momURL = [NSURL fileURLWithPath:path];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];

    return _managedObjectModel;
}

#pragma mark - Path handling
- (void)setLibraryBasePath:(NSString *)libraryBasePath
{
    _libraryBasePath = [libraryBasePath copy];
    _databaseFolderPath = nil;
    _thumbnailFolderPath = nil;
    _persistentStoreURL = nil;
}

- (NSString *)databaseFolderPath
{
    if (_databaseFolderPath.length == 0) {
        _databaseFolderPath = self.libraryBasePath;
    }
    return _databaseFolderPath;
}

- (NSString *)thumbnailFolderPath
{
    if (_thumbnailFolderPath.length == 0) {
        _thumbnailFolderPath = [self.libraryBasePath stringByAppendingPathComponent:@"Thumbnails"];
    }
    return _thumbnailFolderPath;
}

- (NSString *)documentFolderPath
{
    if (_documentFolderPath) {
        if (_documentFolderPath.length > 0)
            return _documentFolderPath;
    }
    int directory = NSDocumentDirectory;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    _documentFolderPath = paths.firstObject;
    return _documentFolderPath;
}

- (NSURL *)persistentStoreURL
{
    if (_persistentStoreURL == nil) {
        NSString *databaseFolderPath = [self databaseFolderPath];
        NSString *path = [databaseFolderPath stringByAppendingPathComponent: @"MediaLibrary.sqlite"];
        _persistentStoreURL = [NSURL fileURLWithPath:path];
    }
    return _persistentStoreURL;
}

- (NSString *)pathRelativeToDocumentsFolderFromAbsolutPath:(NSString *)absolutPath
{
    return [absolutPath stringByReplacingOccurrencesOfString:self.documentFolderPath withString:@""];
}
- (NSString *)absolutPathFromPathRelativeToDocumentsFolder:(NSString *)relativePath
{
    return [self.documentFolderPath stringByAppendingPathComponent:relativePath];
}

#pragma mark -

- (NSPersistentStore *)addDefaultLibraryStoreToCoordinator:(NSPersistentStoreCoordinator *)coordinator withError:(NSError **)error {

    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES,
                              NSSQLitePragmasOption : @{@"journal_mode": @"DELETE"}};

    if (self.additionalPersitentStoreOptions.count > 0) {
        NSMutableDictionary *mutableOptions = options.mutableCopy;
        [mutableOptions addEntriesFromDictionary:self.additionalPersitentStoreOptions];
        options = mutableOptions;
    }
    return [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.persistentStoreURL options:options error:error];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }

    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    if ([[self.additionalPersitentStoreOptions objectForKey:NSReadOnlyPersistentStoreOption] boolValue] == YES) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.persistentStoreURL.path]) {
            APLog(@"no library was found in read-only mode, hence no functionality will be available in this session");
            return nil;
        }
    }

    NSError *error;
    NSPersistentStore *persistentStore = [self addDefaultLibraryStoreToCoordinator:coordinator withError:&error];

    if (!persistentStore) {
#if! TARGET_OS_IPHONE
        // FIXME: Deal with versioning
        NSInteger ret = NSRunAlertPanel(@"Error", @"The Media Library you have on your disk is not compatible with the one Lunettes can read. Do you want to create a new one?", @"No", @"Yes", nil);
        if (ret == NSOKButton)
            [NSApp terminate:nil];
        [[NSFileManager defaultManager] removeItemAtPath:self.persistentStoreURL.path error:nil];
#else
        [[NSFileManager defaultManager] removeItemAtPath:self.persistentStoreURL.path error:nil];
#endif
        persistentStore = [self addDefaultLibraryStoreToCoordinator:coordinator withError:&error];
        if (!persistentStore) {
#if! TARGET_OS_IPHONE
            NSRunInformationalAlertPanel(@"Corrupted Media Library", @"There is nothing we can apparently do about it...", @"OK", nil, nil);
#else
#ifndef TARGET_OS_WATCH
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Corrupted Media Library" message:@"There is nothing we can apparently do about it..." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
#endif
#endif
            // Probably assert instead.
            return nil;
        }
    }

    _persistentStoreCoordinator = coordinator;
    return coordinator;
}


- (void)overrideLibraryWithLibraryFromURL:(NSURL *)replacementURL {

    NSError *error;

    NSPersistentStoreCoordinator *psc = self.persistentStoreCoordinator;
    NSPersistentStore *store = [psc persistentStoreForURL:self.persistentStoreURL];
    if (store) {
        if(![psc removePersistentStore:store error:&error]) {
            APLog(@"%s failed to remove persistent store with error %@",__PRETTY_FUNCTION__,error);
            error = nil;
        }
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSURL *finalTargetURL = self.persistentStoreURL;
    NSString *tmpName = [[NSUUID UUID] UUIDString];
    NSURL *tmpTargetURL = [[finalTargetURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:tmpName];

    BOOL success = [fileManager copyItemAtURL:replacementURL toURL:tmpTargetURL error:&error];
    if (!success) {
        APLog(@"%s failed to copy store to tmp url with with error %@",__PRETTY_FUNCTION__,error);
        error = nil;
    }

    success = [fileManager replaceItemAtURL:self.persistentStoreURL
                              withItemAtURL:tmpTargetURL
                             backupItemName:nil
                                    options:0
                           resultingItemURL:nil
                                      error:&error];
    if (!success) {
        APLog(@"%s failed to replace store with error %@",__PRETTY_FUNCTION__,error);
        error = nil;
    }

    if(![self addDefaultLibraryStoreToCoordinator:psc withError:&error]) {
        APLog(@"%s failed to add store with error %@",__PRETTY_FUNCTION__,error);
    }
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext)
        return _managedObjectContext;

    NSPersistentStoreCoordinator *coodinator = self.persistentStoreCoordinator;
    if (!coodinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coodinator];
    if (_managedObjectContext.persistentStoreCoordinator == nil) {
        _managedObjectContext = nil;
        return nil;
    }
    [_managedObjectContext setUndoManager:nil];
    [_managedObjectContext addObserver:self forKeyPath:@"hasChanges" options:NSKeyValueObservingOptionInitial context:nil];
    return _managedObjectContext;
}

- (void)savePendingChanges
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(savePendingChanges) object:nil];
    NSError *error = nil;
    NSManagedObjectContext *moc = [self managedObjectContext];
    if (!moc)
        return;

    BOOL success = NO;
    @try {
        success = [[self managedObjectContext] save:&error];
    }
    @catch (NSException *exception) {
        APLog(@"Saving pending changes failed");
    }
#if !TARGET_OS_IPHONE && MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    NSProcessInfo *process = [NSProcessInfo processInfo];
    if ([process respondsToSelector:@selector(enableSuddenTermination)])
        [process enableSuddenTermination];
#endif
}

- (void)save
{
    NSError *error = nil;
    NSManagedObjectContext *moc = [self managedObjectContext];
    if (!moc)
        return;

    BOOL success = NO;
    @try {
        success = [moc save:&error];
    }
    @catch (NSException *exception) {
        APLog(@"Saving changes failed");
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"hasChanges"] && object == _managedObjectContext) {
#if !TARGET_OS_IPHONE && MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
        NSProcessInfo *process = [NSProcessInfo processInfo];
        if ([process respondsToSelector:@selector(disableSuddenTermination)])
            [process disableSuddenTermination];
#endif

        if ([[self managedObjectContext] hasChanges]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(savePendingChanges) object:nil];
            [self performSelector:@selector(savePendingChanges) withObject:nil afterDelay:1.];
        }
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (NSManagedObject *)objectForURIRepresentation:(NSURL *)uriRepresenation {
    if (uriRepresenation == nil) {
        return nil;
    }
    NSManagedObjectID *objectID = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation:uriRepresenation];
    if (objectID) {
        return [self.managedObjectContext objectWithID:objectID];
    }
    return nil;
}

#pragma mark -
#pragma mark No meta data fallbacks

- (void)computeThumbnailForFile:(MLFile *)file
{
    if (!file.computedThumbnail && ![file isKindOfType:kMLFileTypeAudio] && [file.hasFetchedInfo boolValue]) {
        APLog(@"Computing thumbnail for %@", file.title);
        [[MLThumbnailerQueue sharedThumbnailerQueue] addFile:file];
    }
}

- (void)errorWhenFetchingMetaDataForFile:(MLFile *)file
{
    APLog(@"Error when fetching for '%@'", file.title);

    [self computeThumbnailForFile:file];
}

- (void)errorWhenFetchingMetaDataForShow:(MLShow *)show
{
    for (MLShowEpisode *episode in show.episodes) {
        for (MLFile *file in episode.files)
            [self errorWhenFetchingMetaDataForFile:file];
    }
}

- (void)noMetaDataInRemoteDBForFile:(MLFile *)file
{
    file.noOnlineMetaData = @YES;
    [self computeThumbnailForFile:file];
}

- (void)noMetaDataInRemoteDBForShow:(MLShow *)show
{
    for (MLShowEpisode *episode in show.episodes) {
        for (MLFile *file in episode.files)
            [self noMetaDataInRemoteDBForFile:file];
    }
}

#pragma mark -
#pragma mark Getter

- (void)addNewLabelWithName:(NSString *)name
{
    MLLabel *label = [self createObjectForEntity:@"Label"];
    label.name = name;
}

/**
 * TV MLShow Episodes
 */

#pragma mark -
#pragma mark Online meta data grabbing

#if HAVE_BLOCK
- (void)tvShowEpisodesInfoGrabberDidFinishGrabbing:(MLTVShowEpisodesInfoGrabber *)grabber
{
    MLShow *show = grabber.userData;

    NSArray *results = grabber.episodesResults;
    [show setValue:(grabber.results)[@"serieArtworkURL"] forKey:@"artworkURL"];
    for (id result in results) {
        if ([result[@"serie"] boolValue]) {
            continue;
        }
        MLShowEpisode *showEpisode = [MLShowEpisode episodeWithShow:show episodeNumber:result[@"episodeNumber"] seasonNumber:result[@"seasonNumber"] createIfNeeded:YES];
        showEpisode.name = result[@"title"];
        showEpisode.theTVDBID = result[@"id"];
        showEpisode.shortSummary = result[@"shortSummary"];
        showEpisode.artworkURL = result[@"artworkURL"];
        if (!showEpisode.artworkURL) {
            for (MLFile *file in showEpisode.files)
                [self computeThumbnailForFile:file];
        }

        showEpisode.lastSyncDate = [MLTVShowInfoGrabber serverTime];
    }
    show.lastSyncDate = [MLTVShowInfoGrabber serverTime];
}

- (void)tvShowEpisodesInfoGrabber:(MLTVShowEpisodesInfoGrabber *)grabber didFailWithError:(NSError *)error
{
    MLShow *show = grabber.userData;
    [self errorWhenFetchingMetaDataForShow:show];
}

- (void)tvShowInfoGrabberDidFinishGrabbing:(MLTVShowInfoGrabber *)grabber
{
    MLShow *show = grabber.userData;
    NSArray *results = grabber.results;
    if ([results count] > 0) {
        NSDictionary *result = results[0];
        NSString *showId = result[@"id"];

        show.theTVDBID = showId;
        show.name = result[@"title"];
        show.shortSummary = result[@"shortSummary"];
        show.releaseYear = result[@"releaseYear"];

        // Fetch episodes info
        MLTVShowEpisodesInfoGrabber *grabber = [[MLTVShowEpisodesInfoGrabber alloc] init];
        grabber.delegate = self;
        grabber.userData = show;
        [grabber lookUpForShowID:showId];
    }
    else {
        // Not found.
        [self noMetaDataInRemoteDBForShow:show];
        show.lastSyncDate = [MLTVShowInfoGrabber serverTime];
    }
}

- (void)tvShowInfoGrabber:(MLTVShowInfoGrabber *)grabber didFailWithError:(NSError *)error
{
    MLShow *show = grabber.userData;
    [self errorWhenFetchingMetaDataForShow:show];
}

- (void)tvShowInfoGrabberDidFetchServerTime:(MLTVShowInfoGrabber *)grabber
{
    MLShow *show = grabber.userData;

    [[NSUserDefaults standardUserDefaults] setInteger:[[MLTVShowInfoGrabber serverTime] integerValue] forKey:kLastTVDBUpdateServerTime];

    // First fetch the MLShow ID
    MLTVShowInfoGrabber *showInfoGrabber = [[MLTVShowInfoGrabber alloc] init];
    showInfoGrabber.delegate = self;
    showInfoGrabber.userData = show;

    APLog(@"Fetching show information on %@", show.name);

    [showInfoGrabber lookUpForTitle:show.name];
}
#endif

- (void)fetchMetaDataForShow:(MLShow *)show
{
    if (!_allowNetworkAccess)
        return;
    APLog(@"Fetching show server time");

    // First fetch the serverTime, so that we can update each entry.
#if HAVE_BLOCK
    [MLTVShowInfoGrabber fetchServerTimeAndExecuteBlock:^(NSNumber *serverDate) {

        [[NSUserDefaults standardUserDefaults] setInteger:[serverDate integerValue] forKey:kLastTVDBUpdateServerTime];

        APLog(@"Fetching show information on %@", show.name);

        // First fetch the MLShow ID
        MLTVShowInfoGrabber *grabber = [[[MLTVShowInfoGrabber alloc] init] autorelease];
        [grabber lookUpForTitle:show.name andExecuteBlock:^{
            NSArray *results = grabber.results;
            if ([results count] > 0) {
                NSDictionary *result = [results objectAtIndex:0];
                NSString *showId = [result objectForKey:@"id"];

                show.theTVDBID = showId;
                show.name = [result objectForKey:@"title"];
                show.shortSummary = [result objectForKey:@"shortSummary"];
                show.releaseYear = [result objectForKey:@"releaseYear"];

                APLog(@"Fetching show episode information on %@", showId);

                // Fetch episode info
                MLTVShowEpisodesInfoGrabber *grabber = [[[MLTVShowEpisodesInfoGrabber alloc] init] autorelease];
                [grabber lookUpForShowID:showId andExecuteBlock:^{
                    NSArray *results = grabber.episodesResults;
                    [show setValue:[grabber.results objectForKey:@"serieArtworkURL"] forKey:@"artworkURL"];
                    for (id result in results) {
                        if ([[result objectForKey:@"serie"] boolValue]) {
                            continue;
                        }
                        MLShowEpisode *showEpisode = [MLShowEpisode episodeWithShow:show episodeNumber:[result objectForKey:@"episodeNumber"] seasonNumber:[result objectForKey:@"seasonNumber"] createIfNeeded:YES];
                        showEpisode.name = [result objectForKey:@"title"];
                        showEpisode.theTVDBID = [result objectForKey:@"id"];
                        showEpisode.shortSummary = [result objectForKey:@"shortSummary"];
                        showEpisode.artworkURL = [result objectForKey:@"artworkURL"];
                        showEpisode.lastSyncDate = serverDate;
                    }
                    show.lastSyncDate = serverDate;
                }];
            }
            else {
                // Not found.
                show.lastSyncDate = serverDate;
            }

        }];
    }];
#endif
}

- (void)addTVShowEpisodeWithInfo:(NSDictionary *)tvShowEpisodeInfo andFile:(MLFile *)file
{
    file.type = kMLFileTypeTVShowEpisode;

    NSNumber *seasonNumber = tvShowEpisodeInfo[@"season"];
    NSNumber *episodeNumber = tvShowEpisodeInfo[@"episode"];
    NSString *tvShowName = tvShowEpisodeInfo[@"tvShowName"];
    NSString *tvEpisodeName = tvShowEpisodeInfo[@"tvEpisodeName"];
    BOOL hasNoTvShow = NO;
    if (!tvShowName) {
        tvShowName = @"";
        hasNoTvShow = YES;
    }
    BOOL wasInserted = NO;
    MLShow *show = nil;
    MLShowEpisode *episode = [MLShowEpisode episodeWithShowName:tvShowName episodeNumber:episodeNumber seasonNumber:seasonNumber createIfNeeded:YES wasCreated:&wasInserted];

    if (episode) {
        show = episode.show;
        [show addEpisode:episode];
    }
    if (wasInserted && !hasNoTvShow) {
        show.name = tvShowName;
        [self fetchMetaDataForShow:show];
    }
    episode.name = tvEpisodeName;

    if (episode.name.length < 1)
        episode.name = file.title;
    file.seasonNumber = seasonNumber;
    file.episodeNumber = episodeNumber;
    episode.shouldBeDisplayed = @YES;

    [episode addFilesObject:file];
    file.showEpisode = episode;

    // The rest of the meta data will be fetched using the MLShow
    file.hasFetchedInfo = @YES;
}

/**
 * MLFile auto detection
 */

#if HAVE_BLOCK
- (void)movieInfoGrabber:(MLMovieInfoGrabber *)grabber didFailWithError:(NSError *)error
{
    MLFile *file = grabber.userData;
    [self errorWhenFetchingMetaDataForFile:file];
}

- (void)movieInfoGrabberDidFinishGrabbing:(MLMovieInfoGrabber *)grabber
{
    NSNumber *yes = @YES;

    NSArray *results = grabber.results;
    MLFile *file = grabber.userData;
    if ([results count] > 0) {
        NSDictionary *result = results[0];
        file.artworkURL = result[@"artworkURL"];
        file.title = result[@"title"];
        file.shortSummary = result[@"shortSummary"];
        file.releaseYear = result[@"releaseYear"];
    }
    else {
        [self noMetaDataInRemoteDBForFile:file];
    }

    file.hasFetchedInfo = yes;
}
#endif

- (void)fetchMetaDataForFile:(MLFile *)file
{
    APLog(@"Fetching meta data for %@", file.title);

    NSDictionary *tvShowEpisodeInfo = [MLTitleDecrapifier tvShowEpisodeInfoFromString:file.title];
    if (tvShowEpisodeInfo) {
        file.type = kMLFileTypeTVShowEpisode;
        [self addTVShowEpisodeWithInfo:tvShowEpisodeInfo andFile:file];
        return;
    }

    if (!_allowNetworkAccess)
        return;
#if HAVE_BLOCK
    // Go online and fetch info.

    // We don't care about keeping a reference to track the item during its life span
    // because we are a singleton
    MLMovieInfoGrabber *grabber = [[MLMovieInfoGrabber alloc] init];

    APLog(@"Looking up for Movie '%@'", file.title);


    [grabber lookUpForTitle:file.title andExecuteBlock:^(NSError *err){
        if (err) {
            [self errorWhenFetchingMetaDataForFile:file];
            return;
        }

        NSArray *results = grabber.results;
        if ([results count] > 0) {
            NSDictionary *result = [results objectAtIndex:0];
            file.artworkURL = [result objectForKey:@"artworkURL"];
            if (!file.artworkURL)
                [self computeThumbnailForFile:file];
            file.title = [result objectForKey:@"title"];
            file.shortSummary = [result objectForKey:@"shortSummary"];
            file.releaseYear = [result objectForKey:@"releaseYear"];
        } else
            [self noMetaDataInRemoteDBForFile:file];
        file.hasFetchedInfo = [NSNumber numberWithBool:YES];
    }];
#endif
}

#pragma mark -
#pragma mark Adding file to the DB

#ifdef MLKIT_READONLY_TARGET

- (void)addFilePaths:(NSArray *)filepaths
{
}

#else

- (void)addFilePath:(NSString *)filePath
{
    APLog(@"Adding Path %@", filePath);

    NSURL *url = [NSURL fileURLWithPath:filePath];
    NSString *title = [filePath lastPathComponent];
#if !TARGET_OS_IPHONE
    NSDate *openedDate = nil; // FIXME kMDItemLastUsedDate
    NSDate *modifiedDate = nil; // FIXME [result valueForAttribute:@"kMDItemFSContentChangeDate"];
#endif

    MLFile *file = [self createObjectForEntity:@"File"];
    file.url = url;

    // Yes, this is a negative number. VLCTime nicely display negative time
    // with "XX minutes remaining". And we are using this facility.

    NSNumber *no = @NO;
    NSNumber *yes = @YES;

    file.currentlyWatching = no;
    file.lastPosition = @0.0;
    file.remainingTime = @0.0;
    file.unread = yes;

#if !TARGET_OS_IPHONE
    if ([openedDate isGreaterThan:modifiedDate]) {
        file.playCount = [NSNumber numberWithDouble:1];
        file.unread = no;
    }
#endif

    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kDecrapifyTitles] boolValue] == YES)
        file.title = [MLTitleDecrapifier decrapify:[title stringByDeletingPathExtension]];
    else
        file.title = [title stringByDeletingPathExtension];

    [[MLFileParserQueue sharedFileParserQueue] addFile:file];
}

- (void)addFilePaths:(NSArray *)filepaths
{
    NSUInteger count = [filepaths count];
    NSMutableArray *fetchPredicates = [NSMutableArray arrayWithCapacity:count];
    NSMutableDictionary *urlToObject = [NSMutableDictionary dictionaryWithCapacity:count];

    // Prepare a fetch request for all items
    for (NSString *path in filepaths) {
        NSString *relativePath = path;
#if TARGET_OS_IPHONE
        // on iPhone we only save relative paths ins the DB
        relativePath = [self pathRelativeToDocumentsFolderFromAbsolutPath:path];
#endif
        relativePath = [relativePath decomposedStringWithCanonicalMapping];
        [urlToObject setObject:path forKey:relativePath];
        [fetchPredicates addObject:[NSPredicate predicateWithFormat:@"path == %@", relativePath]];
    }
    NSFetchRequest *request = [self fetchRequestForEntity:@"File"];
    if (!request)
        return;
    [request setPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:fetchPredicates]];

    APLog(@"Fetching");
    NSManagedObjectContext *moc = [self managedObjectContext];
    if (!moc)
        return;
    NSArray *dbResults = [moc executeFetchRequest:request error:nil];
    APLog(@"Done");

    NSMutableArray *filePathsToAdd = [NSMutableArray arrayWithArray:filepaths];

    // Remove objects that are already in db.
    for (MLFile *dbResult in dbResults) {
        NSString *path = dbResult.path;
        path = [path decomposedStringWithCanonicalMapping];
        [filePathsToAdd removeObject:[urlToObject objectForKey:path]];
    }

    // Add only the newly added items
    for (NSString* path in filePathsToAdd)
        [self addFilePath:path];
}
#endif

#pragma mark -
#pragma mark DB Updates

#if HAVE_BLOCK
- (void)tvShowInfoGrabber:(MLTVShowInfoGrabber *)grabber didFetchUpdates:(NSArray *)updates
{
    NSFetchRequest *request = [self fetchRequestForEntity:@"Show"];
    if (!request)
        return;

    [request setPredicate:[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"theTVDBID"] rightExpression:[NSExpression expressionForConstantValue:updates] modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:0]];
    NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:nil];
    for (MLShow *show in results)
        [self fetchMetaDataForShow:show];
}
#endif

#ifdef MLKIT_READONLY_TARGET

- (void)updateMediaDatabase
{
}

#else

- (void)updateMediaDatabase
{
    [self libraryDidDisappear];
    // Remove no more present files
    NSFetchRequest *request = [self fetchRequestForEntity:@"File"];
    if (!request)
        return;
    NSManagedObjectContext *moc = [self managedObjectContext];
    if (!moc)
        return;
    NSArray *results;
    @try {
        results = [moc executeFetchRequest:request error:nil];
    }
    @catch (NSException *exception) {
        APLog(@"media database update failed");
        return;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];

    unsigned int count = (unsigned int)results.count;
    for (unsigned int x = 0; x < count; x++) {
        MLFile *file = results[x];
       NSURL *fileURL = file.url;
        BOOL exists = [fileManager fileExistsAtPath:[fileURL path]];
        if (!exists) {
            APLog(@"Marking - %@", [fileURL absoluteString]);
            file.isSafe = YES; // It doesn't exist, it's safe.
            if (file.isAlbumTrack) {
                MLAlbum *album = file.albumTrack.album;
                if (album != nil) {
                    if (album.tracks.count <= 1) {
                        @try {
                            [moc deleteObject:album];
                        }
                        @catch (NSException *exception) {
                            APLog(@"failed to nuke object because it disappeared in front of us");
                        }
                    } else
                        [album removeTrack:file.albumTrack];
                }
            }
            if (file.isShowEpisode) {
                MLShow *show = file.showEpisode.show;
                if (show != nil) {
                    if (show.episodes.count <= 1) {
                        @try {
                            [moc deleteObject:show];
                        }
                        @catch (NSException *exception) {
                            APLog(@"failed to nuke object because it disappeared in front of us");
                        }
                    } else
                        [show removeEpisode:file.showEpisode];
                }
            }
#if TARGET_OS_IOS
            NSString *thumbPath = [file thumbnailPath];
            bool thumbExists = [fileManager fileExistsAtPath:thumbPath];
            if (thumbExists)
                [fileManager removeItemAtPath:thumbPath error:nil];

            if ([CSSearchableIndex class]) {
            /* remove file from CoreSpotlight */
                [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithIdentifiers:@[file.objectID.URIRepresentation.absoluteString]
                                                                               completionHandler:^(NSError * __nullable error) {
                                                                                   APLog(@"Removed %@ from index", file.objectID.URIRepresentation);
                                                                               }];
            }

            [moc deleteObject:file];
#endif
        }
#if !TARGET_OS_IPHONE
    file.isOnDisk = @(exists);
#endif
    }
    [self libraryDidAppear];

    // Get the file to parse
    request = [self fetchRequestForEntity:@"File"];
    if (!request)
        return;
    [request setPredicate:[NSPredicate predicateWithFormat:@"isOnDisk == YES && tracks.@count == 0"]];
    @try {
        results = [moc executeFetchRequest:request error:nil];
    }
    @catch (NSException *exception) {
        APLog(@"media database update failed");
        return;
    }
    for (MLFile *file in results)
        [[MLFileParserQueue sharedFileParserQueue] addFile:file];

    if (!_allowNetworkAccess) {
        // Always attempt to fetch
        request = [self fetchRequestForEntity:@"File"];
        if (!request)
            return;
        [request setPredicate:[NSPredicate predicateWithFormat:@"isOnDisk == YES"]];
        @try {
            results = [moc executeFetchRequest:request error:nil];
        }
        @catch (NSException *exception) {
            APLog(@"media database update failed");
            return;
        }
        for (MLFile *file in results) {
            if (!file.computedThumbnail && ![file isKindOfType:kMLFileTypeAudio] && [file.hasFetchedInfo boolValue])
                [self computeThumbnailForFile:file];
        }
        return;
    }

    // Get the thumbnails to compute
    request = [self fetchRequestForEntity:@"File"];
    if (!request)
        return;
    [request setPredicate:[NSPredicate predicateWithFormat:@"isOnDisk == YES && hasFetchedInfo == 1 && artworkURL == nil"]];
    @try {
        results = [moc executeFetchRequest:request error:nil];
    }
    @catch (NSException *exception) {
        APLog(@"media database update failed");
        return;
    }
    for (MLFile *file in results) {
        if (!file.computedThumbnail) {
            if (!file.albumTrack && ![file isKindOfType:kMLFileTypeAudio] && [file.hasFetchedInfo boolValue])
                [self computeThumbnailForFile:file];
        }
    }

    // Get to fetch meta data
    request = [self fetchRequestForEntity:@"File"];
    if (!request)
        return;
    [request setPredicate:[NSPredicate predicateWithFormat:@"isOnDisk == YES && hasFetchedInfo == 0"]];
    @try {
        results = [moc executeFetchRequest:request error:nil];
    }
    @catch (NSException *exception) {
        APLog(@"media database update failed");
        return;
    }
    for (MLFile *file in results)
        [[MLFileParserQueue sharedFileParserQueue] addFile:file];

    // Get to fetch show info
    request = [self fetchRequestForEntity:@"Show"];
    if (!request)
        return;
    [request setPredicate:[NSPredicate predicateWithFormat:@"lastSyncDate == 0"]];
    @try {
        results = [moc executeFetchRequest:request error:nil];
    }
    @catch (NSException *exception) {
        APLog(@"media database update failed");
        return;
    }
    for (MLShow *show in results)
        [self fetchMetaDataForShow:show];

#if HAVE_BLOCK
    // Get updated TV Shows
    NSNumber *lastServerTime = @([[NSUserDefaults standardUserDefaults] integerForKey:kLastTVDBUpdateServerTime]);

    [MLTVShowInfoGrabber fetchUpdatesSinceServerTime:lastServerTime andExecuteBlock:^(NSArray *updates){
        NSFetchRequest *request = [self fetchRequestForEntity:@"Show"];
        if (!request)
            return;
        [request setPredicate:[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"theTVDBID"] rightExpression:[NSExpression expressionForConstantValue:updates] modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:0]];
        NSArray *results = [moc executeFetchRequest:request error:nil];
        for (MLShow *show in results)
            [self fetchMetaDataForShow:show];
    }];
#endif
    /* Update every hour - FIXME: Preferences key */
    [self performSelector:@selector(updateMediaDatabase) withObject:nil afterDelay:60 * 60];
}
#endif

- (void)applicationWillExit
{
    [[MLFileParserQueue sharedFileParserQueue] stop];
    [[MLCrashPreventer sharedPreventer] cancelAllFileParse];
}

- (void)applicationWillStart
{
    [[MLCrashPreventer sharedPreventer] markCrasherFiles];
    [[MLFileParserQueue sharedFileParserQueue] resume];
}

- (void)libraryDidDisappear
{
    // Stop expansive work
    [[MLThumbnailerQueue sharedThumbnailerQueue] stop];
    [[MLFileParserQueue sharedFileParserQueue] stop];
}

- (void)libraryDidAppear
{
    // Resume our work
    [[MLThumbnailerQueue sharedThumbnailerQueue] resume];
    [[MLFileParserQueue sharedFileParserQueue] resume];
}

#pragma mark - migrations

- (BOOL)libraryMigrationNeeded
{
    return [self _libraryMigrationNeeded];
}
- (void)migrateLibrary
{
    [self _migrateLibrary];
}

@end
