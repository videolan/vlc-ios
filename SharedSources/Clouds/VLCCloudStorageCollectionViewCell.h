/*****************************************************************************
 * VLCCloudStorageCollectionViewCell.h
 * VLC for tvOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRemoteBrowsingTVCell.h"

#import "VLCDropboxController.h"
#import "VLCOneDriveObject.h"
#import <BoxSDK/BoxSDK.h>

@interface VLCCloudStorageCollectionViewCell : VLCRemoteBrowsingTVCell

@property (nonatomic, retain) DBMetadata *dropboxFile;
@property (nonatomic, retain) VLCOneDriveObject *oneDriveFile;
@property (nonatomic, retain) BoxItem *boxFile;

@end
