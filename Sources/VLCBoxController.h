/*****************************************************************************
 * VLCBoxController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <BoxSDK/BoxSDK.h>
#import "VLCCloudStorageController.h"
#import "VLCBoxConstants.h"

@interface VLCBoxController : VLCCloudStorageController

- (void)stopSession;
- (void)streamFile:(BoxFile *)file;
- (void)downloadFileToDocumentFolder:(BoxFile *)file;
- (BOOL)hasMoreFiles;

@end
