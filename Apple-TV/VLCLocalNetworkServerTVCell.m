/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServerTVCell.h"

NSString *const VLCLocalServerTVCell = @"localServerTVCell";

@implementation VLCLocalNetworkServerTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageView.tintColor = [UIColor VLCOrangeTintColor];
}
@end
