/*****************************************************************************
 * VLCCarPlayListLimit.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <CarPlay/CarPlay.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
NS_INLINE NSUInteger VLCCarPlayMaximumItemCountLimit(void)
{
    if (@available(iOS 14.0, *)) {
        return CPListTemplate.maximumItemCount;
    }

    // educated guess for iOS 13
    return 100;
}
#pragma clang diagnostic pop
