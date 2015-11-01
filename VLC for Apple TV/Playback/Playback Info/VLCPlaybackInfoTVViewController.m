/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoTVViewController.h"
#import "VLCPlaybackInfoRateTVViewController.h"
#import "VLCPlaybackInfoAudioTVViewController.h"
#import "VLCPlaybackInfoTVAnimators.h"

// just for appearance reasons
@interface VLCPlaybackInfoTVTabBarController : UITabBarController
@end
@implementation VLCPlaybackInfoTVTabBarController
@end

@implementation VLCPlaybackInfoTVViewController

- (NSArray<UIViewController*>*)tabViewControllers
{
    return @[
             [[VLCPlaybackInfoRateTVViewController alloc] initWithNibName:nil bundle:nil],
             [[VLCPlaybackInfoAudioTVViewController alloc] initWithNibName:nil bundle:nil],
             ];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupTabBarItemAppearance];

    UITabBarController *controller = [[VLCPlaybackInfoTVTabBarController alloc] init];
    controller.delegate = self;
    controller.viewControllers = [self tabViewControllers];
    self.tabBarController = controller;

    [self addChildViewController:controller];
    controller.view.frame = self.containerView.bounds;
    controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.containerView addSubview:controller.view];
    [controller didMoveToParentViewController:self];

    UISwipeGestureRecognizer *swipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUpRecognized:)];
    swipeUpRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUpRecognizer.delegate = self;
    [self.view addGestureRecognizer:swipeUpRecognizer];
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return YES;
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    UIViewController *viewController = self.tabBarController.selectedViewController;
    CGFloat tabBarHeight = CGRectGetHeight(self.tabBarController.tabBar.bounds);
    self.tabBarRegiomHeightConstraint.constant = tabBarHeight;
    CGFloat controllerHeight = viewController.preferredContentSize.height;
    self.containerHeightConstraint.constant = controllerHeight;
}


- (void)setupTabBarItemAppearance
{
    UITabBarItem *tabBarItemApprearance = [UITabBarItem appearanceWhenContainedInInstancesOfClasses:@[[VLCPlaybackInfoTVTabBarController class]]];
    NSDictionary *attributesSelected = @{NSForegroundColorAttributeName : [UIColor colorWithWhite:0.75 alpha:1.0]};
    [tabBarItemApprearance setTitleTextAttributes:attributesSelected forState:UIControlStateSelected];
    NSDictionary *attributesFocused = @{NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:1.0]};
    [tabBarItemApprearance setTitleTextAttributes:attributesFocused forState:UIControlStateFocused];
}

- (void)swipeUpRecognized:(UISwipeGestureRecognizer *)recognizer
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - GestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    // FIXME: is there any other way to figure out if the tab bar item is currenlty focused?
    UIView *view = [[UIScreen mainScreen] focusedView];
    while (view) {
        if ([view isKindOfClass:[UITabBar class]]) {
            return YES;
        }
        view = view.superview;
    }
    return NO;
}

#pragma mark - TabBarControllerDelegate
- (nullable id <UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController *)tabBarController
                     animationControllerForTransitionFromViewController:(UIViewController *)fromVC
                                                       toViewController:(UIViewController *)toVC
{
    VLCPlaybackInfoTabBarTVTransitioningAnimator* animator = [[VLCPlaybackInfoTabBarTVTransitioningAnimator alloc] init];
    animator.infoContainerViewController = self;
    return animator;
}


@end

