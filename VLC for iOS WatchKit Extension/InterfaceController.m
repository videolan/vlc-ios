//
//  InterfaceController.m
//  VLC for iOS WatchKit Extension
//
//  Created by Carola Nitz on 22/03/15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import "InterfaceController.h"
#import <MediaLibraryKit/MediaLibraryKit.h>
#import "VLCRowController.h"
#import <MobileVLCKit/VLCTime.h>

static NSString *const rowType = @"mediaRow";

@interface InterfaceController()
@property (nonatomic, strong) NSMutableArray *mediaObjects;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    NSLog(@"%s",__PRETTY_FUNCTION__);

    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.org.videolan.vlc-ios"];

    MLMediaLibrary *mediaLibrary = [MLMediaLibrary sharedMediaLibrary];
    mediaLibrary.libraryBasePath = groupURL.path;

    self.title = NSLocalizedString(@"LIBRARY_MUSIC", nil);


    self.mediaObjects = [self mediaArray];

    [self.table setNumberOfRows:self.mediaObjects.count withRowType:rowType];
    [self configureTable:self.table withObjects:self.mediaObjects];

}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    NSLog(@"%s",__PRETTY_FUNCTION__);

}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

- (void)configureTable:(WKInterfaceTable *)table withObjects:(NSArray *)objects {
    [objects enumerateObjectsUsingBlock:^(MLFile *obj, NSUInteger idx, BOOL *stop) {
        VLCRowController *row = [table rowControllerAtIndex:idx];
        row.titleLabel.text = obj.title;
        row.durationLabel.text = [VLCTime timeWithNumber:obj.duration].stringValue,
        [row.group setBackgroundImage:obj.computedThumbnail];
    }];
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



