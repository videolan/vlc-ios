/*****************************************************************************
 * VLCCloudStorageTableViewCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDropboxController.h"
#import <BoxSDK/BoxSDK.h>
#if TARGET_OS_IOS
#import "GTLRDrive.h"
#import <MSGraphClientModels/MSGraphDriveItem.h>
#import <MSGraphClientModels/MSGraphAudio.h>
#import <MSGraphClientModels/MSGraphVideo.h>
#endif

@class VLCNetworkImageView;
@class MSGraphDriveItem;

@interface VLCCloudStorageTableViewCell : UITableViewCell

@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *folderTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet VLCNetworkImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet UIButton *downloadButton;

@property (nonatomic, retain) DBFILESMetadata *dropboxFile;
@property (nonatomic, retain) MSGraphDriveItem *oneDriveFile;
@property (nonatomic, retain) BoxItem *boxFile;
#if TARGET_OS_IOS
@property (nonatomic, retain) GTLRDrive_File *driveFile;
#endif

@property (nonatomic, readwrite) BOOL isDownloadable;

+ (VLCCloudStorageTableViewCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

- (IBAction)triggerDownload:(id)sender;

@end

@protocol VLCCloudStorageTableViewCell <NSObject>

- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell;

@end
