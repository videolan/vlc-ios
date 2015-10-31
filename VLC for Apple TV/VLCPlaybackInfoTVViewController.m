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

@interface VLCPlaybackInfoTVViewController ()
@property (nonatomic) IBOutlet UIView *containerView;
@property (nonatomic) IBOutlet UIView *dimmingView;
@property (nonatomic) IBOutlet NSLayoutConstraint *containerHeightConstraint;
@property (nonatomic) IBOutlet UITabBarController *tabBarController;

@end

@implementation VLCPlaybackInfoTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UITabBarController *controller = [[UITabBarController alloc] init];


    [self addChildViewController:controller];
    controller.view.frame = self.containerView.bounds;
    controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.containerView addSubview:controller.view];
    [controller didMoveToParentViewController:self];

    UISwipeGestureRecognizer *swipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUpRecognized:)];
    swipeUpRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUpRecognizer];
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return YES;
}

- (void)swipeUpRecognized:(UISwipeGestureRecognizer *)recognizer {

    // TODO: check if it was a navigation gesture in child??

    [self dismissViewControllerAnimated:YES completion:nil];
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