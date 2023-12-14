/*****************************************************************************
 * VLCCarPlayPlaylistsController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022-2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <CarPlay/CarPlay.h>

NS_ASSUME_NONNULL_BEGIN

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@interface VLCCarPlayPlaylistsController : NSObject

@property (readwrite) CPInterfaceController *interfaceController;

- (CPListTemplate *)playlists;

@end

#pragma clang diagnostic pop

NS_ASSUME_NONNULL_END
