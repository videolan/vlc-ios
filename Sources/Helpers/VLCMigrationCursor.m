/*****************************************************************************
 * VLCMigrationCursor.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMigrationCursor.h"

/* migrations must outlive a settings reset, so they live outside the app's persistent domain */
static NSString *const kVLCMigrationSuiteName = @"org.videolan.vlc-ios.migrations";

@implementation VLCMigrationCursor

+ (NSUserDefaults *)store
{
    static NSUserDefaults *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[NSUserDefaults alloc] initWithSuiteName:kVLCMigrationSuiteName];
    });
    return store;
}

+ (BOOL)isStepPending:(VLCMigrationStep)step
{
    return ![[self store] boolForKey:@(step).stringValue];
}

+ (void)completeStep:(VLCMigrationStep)step
{
    [[self store] setBool:YES forKey:@(step).stringValue];
}

@end
