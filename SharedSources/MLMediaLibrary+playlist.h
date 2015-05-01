/*****************************************************************************
 * MLMediaLibrary+playlist.h
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

#import <MediaLibraryKit/MLMediaLibrary.h>

typedef NS_ENUM(NSUInteger, VLCLibraryMode) {
    VLCLibraryModeNone = 0,
    VLCLibraryModeAllFiles,
    VLCLibraryModeAllAlbums,
    VLCLibraryModeAllSeries,
};

@interface MLMediaLibrary (playlist)

- (NSArray *)playlistArrayForGroupObject:(id)groupObject;
- (NSArray *)playlistArrayForLibraryMode:(VLCLibraryMode)libraryMode;

@end
