/*****************************************************************************
 * VLCMigrationCursor.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VLCMigrationStep) {
    VLCMigrationStepBanLogsFolder = 1,
    VLCMigrationStepReloadRadioCountries = 2
};

@interface VLCMigrationCursor : NSObject

+ (BOOL)isStepPending:(VLCMigrationStep)step;
+ (void)completeStep:(VLCMigrationStep)step;

@end
