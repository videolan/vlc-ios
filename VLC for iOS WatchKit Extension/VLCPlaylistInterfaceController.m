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
#import "VLCThumbnailsCache.h"

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
@property (nonatomic, strong) VLCWatchTableController *tableController;
@property (nonatomic) VLCLibraryMode libraryMode;
@property (nonatomic) BOOL needsUpdate;
@property (nonatomic) id groupObject;

@end

@implementation VLCPlaylistInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    NSLog(@"%s",__PRETTY_FUNCTION__);

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateData) name:VLCDBUpdateNotification object:nil];

    [self setupTableController];
    [self updateData];

}

- (void)setupTableController {

    VLCWatchTableController *tableController = [[VLCWatchTableController alloc] init];
    tableController.table = self.table;
    tableController.previousPageButton = self.previousButton;
    tableController.nextPageButton = self.nextButton;
    tableController.emptyLibraryInterfaceObjects = self.emptyLibraryGroup;
    tableController.pageSize = 5;
    tableController.rowType = rowType;

    __weak typeof(self) weakSelf = self;
    tableController.configureRowControllerWithObjectBlock = ^(id controller, id object) {
        [weakSelf configureTableRowController:controller withObject:object];
    };
    self.tableController = tableController;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VLCDBUpdateNotification object:nil];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    NSLog(@"%s",__PRETTY_FUNCTION__);
    if (self.needsUpdate) {
        [self updateData];
    }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    id object = self.tableController.displayedObjects[rowIndex];
    if ([object isKindOfClass:[MLAlbum class]] || [object isKindOfClass:[MLLabel class]] || [object isKindOfClass:[MLShow class]]) {
        [self pushControllerWithName:@"tableViewController" context:object];
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
    // if not activated/visible we defer the update til activation
    if (self.activated) {
        self.tableController.objects = [self mediaArray];
        self.needsUpdate = NO;
    } else {
        self.needsUpdate = YES;
    }
}

- (void)configureTableRowController:(id)rowController withObject:(id)storageObject {

    VLCRowController *row = rowController;

    CGRect screenRect = WKInterfaceDevice.currentDevice.screenBounds;
    UIImage *backgroundImage = [VLCThumbnailsCache thumbnailForManagedObject:storageObject toFitRect: (CGRect){CGPointZero, CGSizeMake(screenRect.size.width * WKInterfaceDevice.currentDevice.screenScale, 120.)} shouldReplaceCache:YES];

    float playbackProgress = 0.0;
    if ([storageObject isKindOfClass:[MLShow class]]) {
        row.titleLabel.text = ((MLAlbum *)storageObject).name;
    } else if ([storageObject isKindOfClass:[MLShowEpisode class]]) {
        row.titleLabel.text = ((MLShowEpisode *)storageObject).name;
    } else if ([storageObject isKindOfClass:[MLLabel class]]) {
        row.titleLabel.text = ((MLLabel *)storageObject).name;
    } else if ([storageObject isKindOfClass:[MLAlbum class]]) {
        row.titleLabel.text = ((MLAlbum *)storageObject).name;
    } else if ([storageObject isKindOfClass:[MLAlbumTrack class]]) {
        row.titleLabel.text = ((MLAlbumTrack *)storageObject).title;
    } else if ([storageObject isKindOfClass:[MLFile class]]){
        MLFile *file = (MLFile *)storageObject;
        row.titleLabel.text = [file title];
        playbackProgress = file.lastPosition.floatValue;
    }

    BOOL noProgress = (playbackProgress == 0.0 || playbackProgress == 1.0);
    row.progressSeparator.hidden = noProgress;
    row.progressSeparator.width = floor(playbackProgress * CGRectGetWidth([WKInterfaceDevice currentDevice].screenBounds));

    /* FIXME: add placeholder image once designed
    if (backgroundImage == nil)
        backgroundImage = nil;
     */

    [row.group setBackgroundImage:[self generateBackgroundImageWithGradient:backgroundImage]];
}

- (UIImage *)generateBackgroundImageWithGradient:(UIImage *)backgroundImage {

    UIImage *gradient = [UIImage imageNamed:@"tableview-gradient"];

    CGSize newSize = backgroundImage ? backgroundImage.size : CGSizeMake(260, 120);
    UIGraphicsBeginImageContext(newSize);

    // Use existing opacity as is
    [backgroundImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    [gradient drawInRect:CGRectMake(0,newSize.height/2,newSize.width,newSize.height/2) blendMode:kCGBlendModeNormal alpha:1.0];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    return newImage;
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

@end



