/*****************************************************************************
 * VLCPlaybackService+MediaLibrary.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz     <caro #videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackService.h"

@class VLCMLMedia;
@interface VLCPlaybackService (MediaLibrary)

- (void)playMedia:(VLCMLMedia *)media;
- (void)playMediaAtIndex:(NSInteger)index fromCollection:(NSArray<VLCMLMedia *> *)collection;
- (void)playMediaNextInQueue:(VLCMLMedia *)media NS_SWIFT_NAME(playMediaNextInQueue(_:));
- (void)appendMediaToQueue:(VLCMLMedia *)media NS_SWIFT_NAME(appendMediaToQueue(_:));
- (void)playCollection:(NSArray<VLCMLMedia *> *)collection;
- (void)playCollectionNextInQueue:(NSArray<VLCMLMedia *> *)collection NS_SWIFT_NAME(playCollectionNextInQueue(_:));
- (void)appendCollectionToQueue:(NSArray<VLCMLMedia *> *)collection NS_SWIFT_NAME(appendCollectionToQueue(_:));
@end
