/*****************************************************************************
 * VLCFirstStepsBaseViewController
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2020-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Pavel Akhrameev <p.akhrameev@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, VLCFirstStepsPage) {
    VLCFirstStepsPageFirst,
    VLCFirstStepsPageiTunesSync = 0,
    VLCFirstStepsPageWifiSharing,
    VLCFirstStepsPageClouds,
    VLCFirstStepsPageCount
};

@interface VLCFirstStepsBaseViewController : UIViewController

@property (nonatomic, readonly) VLCFirstStepsPage page;

@property (weak, nonatomic) IBOutlet UILabel *pageTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *centralView;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *centralParts;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *images;
@property (weak, nonatomic) IBOutlet UIView *pageTitleContainer;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pageTitleLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionLabelHeightConstraint;
@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *labelHeightConstraints;

- (void)configurePage;
- (NSArray <NSLayoutConstraint *> *)imageViewConstraints:(UIImageView *)imageView;

#pragma mark - Class Functions

+ (NSArray *)pageClasses;

+ (VLCFirstStepsPage)page;

+ (NSString *)pageTitleText;
+ (NSString *)titleText;
+ (NSString *)descriptionText;

+ (NSArray <NSString *> *)pageTitleTexts;
+ (NSArray <NSString *> *)titleTexts;
+ (NSArray <NSString *> *)descriptionTexts;

@end

NS_ASSUME_NONNULL_END
