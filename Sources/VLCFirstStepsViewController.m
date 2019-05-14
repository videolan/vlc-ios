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
#import "VLCFirstStepsiTunesSyncViewController.h"
#import "VLCFirstStepsWifiSharingViewController.h"
#import "VLCFirstStepsCloudViewController.h"
#import "VLC-Swift.h"

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

    [pageVC setViewControllers:@[[[VLCFirstStepsiTunesSyncViewController alloc] initWithNibName:nil bundle:nil]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];

    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissFirstSteps)];

    self.navigationItem.rightBarButtonItem = dismissButton;
    self.title = NSLocalizedString(@"FIRST_STEPS_ITUNES", nil);

    [self addChildViewController:pageVC];
    [self.view addSubview:[pageVC view]];
    [pageVC didMoveToParentViewController:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTheme) name:kVLCThemeDidChangeNotification object:nil];
    [self updateTheme];
}

- (void)updateTheme
{
    self.view.backgroundColor = PresentationTheme.current.colors.background;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return PresentationTheme.current.colors.statusBarStyle;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    UIViewController *returnedVC;
    NSUInteger currentPage = 0;

    if ([viewController respondsToSelector:@selector(page)])
        currentPage = (NSUInteger)[viewController performSelector:@selector(page) withObject:nil];

    switch (currentPage) {
        case 0:
            returnedVC = [[VLCFirstStepsWifiSharingViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 1:
            returnedVC = [[VLCFirstStepsCloudViewController alloc] initWithNibName:nil bundle:nil];
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
        case 1:
            returnedVC = [[VLCFirstStepsiTunesSyncViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 2:
            returnedVC = [[VLCFirstStepsWifiSharingViewController alloc] initWithNibName:nil bundle:nil];
            break;

        default:
            nil;
    }

    return returnedVC;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return 3;
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
