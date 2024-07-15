/*****************************************************************************
 * VLCCloudStorageTableViewCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors:  Felix Paul Kühne <fkuehne # videolan.org>
 *        Carola Nitz <nitz.carola # googlemail.com>
 *        Eshan Singh <eeeshan789 # gmail.com>
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDropboxController.h"
#import <BoxSDK/BoxSDK.h>
#if TARGET_OS_IOS
#import "GTLRDrive.h"
#import <OneDriveSDK/OneDriveSDK.h>
#endif

@class VLCNetworkImageView;
@class ODItem;
@class VLCPCloudCellContentWrapper;

@interface VLCCloudStorageTableViewCell : UITableViewCell

@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *folderTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet VLCNetworkImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet UIButton *downloadButton;
@property (nonatomic, strong) IBOutlet UIButton *favouriteButton;

@property (nonatomic, retain) VLCPCloudCellContentWrapper *pcloudFile;
@property (nonatomic, retain) DBFILESMetadata *dropboxFile;
@property (nonatomic, retain) ODItem *oneDriveFile;
@property (nonatomic, retain) BoxItem *boxFile;
#if TARGET_OS_IOS
@property (nonatomic, retain) GTLRDrive_File *driveFile;
#endif

@property (nonatomic, readwrite) BOOL isDownloadable;
@property (nonatomic, readwrite) BOOL isFavourite;
// We use this property here to determine folders
@property (nonatomic, readwrite) BOOL isFavourable;

+ (VLCCloudStorageTableViewCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

- (IBAction)triggerDownload:(id)sender;

@end

@protocol VLCCloudStorageTableViewCell <NSObject>

@optional
- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell;
- (void)triggerFavoriteForCell:(VLCCloudStorageTableViewCell *)cell;

@end
