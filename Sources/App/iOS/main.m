/*****************************************************************************
 * main.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

#import "VLCAppDelegate.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        // Avoid launching the app during testing.
        if (NSClassFromString(@"XCTestCase") != nil) {
            return UIApplicationMain(argc, argv, nil, nil);
        } else {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([VLCAppDelegate class]));
        }
    }
}
