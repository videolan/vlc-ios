/*****************************************************************************
 * VLCPlaybackController+MediaLibrary.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz     <caro #videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackController.h"

@class VLCMLMedia;
@interface VLCPlaybackController (MediaLibrary)

- (void)playMedia:(VLCMLMedia *)media;
- (void)playMediaAtIndex:(NSInteger)index fromCollection:(NSArray<VLCMLMedia *> *)collection;
@end
