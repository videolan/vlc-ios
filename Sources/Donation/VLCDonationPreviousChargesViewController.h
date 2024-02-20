/*****************************************************************************
 * VLCDonationPreviousChargesViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@class VLCCharge;

NS_ASSUME_NONNULL_BEGIN

@interface VLCDonationPreviousChargesViewController : UITableViewController

- (void)addPreviousCharge:(VLCCharge *)charge;

@end

NS_ASSUME_NONNULL_END
