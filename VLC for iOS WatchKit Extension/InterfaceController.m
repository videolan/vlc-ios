/*****************************************************************************
 * InterfaceController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "InterfaceController.h"
#import <MediaLibraryKit/MediaLibraryKit.h>
#import "VLCRowController.h"
#import <MobileVLCKit/VLCTime.h>

#import "VLCNotificationRelay.h"
#import "VLCWatchTableController.h"

static NSString *const rowType = @"mediaRow";
static NSString *const VLCDBUpdateNotification = @"VLCUpdateDataBase";
static NSString *const VLCDBUpdateNotificationRemote = @"org.videolan.ios-app.dbupdate";

@interface InterfaceController()
@property (nonatomic, strong) VLCWatchTableController *tableController;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    NSLog(@"%s",__PRETTY_FUNCTION__);

    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.org.videolan.vlc-ios"];

    MLMediaLibrary *mediaLibrary = [MLMediaLibrary sharedMediaLibrary];
    mediaLibrary.libraryBasePath = groupURL.path;
    mediaLibrary.additionalPersitentStoreOptions = @{NSReadOnlyPersistentStoreOption : @YES};

    self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", nil);
    [[VLCNotificationRelay sharedRelay] addRelayRemoteName:VLCDBUpdateNotificationRemote toLocalName:VLCDBUpdateNotification];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateData) name:VLCDBUpdateNotification object:nil];
    _tableController = [[VLCWatchTableController alloc] init];
    _tableController.table = self.table;
    _tableController.previousPageButton = self.previousButton;
    _tableController.nextPageButton = self.nextButton;
    _tableController.pageSize = 5;
    _tableController.rowTypeForObjectBlock = ^(id object) {
        return rowType;
    };
    _tableController.configureRowControllerWithObjectBlock = ^(id controller, id object) {
        [self configureTableRowController:context withObject:object];
    };
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    NSLog(@"%s",__PRETTY_FUNCTION__);

    [self updateData];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateData) name:VLCDBUpdateNotification object:nil];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    NSLog(@"%s",__PRETTY_FUNCTION__);

    [[NSNotificationCenter defaultCenter] removeObserver:self name:VLCDBUpdateNotification object:nil];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    id object = self.tableController.displayedObjects[rowIndex];
    if ([object isKindOfClass:[MLFile class]]) {
        [self pushControllerWithName:@"detailInfo" context:object];
    }
}

- (IBAction)nextPagePressed {
    [self.tableController nextPageButtonPressed];
}

- (IBAction)previousPagePressed {
    [self.tableController previousPageButtonPressed];
}

#pragma mark - data handling

- (void)updateData {
    self.tableController.objects = [self mediaArray];
}

- (void)configureTableRowController:(id)rowController withObject:(MLFile *)object {
    VLCRowController *row = rowController;
    row.titleLabel.text = object.title;
    row.durationLabel.text = [VLCTime timeWithNumber:object.duration].stringValue;
    [row.group setBackgroundImage:object.computedThumbnail];
}


- (NSMutableArray *)mediaArray {
    NSMutableArray *objects = [NSMutableArray array];
//    /* add all albums */
//    NSArray *rawAlbums = [MLAlbum allAlbums];
//    for (MLAlbum *album in rawAlbums) {
//        if (album.name.length > 0 && album.tracks.count > 1)
//            [objects addObject:album];
//    }
//
//    /* add all shows */
//    NSArray *rawShows = [MLShow allShows];
//    for (MLShow *show in rawShows) {
//        if (show.name.length > 0 && show.episodes.count > 1)
//            [objects addObject:show];
//    }
//
//    /* add all folders*/
//    NSArray *allFolders = [MLLabel allLabels];
//    for (MLLabel *folder in allFolders)
//        [objects addObject:folder];

    /* add all remaining files */
    NSArray *allFiles = [MLFile allFiles];
    for (MLFile *file in allFiles) {
        if (file.labels.count > 0) continue;

        if (!file.isShowEpisode && !file.isAlbumTrack)
            [objects addObject:file];
        else if (file.isShowEpisode) {
            if (file.showEpisode.show.episodes.count < 2)
                [objects addObject:file];
        } else if (file.isAlbumTrack) {
            if (file.albumTrack.album.tracks.count < 2)
                [objects addObject:file];
        }
    }
    return objects;
}

@end



