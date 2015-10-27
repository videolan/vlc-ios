//
//  VLCLocalNetworkServerTVCell.m
//  VLC for iOS
//
//  Created by Tobias Conradi on 27.10.15.
//  Copyright © 2015 VideoLAN. All rights reserved.
//

#import "VLCLocalNetworkServerTVCell.h"

NSString *const VLCLocalServerTVCell = @"localServerTVCell";

@implementation VLCLocalNetworkServerTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageView.tintColor = [UIColor VLCOrangeTintColor];
}
@end
