/*****************************************************************************
 * VLCWiFiUploadTableViewCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@protocol VLCWiFiUploadTableViewCellDelegate <NSObject>

- (void)updateTableViewHeight;

@end

@interface VLCWiFiUploadTableViewCell : UITableViewCell

@property (nonatomic, readwrite, weak)id <VLCWiFiUploadTableViewCellDelegate> delegate;

+ (NSString *)cellIdentifier;

@end
