/*****************************************************************************
 * VLCSEPANotificationViewController.h
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

NS_ASSUME_NONNULL_BEGIN

@interface VLCSEPANotificationViewController : UIViewController

@property (readwrite, nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *authorizationTextLabel;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *continueButton;

- (IBAction)continueButtonAction:(id)sender;

@end

NS_ASSUME_NONNULL_END
