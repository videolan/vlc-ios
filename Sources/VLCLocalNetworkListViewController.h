/*****************************************************************************
 * VLCLocalNetworkListViewController
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@class VLCLocalNetworkListCell;

@interface VLCLocalNetworkListViewController : UIViewController

@property (nonatomic, strong) UITableView *tableView;

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCLocalNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;

@end
