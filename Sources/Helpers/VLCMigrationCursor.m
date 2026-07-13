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
static NSString *const kVLCLastCompletedMigrationStep = @"lastCompletedMigrationStep";

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
    return [[self store] integerForKey:kVLCLastCompletedMigrationStep] < step;
}

+ (void)completeStep:(VLCMigrationStep)step
{
    NSUserDefaults *store = [self store];
    if ([store integerForKey:kVLCLastCompletedMigrationStep] < step) {
        [store setInteger:step forKey:kVLCLastCompletedMigrationStep];
    }
}

@end
