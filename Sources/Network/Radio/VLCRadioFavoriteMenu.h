/*****************************************************************************
 * VLCRadioFavoriteMenu.h
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

@class VLCFavorite;

API_AVAILABLE(ios(14.0))
@interface VLCRadioFavoriteMenu : NSObject

+ (UIMenu *)menuForFavorite:(VLCFavorite *)favorite
   presentingViewController:(UIViewController *)presenter
                  didChange:(void (^)(void))didChange;

+ (NSArray<UIMenuElement *> *)alarmActionsForFavorite:(VLCFavorite *)favorite
                             presentingViewController:(UIViewController *)presenter
                                            didChange:(void (^)(void))didChange;

@end
