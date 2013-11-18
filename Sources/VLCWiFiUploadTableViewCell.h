/*****************************************************************************
 * VLCWiFiUploadTableViewCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCWiFiUploadTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *uploadAddressLabel;
@property (nonatomic, strong) IBOutlet UIButton *serverOnButton;

+ (VLCWiFiUploadTableViewCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

@end
