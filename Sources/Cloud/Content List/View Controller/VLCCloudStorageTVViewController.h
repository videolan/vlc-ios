/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRemoteBrowsingCollectionViewController.h"
#import "VLCCloudStorageController.h"

@interface VLCCloudStorageTVViewController : VLCRemoteBrowsingCollectionViewController

@property (nonatomic, strong) VLCCloudStorageController *controller;
@property (nonatomic, strong) NSString *currentPath;
@property (nonatomic) BOOL authorizationInProgress;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

- (void)updateViewAfterSessionChange;
- (void)requestInformationForCurrentPath;

@end
