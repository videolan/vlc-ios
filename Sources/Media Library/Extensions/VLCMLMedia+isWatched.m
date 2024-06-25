//
//  VLCMLMedia+isWatched.m
//  VLC-iOS
//
//  Created by İbrahim Çetin on 25.06.2024.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

#import "VLCMLMedia+isWatched.h"

@implementation VLCMLMedia (VLCMLMedia_isWatched)

- (BOOL)isWatched {
    BOOL is95PercentWatched = self.progress >= 0.95;

    // If the media is watched more than 95% and the remaing time is less than 2 minutes, it is watched.
    if (is95PercentWatched) {
        // Remaining duration in ms
        SInt64 remainingDuration = self.duration * (1 - self.progress);

        if (remainingDuration < 120000)
            return YES;
    }

    return NO;
}

@end
