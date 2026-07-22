/*****************************************************************************
 * VLCRadioAlarmEditorViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@class VLCRadioAlarmInfo;

typedef void (^VLCRadioAlarmEditorCompletion)(NSInteger hour, NSInteger minute, NSArray<NSNumber *> *weekdays);

@interface VLCRadioAlarmEditorViewController : UIViewController

+ (void)presentForStationNamed:(NSString *)stationName
                 existingAlarm:(VLCRadioAlarmInfo *)existingAlarm
            fromViewController:(UIViewController *)viewController
                    completion:(VLCRadioAlarmEditorCompletion)completion;

@end
