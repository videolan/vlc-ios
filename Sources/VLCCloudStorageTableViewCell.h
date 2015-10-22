/*****************************************************************************
 * VLCCloudStorageTableViewCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDropboxController.h"
#import "VLCOneDriveObject.h"
#if TARGET_OS_IOS
#import "GTLDrive.h"
#import <BoxSDK/BoxSDK.h>
#endif

@interface VLCCloudStorageTableViewCell : UITableViewCell

@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *folderTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet UIButton *downloadButton;

@property (nonatomic, retain) DBMetadata *dropboxFile;
@property (nonatomic, retain) VLCOneDriveObject *oneDriveFile;
#if TARGET_OS_IOS
@property (nonatomic, retain) GTLDriveFile *driveFile;
@property (nonatomic, retain) BoxItem *boxFile;
#endif

@property (nonatomic, readwrite) BOOL isDownloadable;

+ (VLCCloudStorageTableViewCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

- (IBAction)triggerDownload:(id)sender;

@end

@protocol VLCCloudStorageTableViewCell <NSObject>

- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell;

@end
