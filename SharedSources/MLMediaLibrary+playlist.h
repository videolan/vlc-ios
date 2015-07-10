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

typedef enum {
    VLCLibraryModeAllFiles  = 0,
    VLCLibraryModeAllAlbums = 1,
    VLCLibraryModeAllSeries = 2,
    VLCLibraryModeCreateFolder = 3,
    VLCLibraryModeFolder = 4
} VLCLibraryMode;

@interface MLMediaLibrary (playlist)

- (nonnull NSArray *)playlistArrayForGroupObject:(nonnull id)groupObject;
- (nonnull NSArray *)playlistArrayForLibraryMode:(VLCLibraryMode)libraryMode;

@end
