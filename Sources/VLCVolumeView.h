/*****************************************************************************
 * VLCVolumeView.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <MediaPlayer/MediaPlayer.h>

// overrides the rect methods of MPVolumeView to fix the slider and button
// hanging at the top of the view when the volume view has not the "original" size

@interface VLCVolumeView : MPVolumeView
- (CGRect)volumeSliderRectForBounds:(CGRect)bounds;
- (CGRect)routeButtonRectForBounds:(CGRect)bounds;
@end
