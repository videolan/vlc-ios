/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kVLCNetworkLoginViewFieldCellIdentifier;

@protocol VLCNetworkLoginViewFieldCellDelegate;

@interface VLCNetworkLoginViewFieldCell : UITableViewCell
@property (nonatomic, weak) id<VLCNetworkLoginViewFieldCellDelegate> delegate;
@property (nonatomic, retain) UITextField *textField;
@property (nonatomic, retain) UIView *darkView;
@property (nonatomic, nullable, copy) NSString *placeholderString;
@end

@protocol VLCNetworkLoginViewFieldCellDelegate <NSObject>
- (BOOL)loginViewFieldCellShouldReturn:(VLCNetworkLoginViewFieldCell *)cell;
- (void)loginViewFieldCellDidEndEditing:(VLCNetworkLoginViewFieldCell *)cell;
@end

NS_ASSUME_NONNULL_END
