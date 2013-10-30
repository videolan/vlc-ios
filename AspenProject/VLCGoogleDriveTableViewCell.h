//
//  VLCDropboxTableViewCell.h
//  VLC for iOS
//
//  Created by Carola Nitz on 21.09.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

//#import <DropboxSDK/DropboxSDK.h>

@interface VLCGoogleDriveTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *folderTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;

//@property (nonatomic, retain) DBMetadata *fileMetadata;

+ (VLCGoogleDriveTableViewCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

@end
