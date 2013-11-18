//
//  VLCWiFiUploadTableViewCell.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 10.08.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <UIKit/UIKit.h>

@interface VLCWiFiUploadTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *uploadAddressLabel;
@property (nonatomic, strong) IBOutlet UIButton *serverOnButton;

+ (VLCWiFiUploadTableViewCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

@end
