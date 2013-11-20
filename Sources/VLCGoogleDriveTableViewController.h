/*****************************************************************************
 * VLCGoogleDriveTableViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import "VLCCloudStorageTableViewController.h"
#import "GTMOAuth2ViewControllerTouch.h"

@interface VLCGoogleDriveTableViewController : VLCCloudStorageTableViewController

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)authResult error:(NSError *)error;

@end
