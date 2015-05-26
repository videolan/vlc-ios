/*****************************************************************************
 * VLCMiniPlaybackView.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFrostedGlasView.h"

@class VLCPlaybackController;
@interface VLCMiniPlaybackView : VLCFrostedGlasView
// just a state keeper for animation, has no other implementation
@property (nonatomic) BOOL visible;

- (void)setupForWork:(VLCPlaybackController *)playbackController;
@end
