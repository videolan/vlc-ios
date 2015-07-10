/*****************************************************************************
 * MLMediaLibrary+playlist.m
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

#import "MLMediaLibrary+playlist.h"

@implementation MLMediaLibrary (playlist)


- (nonnull NSArray *)playlistArrayForGroupObject:(nonnull id)groupObject
{
    if([groupObject isKindOfClass:[MLLabel class]]) {
        return [(MLLabel *)groupObject sortedFolderItems];
    } else if ([groupObject isKindOfClass:[MLAlbum class]]) {
        return [(MLAlbum *)groupObject sortedTracks];
    } else if ([groupObject isKindOfClass:[MLShow class]]){
        return [(MLShow *)groupObject sortedEpisodes];
    } else {
        NSAssert(NO, @"this shouldn't have happened check the grouObjects type");
        return nil;
    }
}

//TODO: this code could use refactoring to be more readable
- (nonnull NSArray *)playlistArrayForLibraryMode:(VLCLibraryMode)libraryMode
{

    NSMutableArray *objects = [NSMutableArray array];
    if (libraryMode == VLCLibraryModeFolder) {
        return  objects;
    }

    /* add all albums */
    if (libraryMode != VLCLibraryModeAllSeries) {
        NSArray *rawAlbums = [MLAlbum allAlbums];
        for (MLAlbum *album in rawAlbums) {
            if (album.name.length > 0 && album.tracks.count > 1)
                [objects addObject:album];
        }
    }
    if (libraryMode == VLCLibraryModeAllAlbums) {
        return objects;
    }

    /* add all shows */
    NSArray *rawShows = [MLShow allShows];
    for (MLShow *show in rawShows) {
        if (show.name.length > 0 && show.episodes.count > 1)
            [objects addObject:show];
    }
    if (libraryMode == VLCLibraryModeAllSeries) {
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
