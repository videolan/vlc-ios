/*****************************************************************************
 * VLCLibraryViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Mike JS. Choi <mkchoi212 # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

#define EXPERIMENTAL_LIBRARY 1

#import "MLMediaLibrary+playlist.h"

@interface VLCLibraryViewController : UIViewController <UITabBarDelegate, UIPopoverControllerDelegate>

- (IBAction)leftButtonAction:(id)sender;

- (void)updateViewContents;
- (void)removeMediaObject:(id)mediaObject updateDatabase:(BOOL)updateDB;
- (void)setLibraryMode:(VLCLibraryMode)mode;

@end
