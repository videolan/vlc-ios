/*****************************************************************************
 * VLCStreamingHistoryCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Adam Viaud <mcnight # mcnight.fr>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@protocol VLCStreamingHistoryCellMenuItemProtocol
- (void)renameStreamFromCell:(UITableViewCell *)cell;
@end

@interface VLCStreamingHistoryCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;

@property (weak, nonatomic) id<VLCStreamingHistoryCellMenuItemProtocol> delegate;

+ (VLCStreamingHistoryCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

- (void)renameStream:(id)sender;
- (void)customizeAppearance;

@end
