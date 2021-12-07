/*****************************************************************************
 * VLCStreamingHistoryCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Adam Viaud <mcnight # mcnight.fr>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import "VLCNetworkListCell.h"

@protocol VLCStreamingHistoryCellMenuItemProtocol
- (void)renameStreamFromCell:(UITableViewCell *)cell;
@end

@interface VLCStreamingHistoryCell : VLCNetworkListCell

@property (weak, nonatomic) id<VLCStreamingHistoryCellMenuItemProtocol> delegate;

- (void)renameStream:(id)sender;
- (void)customizeAppearance;

@end
