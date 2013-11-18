/*****************************************************************************
 * VLCBugreporter.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@interface VLCBugreporter : NSObject

+ (VLCBugreporter *)sharedInstance;

- (void)handleBugreportRequest;

@end
