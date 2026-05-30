/*****************************************************************************
 * VLCPhotoLibraryController.h
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

API_AVAILABLE(ios(14.0))
@interface VLCPhotoLibraryController : NSObject

- (void)showPhotoLibraryPicker:(id)sender;

@end
