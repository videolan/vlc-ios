/*****************************************************************************
 * VLCSlider.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "OBSlider.h"

@interface VLCOBSlider : OBSlider
@property (nonatomic) BOOL seekOnTap;
@end

@interface VLCSlider : UISlider

@end

@interface VLCResettingSlider : VLCSlider
@property (nonatomic) IBInspectable float defaultValue;
@property (nonatomic) IBInspectable BOOL resetOnDoubleTap;
@end