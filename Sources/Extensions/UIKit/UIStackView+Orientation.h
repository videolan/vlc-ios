/*****************************************************************************
 * UIStackView+Orientation.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCWindowSceneGeometryPreferencesIOS : NSObject

- (instancetype)initWithInterfaceOrientations:(UIInterfaceOrientationMask)interfaceOrientations;

@end

#ifndef __IPHONE_16_0
@interface UIWindowScene(IntroducedIniOS16)
- (void)requestGeometryUpdateWithPreferences:(id)geometryPreferences errorHandler:(nullable void (^)(NSError *error))errorHandler API_AVAILABLE(ios(16.0));
@end

@interface UIViewController(IntroducedIniOS16)
- (void)setNeedsUpdateOfSupportedInterfaceOrientations API_AVAILABLE(ios(16.0));
@end
#endif

@interface UIStackView(Orientation)

- (void)vlc_toggleOrientation;

@end

NS_ASSUME_NONNULL_END
