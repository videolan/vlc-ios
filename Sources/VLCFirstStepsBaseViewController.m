//
//  VLCFirstStepsBaseViewController.m
//  VLC-iOS
//
//  Created by Pavel Akhrameev on 02.10.2020.
//  Copyright © 2020 VideoLAN. All rights reserved.
//

#import "VLCFirstStepsBaseViewController.h"
#import "VLCFirstStepsiTunesSyncViewController.h"
#import "VLCFirstStepsWifiSharingViewController.h"
#import "VLCFirstStepsCloudViewController.h"
#import "VLC-Swift.h"

@interface VLCFirstStepsBaseViewController ()

@end

@implementation VLCFirstStepsBaseViewController

- (VLCFirstStepsPage)page
{
    return self.class.page;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (@available(iOS 11.0, *)) {
        UIFont *titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle];
        self.pageTitleLabel.font = [UIFont systemFontOfSize:titleFont.pointSize weight:UIFontWeightBold];
    } else {
        self.pageTitleLabel.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTheme) name:kVLCThemeDidChangeNotification object:nil];
    [self setupPage];
    [self updateTheme];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self setupPage];
    [self updateTheme];
}

- (void)updateTheme
{
    self.pageTitleLabel.textColor = PresentationTheme.current.colors.navigationbarTextColor;
    self.titleLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    self.descriptionLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor;
    self.view.backgroundColor = PresentationTheme.current.colors.background;
    self.bottomView.backgroundColor = self.view.backgroundColor;
    self.pageTitleLabel.backgroundColor = self.view.backgroundColor;
    self.pageTitleLabel.superview.backgroundColor = self.view.backgroundColor;
    [self configurePage];
}

- (void)setupPage
{
    [self.centralParts enumerateObjectsUsingBlock:^(UIView *part, NSUInteger idx, BOOL * _Nonnull stop) {
        part.hidden = idx != self.page;
        if (idx == self.page) {
            for (UIView *view in self.centralView.subviews) {
                [view removeFromSuperview];
            }
            UIGraphicsBeginImageContext(part.frame.size);
            [part.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
            UIImageView *imageView = [[UIImageView alloc] initWithImage:img];
            UIGraphicsEndImageContext();
            [self.centralView addSubview:imageView];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints: [self imageViewConstraints:imageView]];
        }
    }];
}

- (void)configurePage
{
    self.pageTitleLabel.text = [self.class pageTitleText];
    self.titleLabel.text = [self.class titleText];
    self.descriptionLabel.text = [self.class descriptionText];
    [self updateHeightConstraints];
}

- (void)updateHeightConstraints
{
    self.pageTitleLabelHeightConstraint.constant = [self heightForLabel:self.pageTitleLabel
                                                                  texts:self.class.pageTitleTexts];
    self.titleLabelHeightConstraint.constant = [self heightForLabel:self.titleLabel
                                                              texts:self.class.titleTexts];
    self.descriptionLabelHeightConstraint.constant = [self heightForLabel:self.descriptionLabel
                                                                    texts:self.class.descriptionTexts];
}

- (CGFloat)heightForLabel:(UILabel *)label texts:(NSArray<NSString *> *)texts
{
    CGFloat height = 0;
    if (!label) {
        return height;
    }
    for (NSString *text in texts) {
        height = MAX(height, CGRectIntegral([text boundingRectWithSize:CGSizeMake(label.frame.size.width, CGFLOAT_MAX)
                                                               options:NSStringDrawingUsesLineFragmentOrigin
                                                            attributes:@{
                                                                NSFontAttributeName: label.font
                                                            }
                                                               context:nil]).size.height);
    }
    return height;
}

- (NSArray <NSLayoutConstraint *> *)imageViewConstraints:(UIImageView *)imageView
{
    UIImage *img = imageView.image;
    return @[
        [imageView.widthAnchor constraintEqualToAnchor:imageView.heightAnchor multiplier:img.size.width / img.size.height],
        [imageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.centralView.leadingAnchor],
        [imageView.centerXAnchor constraintEqualToAnchor:self.centralView.centerXAnchor],
        [imageView.topAnchor constraintGreaterThanOrEqualToAnchor:self.centralView.topAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:self.centralView.bottomAnchor],
    ];
}

#pragma mark - Class methods

+ (VLCFirstStepsPage)page
{
    NSAssert(NO, @"page should be overriden in subclasses");
    return VLCFirstStepsPageCount;
}

+ (NSString *)pageTitleText
{
    NSAssert(NO, @"pageTitleText should be overriden in subclasses");
    return @"";
}

+ (NSString *)titleText
{
    NSAssert(NO, @"titleText should be overriden in subclasses");
    return @"";
}

+ (NSString *)descriptionText
{
    NSAssert(NO, @"descriptionText should be overriden in subclasses");
    return @"";
}

+ (NSArray *)pageClasses
{
    return @[
        [VLCFirstStepsiTunesSyncViewController class],
        [VLCFirstStepsWifiSharingViewController class],
        [VLCFirstStepsCloudViewController class],
    ];
}

+ (NSArray <NSString *> *)pageTitleTexts
{
    return [self.pageClasses valueForKeyPath: NSStringFromSelector(@selector(pageTitleText))];
}
+ (NSArray <NSString *> *)titleTexts
{
    return [self.pageClasses valueForKeyPath: NSStringFromSelector(@selector(titleText))];
}
+ (NSArray <NSString *> *)descriptionTexts
{
    return [self.pageClasses valueForKeyPath: NSStringFromSelector(@selector(descriptionText))];
}

@end
