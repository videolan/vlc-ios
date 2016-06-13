/*****************************************************************************
 * VLCGoogleDriveController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "GTLDrive.h"
#import "VLCCloudStorageController.h"
#import "VLCGoogleDriveConstants.h"

@interface VLCGoogleDriveController : VLCCloudStorageController

@property (nonatomic, retain) GTLServiceDrive *driveService;

- (void)stopSession;
- (void)streamFile:(GTLDriveFile *)file;
- (void)downloadFileToDocumentFolder:(GTLDriveFile *)file;
- (BOOL)hasMoreFiles;

@end
