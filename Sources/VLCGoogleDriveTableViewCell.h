/*****************************************************************************
 * VLCGoogleDriveTableViewCell.h
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

@interface VLCGoogleDriveTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *folderTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;

@property (nonatomic) GTLDriveFile *driveFile;

+ (VLCGoogleDriveTableViewCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

@end
