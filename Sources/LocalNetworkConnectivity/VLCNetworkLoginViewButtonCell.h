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
extern NSString * const kVLCNetworkLoginViewButtonCellIdentifier;

@interface VLCNetworkLoginViewButtonCell : UITableViewCell
@property (nonatomic, nullable, copy) NSString *titleString;
@end
NS_ASSUME_NONNULL_END
