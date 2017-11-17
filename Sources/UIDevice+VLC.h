/*****************************************************************************
 * UIDevice+VLC.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface UIDevice (VLC)

@property (readonly) NSNumber *VLCFreeDiskSpace;
@property (readonly) BOOL VLCHasExternalDisplay;
@property (readonly) BOOL isiPhoneX;
@end
