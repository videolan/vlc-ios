/*****************************************************************************
 * UIImage+Scaling.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@interface UIImage (Scaling)

+ (UIImage *)scaleImage:(UIImage *)image toFitRect:(CGRect)rect;

@end
