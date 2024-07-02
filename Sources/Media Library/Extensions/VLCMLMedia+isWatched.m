/*****************************************************************************
 * VLCMLMedia+isWatched.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: İbrahim Çetin <cetinibrahim.ci # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMLMedia+isWatched.h"

@implementation VLCMLMedia (isWatched)

- (BOOL)isWatched {
    BOOL is95PercentWatched = self.progress >= 0.95;
    SInt64 mediaDuration = self.duration;

    // short media or externally stored media is never considered as played
    if (mediaDuration < 10000 && !self.isExternalMedia) {
        return NO;
    }

    // If the media is watched more than 95% and the remaining time is less than 2 minutes, it is watched.
    if (is95PercentWatched) {
        // Remaining duration in ms
        if (self.progress * mediaDuration > 120000.) {
            return NO;
        }

        return YES;
    }

    return NO;
}

@end
