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
#import "VLCRowController.h"

#import "VLCWatchTableController.h"
#import "MLMediaLibrary+playlist.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import "VLCWatchMessage.h"

static NSString *const rowType = @"mediaRow";

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

    if (context == nil) {
        self.libraryMode = VLCLibraryModeAllFiles;
        [self setupMenuButtons];
        self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", nil);
        self.emptyLibraryLabel.text = NSLocalizedString(@"EMPTY_LIBRARY", nil);
    } else {
        self.groupObject = context;
        self.title = [self.groupObject name];
        self.libraryMode = VLCLibraryModeFolder;
    }
    [self addNowPlayingMenu];

    /* setup table view controller */
    VLCWatchTableController *tableController = [[VLCWatchTableController alloc] init];
    tableController.table = self.table;
    tableController.previousPageButton = self.previousButton;
    tableController.nextPageButton = self.nextButton;
    tableController.emptyLibraryInterfaceObjects = self.emptyLibraryGroup;
    tableController.pageSize = 20;
    tableController.rowType = rowType;
    tableController.identifierKeyPath = @"objectID.URIRepresentation";

    tableController.configureRowControllerWithObjectBlock = ^(id controller, id object) {
        if ([controller respondsToSelector:@selector(configureWithMediaLibraryObject:)]) {
            [controller configureWithMediaLibraryObject:object];
        }
    };
    self.tableController = tableController;

    [self updateData];

    if (self.tableController.objects.count == 0) {
        NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:VLCWatchMessageNameRequestDB];
        [[WCSession defaultSession] sendMessage:dict
                                   replyHandler:nil
                                   errorHandler:nil];
    }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    id object = self.tableController.displayedObjects[rowIndex];

    if ([object isKindOfClass:[MLAlbum class]] || [object isKindOfClass:[MLLabel class]] || [object isKindOfClass:[MLShow class]]) {
        [self pushControllerWithName:@"tableViewController" context:object];
        NSString *folderRepresentation = [((NSManagedObject *)object).objectID.URIRepresentation absoluteString];
        NSDictionary *userDict = @{@"state" : @(self.libraryMode),
                                   @"folder" : folderRepresentation};

        [self invalidateUserActivity];
        [self updateUserActivity:@"org.videolan.vlc-ios.libraryselection"
                        userInfo:userDict
                      webpageURL:nil];
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
    [moc refreshAllObjects];
    self.tableController.objects = [self mediaArray];
}


- (void)setLibraryMode:(VLCLibraryMode)libraryMode
{
    //should also handle diving into a folder
    [self invalidateUserActivity];
    [self updateUserActivity:@"org.videolan.vlc-ios.librarymode" userInfo:@{@"state" : @(libraryMode)} webpageURL:nil];
    _libraryMode = libraryMode;
}

- (NSArray *)mediaArray
{
    id groupObject = self.groupObject;
    if (groupObject) {
        return [[MLMediaLibrary sharedMediaLibrary] playlistArrayForGroupObject:groupObject];
    } else {
        return [[MLMediaLibrary sharedMediaLibrary] playlistArrayForLibraryMode:self.libraryMode];
    }
}

@end
