//
//  VLCCloudStorageTableViewCell.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 24.05.13.
//  Modified by Carola Nitz on 07.11.13
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <DropboxSDK/DropboxSDK.h>
#import "GTLDrive.h"

@interface VLCCloudStorageTableViewCell : UITableViewCell

@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *folderTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet UIButton *downloadButton;

@property (nonatomic, retain) DBMetadata *fileMetadata;
@property (nonatomic, retain) GTLDriveFile *driveFile;

+ (VLCCloudStorageTableViewCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

- (IBAction)triggerDownload:(id)sender;

@end

@protocol VLCCloudStorageTableViewCell <NSObject>

- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell;

@end
