/*****************************************************************************
 * WKInterfaceObject+VLCProgress.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "WKInterfaceObject+VLCProgress.h"

@implementation WKInterfaceObject (VLCProgress)

-(void)vlc_setProgress:(float)progress
{
    float progressWidth = ceil(progress * CGRectGetWidth([WKInterfaceDevice currentDevice].screenBounds));
    self.width = progressWidth;
}

- (void)vlc_setProgress:(float)progress hideForNoProgress:(BOOL)hideForNoProgress
{
    [self vlc_setProgress:progress];
    BOOL noProgress = progress == 0.0;
    self.hidden = noProgress && hideForNoProgress;
}

- (void)vlc_setProgressFromPlaybackTime:(float)playbackTime duration:(float)duration hideForNoProgess:(BOOL)hideForNoProgress
{
    float playbackProgress = 0.0;
    if (playbackTime > 0.0 && duration > 0.0) {
        playbackProgress = playbackTime / duration;
    }
    [self vlc_setProgress:playbackProgress hideForNoProgress:hideForNoProgress];
}

@end
