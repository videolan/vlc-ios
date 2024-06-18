/*****************************************************************************
 * UIStackView+Orientation.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UIStackView+Orientation.h"

@implementation UIStackView(Orientation)

- (void)vlc_toggleOrientation
{
    if (@available(iOS 16.0, *)) {
        UIWindowScene *windowScene = self.window.windowScene;
        id prefs;
        if (windowScene.interfaceOrientation == UIInterfaceOrientationPortrait) {
            prefs = [[VLCWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations: UIInterfaceOrientationMaskLandscape];
        } else {
            prefs = [[VLCWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations: UIInterfaceOrientationMaskPortrait];
        }
        [windowScene requestGeometryUpdateWithPreferences:prefs errorHandler:nil];
    } else {
        UIInterfaceOrientation orientation;
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) {
            orientation = UIInterfaceOrientationLandscapeRight;
        } else {
            orientation = UIInterfaceOrientationPortrait;
        }
        [UIDevice setValue:@(orientation) forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
    }
}

@end

@implementation VLCWindowSceneGeometryPreferencesIOS

- (instancetype)initWithInterfaceOrientations:(UIInterfaceOrientationMask)interfaceOrientations
{
    return [[NSClassFromString(@"UIWindowSceneGeometryPreferencesIOS") alloc] initWithInterfaceOrientations:interfaceOrientations];
}

@end
