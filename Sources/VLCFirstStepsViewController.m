/*****************************************************************************
 * VLCFirstStepsViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pavel Akhrameev <p.akhrameev@gmail.com>
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

    VLCFirstStepsBaseViewController *firstVC = [[VLCFirstStepsiTunesSyncViewController alloc] initWithNibName:nil bundle:nil];
    [pageVC setViewControllers:@[firstVC] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];

    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissFirstSteps)];

    self.navigationItem.rightBarButtonItem = dismissButton;
    self.navigationController.navigationBar.translucent = NO;

    [self addChildViewController:pageVC];
    [self.view addSubview:[pageVC view]];
    [pageVC didMoveToParentViewController:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTheme) name:kVLCThemeDidChangeNotification object:nil];
    [self updateTheme];
    [self updateTitle];
    [self setupNavigationBar];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    __weak typeof(self) weakSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf updateTitle];
    });
}

- (void)updateTitle
{
    self.title = pageVC.viewControllers.firstObject.title;
}

- (void)updateTheme
{
    self.view.backgroundColor = PresentationTheme.current.colors.background;
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *navigationBarAppearance = [VLCAppearanceManager navigationbarAppearance];
        self.navigationController.navigationBar.standardAppearance = navigationBarAppearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return PresentationTheme.current.colors.statusBarStyle;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    VLCFirstStepsPage currentPage = VLCFirstStepsPageFirst;
    if ([viewController respondsToSelector:@selector(page)]) {
        currentPage = (NSUInteger)[viewController performSelector:@selector(page) withObject:nil];
    }
    if (currentPage == VLCFirstStepsPageCount - 1) {
        return nil;
    }
    NSArray <Class> *pageClasses = VLCFirstStepsBaseViewController.pageClasses;
    NSUInteger afterIndex = (VLCFirstStepsPageCount + currentPage + 1) % VLCFirstStepsPageCount;
    return [[pageClasses[afterIndex] alloc] initWithNibName:nil bundle:nil];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    VLCFirstStepsPage currentPage = VLCFirstStepsPageFirst;
    if ([viewController respondsToSelector:@selector(page)]) {
        currentPage = (NSUInteger)[viewController performSelector:@selector(page) withObject:nil];
    }
    if (currentPage == VLCFirstStepsPageFirst) {
        return nil;
    }
    NSArray <Class> *pageClasses = VLCFirstStepsBaseViewController.pageClasses;
    NSUInteger beforeIndex = (VLCFirstStepsPageCount + currentPage - 1) % VLCFirstStepsPageCount;
    return [[pageClasses[beforeIndex] alloc] initWithNibName:nil bundle:nil];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return VLCFirstStepsPageCount;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

- (void)dismissFirstSteps
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    [self updateTitle];
}

- (void)setupNavigationBar
{
    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = NO;
    }
}

@end
