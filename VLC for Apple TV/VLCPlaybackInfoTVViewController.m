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
#import "VLCPlaybackInfoSpeedTVViewController.h"
#import "VLCPlaybackInfoAudioTVViewController.h"

@interface VLCPlaybackInfoTVViewController () <UITabBarControllerDelegate, UIGestureRecognizerDelegate>
@property (nonatomic) IBOutlet UIView *containerView;
@property (nonatomic) IBOutlet UIView *dimmingView;
@property (nonatomic) IBOutlet NSLayoutConstraint *containerHeightConstraint;
@property (nonatomic) IBOutlet UITabBarController *tabBarController;

@end

@implementation VLCPlaybackInfoTVViewController

- (NSArray<UIViewController*>*) tabViewControllers {
    return @[
             [[VLCPlaybackInfoSpeedTVViewController alloc] initWithNibName:nil bundle:nil],
             [[VLCPlaybackInfoAudioTVViewController alloc] initWithNibName:nil bundle:nil],
             ];
}



- (void)viewDidLoad
{
    [super viewDidLoad];

    UITabBarController *controller = [[UITabBarController alloc] init];
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


- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return YES;
}

- (void)swipeUpRecognized:(UISwipeGestureRecognizer *)recognizer {

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];

    UIViewController *viewController = self.tabBarController.selectedViewController;
    CGFloat tabbarHeight = CGRectGetHeight(self.tabBarController.tabBar.bounds);
    CGFloat controllerHeight = viewController.preferredContentSize.height;
    self.containerHeightConstraint.constant = controllerHeight + tabbarHeight;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         [self updateViewConstraints];
                         [self.view layoutIfNeeded];
                     }];
}


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

@end


@implementation VLCPlaybackInfoTVTransitioningAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *source = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *target = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    UIView *container = [transitionContext containerView];
    CGRect initialSourceFrame = [transitionContext initialFrameForViewController:source];
    // TODO: calculate
    CGFloat infoHeight = CGRectGetHeight(initialSourceFrame);

    CGRect largeFrame = ({
        CGRect frame = initialSourceFrame;
        frame.origin.y -=infoHeight;
        frame.size.height += infoHeight;
        frame;
    });
    CGRect smallFrame = initialSourceFrame;

    CGFloat targetAlpha = 1.0;
    CGRect fromFrame = initialSourceFrame;
    CGRect toFrame = initialSourceFrame;

    VLCPlaybackInfoTVViewController *infoVC = nil;
    if ([target isKindOfClass:[VLCPlaybackInfoTVViewController class]]) {
        infoVC = (VLCPlaybackInfoTVViewController*) target;
        infoVC.dimmingView.alpha = 0.0;
        targetAlpha = 1.0;
        toFrame = smallFrame;
        fromFrame = largeFrame;
        [container addSubview:target.view];
    } else if ([source isKindOfClass:[VLCPlaybackInfoTVViewController class]]) {
        infoVC = (VLCPlaybackInfoTVViewController*) source;
        infoVC.dimmingView.alpha = 1.0;
        targetAlpha = 0.0;
        toFrame = largeFrame;
        fromFrame = smallFrame;
    }

    infoVC.view.frame = fromFrame;
    [infoVC.view layoutIfNeeded];

    // fallback
    if (!infoVC) {
        target.view.frame = smallFrame;
    }

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                         infoVC.view.frame = toFrame;
                         [infoVC.view layoutIfNeeded];
                         infoVC.dimmingView.alpha = targetAlpha;
                     }
                     completion:^(BOOL finished) {
                         [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                     }];

}

@end