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

#import "VLCPlaybackController.h"
#import "VLCPlayerDisplayController.h"
#import "VLCFrostedGlasView.h"

@class VLCPlaybackController;
@interface VLCMiniPlaybackView : VLCFrostedGlasView <VLCPlaybackControllerDelegate, VLCMiniPlaybackViewInterface>
// just a state keeper for animation, has no other implementation
@property (nonatomic) BOOL visible;
@end
