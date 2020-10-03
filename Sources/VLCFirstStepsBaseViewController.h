//
//  VLCFirstStepsBaseViewController.h
//  VLC-iOS
//
//  Created by Pavel Akhrameev on 02.10.2020.
//  Copyright © 2020 VideoLAN. All rights reserved.
//

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
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pageTitleLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionLabelHeightConstraint;

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
