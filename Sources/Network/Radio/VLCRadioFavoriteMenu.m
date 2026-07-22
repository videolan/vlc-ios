/*****************************************************************************
 * VLCRadioFavoriteMenu.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRadioFavoriteMenu.h"
#import "VLCFavoriteService.h"
#import "VLCAppCoordinator.h"
#if !TARGET_OS_VISION
#import "VLCRadioAlarmEditorViewController.h"
#endif

#import "VLC-Swift.h"

@implementation VLCRadioFavoriteMenu

+ (UIMenu *)menuForFavorite:(VLCFavorite *)favorite
   presentingViewController:(UIViewController *)presenter
                  didChange:(void (^)(void))didChange
{
    NSMutableArray<UIMenuElement *> *actions = [[self alarmActionsForFavorite:favorite
                                                    presentingViewController:presenter
                                                                   didChange:didChange] mutableCopy];

    UIAction *removeAction = [UIAction actionWithTitle:NSLocalizedString(@"REMOVE_FAVORITE", nil)
                                                 image:[UIImage systemImageNamed:@"heart.slash"]
                                            identifier:nil
                                               handler:^(__kindof UIAction * _Nonnull action) {
        [[[VLCAppCoordinator sharedInstance] favoriteService] removeFavorite:favorite];
        didChange();
    }];
    removeAction.attributes = UIMenuElementAttributesDestructive;
    [actions addObject:removeAction];

    return [UIMenu menuWithTitle:@"" children:actions];
}

+ (NSArray<UIMenuElement *> *)alarmActionsForFavorite:(VLCFavorite *)favorite
                             presentingViewController:(UIViewController *)presenter
                                            didChange:(void (^)(void))didChange
{
#if !TARGET_OS_VISION
    if (@available(iOS 26.1, *)) {
        VLCRadioAlarmService *alarmService = VLCRadioAlarmService.shared;
        VLCRadioAlarmInfo *alarm = [alarmService alarmForURL:favorite.url];

        NSString *editTitle = alarm ? NSLocalizedString(@"RADIO_ALARM_EDIT", nil) : NSLocalizedString(@"RADIO_ALARM_SET", nil);
        UIAction *editAction = [UIAction actionWithTitle:editTitle
                                                   image:[UIImage systemImageNamed:@"alarm"]
                                              identifier:nil
                                                 handler:^(__kindof UIAction * _Nonnull action) {
            [self editAlarmForFavorite:favorite presentingViewController:presenter didChange:didChange];
        }];
        editAction.subtitle = [alarmService localizedAlarmDescriptionForURL:favorite.url];

        if (!alarm) {
            return @[editAction];
        }

        UIAction *removeAction = [UIAction actionWithTitle:NSLocalizedString(@"RADIO_ALARM_REMOVE", nil)
                                                     image:[UIImage systemImageNamed:@"bell.slash"]
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
            [alarmService removeAlarmForURL:favorite.url];
            didChange();
        }];
        return @[editAction, removeAction];
    }
#endif
    return @[];
}

#if !TARGET_OS_VISION
+ (void)editAlarmForFavorite:(VLCFavorite *)favorite
    presentingViewController:(UIViewController *)presenter
                   didChange:(void (^)(void))didChange
{
    VLCRadioAlarmService *alarmService = VLCRadioAlarmService.shared;

    [VLCRadioAlarmEditorViewController presentForStationNamed:favorite.userVisibleName
                                                existingAlarm:[alarmService alarmForURL:favorite.url]
                                           fromViewController:presenter
                                                   completion:^(NSInteger hour, NSInteger minute, NSArray<NSNumber *> *weekdays) {
        [alarmService scheduleAlarmForFavorite:favorite
                                          hour:hour
                                        minute:minute
                                      weekdays:weekdays
                                    completion:^(NSError * _Nullable error) {
            if (error) {
                [self presentAlarmError:error fromViewController:presenter];
                return;
            }
            didChange();
        }];
    }];
}

+ (void)presentAlarmError:(NSError *)error fromViewController:(UIViewController *)presenter
{
    BOOL denied = error.code == VLCRadioAlarmErrorAuthorizationDenied;
    NSString *message = denied ? NSLocalizedString(@"RADIO_ALARM_DENIED", nil) : NSLocalizedString(@"RADIO_ALARM_FAILED", nil);
    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:NSLocalizedString(@"RADIO_ALARM_SET", nil)
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];

    if (denied) {
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OPEN", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
        }]];
    } else {
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil]];
    }

    [presenter presentViewController:alertController animated:YES completion:nil];
}
#endif

@end
