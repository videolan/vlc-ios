/*****************************************************************************
 * VLCFirstStepsViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFirstStepsViewController.h"
#import "VLCFirstStepsFirstPageViewController.h"
#import "VLCFirstStepsSecondPageViewController.h"
#import "VLCFirstStepsThirdPageViewController.h"
#import "VLCFirstStepsFourthPageViewController.h"
#import "VLCFirstStepsFifthPageViewController.h"
#import "VLCFirstStepsSixthPageViewController.h"

@interface VLCFirstStepsViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
{
    UIPageViewController *pageVC;
}

@end

@implementation VLCFirstStepsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    pageVC = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    pageVC.dataSource = self;
    pageVC.delegate = self;

    [[pageVC view] setFrame:[[self view] bounds]];

    [pageVC setViewControllers:@[[[VLCFirstStepsFirstPageViewController alloc] initWithNibName:nil bundle:nil]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];

    UIBarButtonItem *dismissButton = [UIBarButtonItem themedDarkToolbarButtonWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) target:self andSelector:@selector(dismissFirstSteps)];
    self.navigationItem.rightBarButtonItem = dismissButton;
    self.title = NSLocalizedString(@"FIRST_STEPS_WELCOME", nil);
    self.view.backgroundColor = [UIColor blackColor];

    [self addChildViewController:pageVC];
    [self.view addSubview:[pageVC view]];
    [pageVC didMoveToParentViewController:self];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    UIViewController *returnedVC;
    NSUInteger currentPage = 0;

    if ([viewController respondsToSelector:@selector(page)])
        currentPage = (NSUInteger)[viewController performSelector:@selector(page) withObject:nil];

    switch (currentPage) {
        case 1:
            returnedVC = [[VLCFirstStepsSecondPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 2:
            returnedVC = [[VLCFirstStepsThirdPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 3:
            returnedVC = [[VLCFirstStepsFourthPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 4:
            returnedVC = [[VLCFirstStepsFifthPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 5:
            returnedVC = [[VLCFirstStepsSixthPageViewController alloc] initWithNibName:nil bundle:nil];
            break;

        default:
            nil;
    }

    return returnedVC;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    UIViewController *returnedVC;
    NSUInteger currentPage = 0;

    if ([viewController respondsToSelector:@selector(page)])
        currentPage = (NSUInteger)[viewController performSelector:@selector(page) withObject:nil];

    switch (currentPage) {
        case 2:
            returnedVC = [[VLCFirstStepsFirstPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 3:
            returnedVC = [[VLCFirstStepsSecondPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 4:
            returnedVC = [[VLCFirstStepsThirdPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 5:
            returnedVC = [[VLCFirstStepsFourthPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 6:
            returnedVC = [[VLCFirstStepsFifthPageViewController alloc] initWithNibName:nil bundle:nil];
            break;

        default:
            nil;
    }

    return returnedVC;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return 6;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

- (void)dismissFirstSteps
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    self.title = [[pageViewController viewControllers][0] pageTitle];
}

@end
