/*****************************************************************************
 * VLCDonationPayPalViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCDonationPayPalViewController : UIViewController

- (void)setDonationAmount:(int)donationAmount;
- (void)setCurrencyCode:(NSString *)isoCode;

@end

NS_ASSUME_NONNULL_END
