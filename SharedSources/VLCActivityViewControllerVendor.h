/*****************************************************************************
 * VLCActivityViewControllerVendor.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@interface VLCActivityViewControllerVendor : NSObject

+ (UIActivityViewController *)activityViewControllerForFiles:(NSArray *)files
                                            presentingButton:(UIButton *)button
                                    presentingViewController:(UIViewController *)controller
                                           completionHandler:(void (^)(BOOL))completionHandler;

@end
