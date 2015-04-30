/*****************************************************************************
 * VLCPlaylistInterfaceController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Carola Nitz <caro # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaylistInterfaceController.h"
#import <MediaLibraryKit/MediaLibraryKit.h>
#import "VLCRowController.h"
#import <MobileVLCKit/VLCTime.h>

#import "VLCNotificationRelay.h"
#import "VLCWatchTableController.h"
#import "NSManagedObjectContext+refreshAll.h"

static NSString *const rowType = @"mediaRow";
static NSString *const VLCDBUpdateNotification = @"VLCUpdateDataBase";
static NSString *const VLCDBUpdateNotificationRemote = @"org.videolan.ios-app.dbupdate";

typedef enum {
    VLCLibraryModeAllFiles  = 0,
    VLCLibraryModeAllAlbums = 1,
    VLCLibraryModeAllSeries = 2,
    VLCLibraryModeInGroup = 3
} VLCLibraryMode;

@interface VLCPlaylistInterfaceController()
{
    CGRect _thumbnailSize;
    CGFloat _rowWidth;
}

@property (nonatomic, strong) VLCWatchTableController *tableController;
@property (nonatomic) VLCLibraryMode libraryMode;
@property (nonatomic) id groupObject;

@end

@implementation VLCPlaylistInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.org.videolan.vlc-ios"];
    MLMediaLibrary *mediaLibrary = [MLMediaLibrary sharedMediaLibrary];
    mediaLibrary.libraryBasePath = groupURL.path;
    mediaLibrary.additionalPersitentStoreOptions = @{NSReadOnlyPersistentStoreOption : @YES};

    if (context == nil) {
        self.libraryMode = VLCLibraryModeAllFiles;
        [self setupMenuButtons];
        self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", nil);
        self.emptyLibraryLabel.text = NSLocalizedString(@"EMPTY_LIBRARY", nil);
    } else {
        self.groupObject = context;
        self.title = [self.groupObject name];
        self.libraryMode = VLCLibraryModeInGroup;
    }

    [[VLCNotificationRelay sharedRelay] addRelayRemoteName:VLCDBUpdateNotificationRemote toLocalName:VLCDBUpdateNotification];

    /* setup table view controller */
    VLCWatchTableController *tableController = [[VLCWatchTableController alloc] init];
    tableController.table = self.table;
    tableController.previousPageButton = self.previousButton;
    tableController.nextPageButton = self.nextButton;
    tableController.emptyLibraryInterfaceObjects = self.emptyLibraryGroup;
    tableController.pageSize = 5;
    tableController.rowType = rowType;

    tableController.configureRowControllerWithObjectBlock = ^(id controller, id object) {
        if ([controller respondsToSelector:@selector(configureWithMediaLibraryObject:)]) {
            [controller configureWithMediaLibraryObject:object];
        }
    };
    self.tableController = tableController;

    [self updateData];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    id object = self.tableController.displayedObjects[rowIndex];
    if ([object isKindOfClass:[MLAlbum class]] || [object isKindOfClass:[MLLabel class]] || [object isKindOfClass:[MLShow class]]) {

        [self pushControllerWithName:@"tableViewController" context:object];
        [self updateUserActivity:@"org.videolan.vlc-ios.librarymode" userInfo:@{@"state" : @(self.libraryMode), @"folder":((NSManagedObject *)object).objectID.URIRepresentation} webpageURL:nil];
    } else {
        [self pushControllerWithName:@"detailInfo" context:object];
    }
}

- (IBAction)nextPagePressed {
    [self.tableController nextPageButtonPressed];
}

- (IBAction)previousPagePressed {
    [self.tableController previousPageButtonPressed];
}

- (void)setupMenuButtons {

    [self addMenuItemWithImageNamed:@"AllFiles" title: NSLocalizedString(@"LIBRARY_ALL_FILES", nil) action:@selector(switchToAllFiles)];
    [self addMenuItemWithImageNamed:@"MusicAlbums" title: NSLocalizedString(@"LIBRARY_MUSIC", nil) action:@selector(switchToMusic)];
    [self addMenuItemWithImageNamed:@"TVShows" title: NSLocalizedString(@"LIBRARY_SERIES", nil) action:@selector(switchToSeries)];
    [self addNowPlayingMenu];
}

- (void)switchToAllFiles{
    self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", nil);
    self.libraryMode = VLCLibraryModeAllFiles;
    [self updateData];
}

- (void)switchToMusic{
    self.title = NSLocalizedString(@"LIBRARY_MUSIC", nil);
    self.libraryMode = VLCLibraryModeAllAlbums;
    [self updateData];
}

- (void)switchToSeries{
    self.title = NSLocalizedString(@"LIBRARY_SERIES", nil);
    self.libraryMode = VLCLibraryModeAllSeries;
    [self updateData];
}

#pragma mark - data handling

- (void)updateData {
    [super updateData];
    NSManagedObjectContext *moc = [(NSManagedObject *)self.tableController.objects.firstObject managedObjectContext];
    [moc vlc_refreshAllObjectsMerge:NO];
    self.tableController.objects = [self mediaArray];
}

//TODO: this code could use refactoring to be more readable
- (NSMutableArray *)mediaArray {

    if (_libraryMode == VLCLibraryModeInGroup) {
        id groupObject = self.groupObject;

        if([groupObject isKindOfClass:[MLLabel class]]) {
            return [NSMutableArray arrayWithArray:[(MLLabel *)groupObject sortedFolderItems]];
        } else if ([groupObject isKindOfClass:[MLAlbum class]]) {
            return [NSMutableArray arrayWithArray:[(MLAlbum *)groupObject sortedTracks]];
        } else if ([groupObject isKindOfClass:[MLShow class]]){
            return [NSMutableArray arrayWithArray:[(MLShow *)groupObject sortedEpisodes]];
        } else {
            NSAssert(NO, @"this shouldn't have happened check the grouObjects type");
        }
    }

    NSMutableArray *objects = [NSMutableArray array];

    /* add all albums */
    if (_libraryMode != VLCLibraryModeAllSeries) {
        NSArray *rawAlbums = [MLAlbum allAlbums];
        for (MLAlbum *album in rawAlbums) {
            if (album.name.length > 0 && album.tracks.count > 1)
                [objects addObject:album];
        }
    }
    if (_libraryMode == VLCLibraryModeAllAlbums) {
        return objects;
    }

    /* add all shows */
    NSArray *rawShows = [MLShow allShows];
    for (MLShow *show in rawShows) {
        if (show.name.length > 0 && show.episodes.count > 1)
            [objects addObject:show];
    }
    if (_libraryMode == VLCLibraryModeAllSeries) {
        return objects;
    }

    /* add all folders*/
    NSArray *allFolders = [MLLabel allLabels];
    for (MLLabel *folder in allFolders)
        [objects addObject:folder];

    /* add all remaining files */
    NSArray *allFiles = [MLFile allFiles];
    for (MLFile *file in allFiles) {
        if (file.labels.count > 0) continue;

        if (!file.isShowEpisode && !file.isAlbumTrack)
            [objects addObject:file];
        else if (file.isShowEpisode) {
            if (file.showEpisode.show.episodes.count < 2)
                [objects addObject:file];

            /* older MediaLibraryKit versions don't send a show name in a popular
             * corner case. hence, we need to work-around here and force a reload
             * afterwards as this could lead to the 'all my shows are gone'
             * syndrome (see #10435, #10464, #10432 et al) */
            if (file.showEpisode.show.name.length == 0) {
                file.showEpisode.show.name = NSLocalizedString(@"UNTITLED_SHOW", nil);
            }
        } else if (file.isAlbumTrack) {
            if (file.albumTrack.album.tracks.count < 2)
                [objects addObject:file];
        }
    }
    return objects;
}

- (void)setLibraryMode:(VLCLibraryMode)libraryMode
{
    //should also handle diving into a folder
    [self updateUserActivity:@"org.videolan.vlc-ios.librarymode" userInfo:@{@"state" : @(libraryMode)} webpageURL:nil];
    _libraryMode = libraryMode;
}

@end
