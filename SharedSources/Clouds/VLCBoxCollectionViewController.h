/*****************************************************************************
 * VLCBoxCollectionViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCloudStorageTVViewController.h"

@interface VLCBoxCollectionViewController : VLCCloudStorageTVViewController

- (instancetype)initWithPath:(NSString *)path;

@end
