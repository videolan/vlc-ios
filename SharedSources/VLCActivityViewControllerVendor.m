/*****************************************************************************
 * VLCActivityViewControllerVendor.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCActivityViewControllerVendor.h"
#import "VLCOpeninActivity.h"
#import <Photos/PHPhotoLibrary.h>

@implementation VLCActivityViewControllerVendor

+ (UIActivityViewController *)activityViewControllerForFiles:(NSArray *)files
                                            presentingButton:(UIButton *)button
                                    presentingViewController:(UIViewController *)viewController
                                           completionHandler:(void (^)(BOOL))completionHandler
{
    if (![files count]) {
        [viewController vlc_showAlertWithTitle:NSLocalizedString(@"SHARING_ERROR_NO_FILES", nil)
                             message:nil
                         buttonTitle:NSLocalizedString(@"BUTTON_OK", nil)];
        return nil;
    }

    VLCOpenInActivity *openInActivity = [[VLCOpenInActivity alloc] init];
    openInActivity.presentingViewController = viewController;
    openInActivity.presentingButton = button;

    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:files applicationActivities:@[openInActivity]];

    NSMutableArray *excludedActivities = [@[
                                            UIActivityTypePrint,
                                            UIActivityTypeAssignToContact,
                                            UIActivityTypeAddToReadingList,
                                            UIActivityTypeOpenInIBooks
                                            ] mutableCopy];

    if (@available(iOS 11_0, *)) {
        [excludedActivities addObject:UIActivityTypeMarkupAsPDF];
    }
    controller.excludedActivityTypes = excludedActivities;
    controller.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        APLog(@"UIActivityViewController finished with activity type: %@, completed: %i", activityType, completed);

        // Provide feedback. This could cause a false positive if the user chose "Don't Allow" in the permissions dialog, and UIActivityViewController does not inform us of that, so check the authorization status.

        // By the time this is called, the user has not had time to choose whether to allow access to the Photos library, so only display the message if we are truly sure we got authorization. The first time the user saves to the camera roll he won't see the confirmation because of this timing issue. This is better than showing a success message when the user had denied access. A timing workaround could be developed if needed through UIApplicationDidBecomeActiveNotification (to know when the security alert view was dismissed) or through other ALAssets APIs.
        if (completed && [activityType isEqualToString:UIActivityTypeSaveToCameraRoll]) {
            [viewController vlc_showAlertWithTitle:NSLocalizedString(@"SHARING_SUCCESS_CAMERA_ROLL", nil)
                                           message:nil
                                       buttonTitle:NSLocalizedString(@"BUTTON_OK", nil)];
        }
        completionHandler(completed);
    };
    return controller;
}
@end
