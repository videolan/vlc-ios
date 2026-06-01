/*****************************************************************************
 * VLCDocumentPickerController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tamas Timar <ttimar.vlc # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VLCDocumentPickerController : NSObject

- (void)presentFromViewController:(UIViewController *)presentingViewController
                 initialDirectory:(NSURL *)initialDirectoryURL;

@end
