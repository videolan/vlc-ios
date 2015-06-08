/*****************************************************************************
 * VLCPlaybackController+MediaLibrary.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackController+MediaLibrary.h"
#import <MediaLibraryKit/MediaLibraryKit.h>
#import <CoreData/CoreData.h>

@implementation VLCPlaybackController (MediaLibrary)

- (void)playMediaLibraryObject:(NSManagedObject *)mediaObject
{
    if ([mediaObject isKindOfClass:[MLFile class]]) {
        [self configureWithFile:(MLFile *)mediaObject];
    }
    else if ([mediaObject isKindOfClass:[MLAlbumTrack class]]) {
        [self configureWithAlbumTrack:(MLAlbumTrack *)mediaObject];
    }
    else if ([mediaObject isKindOfClass:[MLShowEpisode class]])
        [self configureWithSingleFile:[(MLShowEpisode*)mediaObject files].anyObject];

    [self startPlayback];
}

- (void)configureWithFile:(MLFile *)file
{
    if (file.labels.count == 0) {
        [self configureWithSingleFile:file];
    } else {
        MLLabel *folder = [file.labels anyObject];
        NSArray *files = [folder sortedFolderItems];
        int index = (int)[files indexOfObject:file];
        [self configureMediaListWithFiles:files indexToPlay:index];
    }
}

- (void)configureWithSingleFile:(MLFile *)file
{
    [file setUnread:@(NO)];
    self.fileFromMediaLibrary = file;
}

- (void)configureWithAlbumTrack:(MLAlbumTrack *)albumTrack
{
    NSArray *tracks = [[albumTrack album] sortedTracks];
    NSMutableArray *files = [NSMutableArray arrayWithCapacity:tracks.count];
    for (MLAlbumTrack *track in tracks) {
        MLFile *file = track.files.anyObject;
        if (file)
            [files addObject:file];
    }
    int index = (int)[tracks indexOfObject:albumTrack];
    [self configureMediaListWithFiles:files indexToPlay:index];
}

- (void)configureMediaListWithFiles:(NSArray *)files indexToPlay:(int)index
{
    VLCMediaList *list = [[VLCMediaList alloc] init];
    for (MLFile *file in files.reverseObjectEnumerator) {
        [list addMedia:[VLCMedia mediaWithURL:file.url]];
    }
    [self configureMediaList:list atIndex:index];
}

- (void)configureMediaList:(VLCMediaList *)list atIndex:(int)index
{
    self.mediaList = list;
    self.itemInMediaListToBePlayedFirst = index;
    self.pathToExternalSubtitlesFile = nil;
}

@end
