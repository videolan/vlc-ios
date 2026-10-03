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
#if TARGET_OS_IOS
#import "VLCFirstStepsiTunesSyncViewController.h"
#import "VLCFirstStepsCloudViewController.h"
#endif
#import "VLCFirstStepsWifiSharingViewController.h"
#import "VLC-Swift.h"

@interface VLCFirstStepsViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
{
    UIPageViewController *pageVC;
    UIPageControl *pageControl;
}

@end

@implementation VLCFirstStepsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    pageVC = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    pageVC.dataSource = self;
    pageVC.delegate = self;

    pageControl = [[UIPageControl alloc] init];
    pageControl.numberOfPages = VLCFirstStepsPageCount;
    pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    [pageControl addTarget:self action:@selector(pageControlValueChanged) forControlEvents:UIControlEventValueChanged];

#if TARGET_OS_IOS
    VLCFirstStepsBaseViewController *firstVC = [[VLCFirstStepsiTunesSyncViewController alloc] initWithNibName:nil bundle:nil];
#else
    VLCFirstStepsBaseViewController *firstVC = [[VLCFirstStepsWifiSharingViewController alloc] initWithNibName:nil bundle:nil];
#endif
    [pageVC setViewControllers:@[firstVC] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];

    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissFirstSteps)];

    self.navigationItem.rightBarButtonItem = dismissButton;
    self.navigationController.navigationBar.translucent = NO;

    [self addChildViewController:pageVC];
    UIView *pageView = pageVC.view;
    pageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:pageView];
    [self.view addSubview:pageControl];
    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [pageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [pageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [pageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [pageView.bottomAnchor constraintEqualToAnchor:pageControl.topAnchor],
        [pageControl.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
        [pageControl.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
        [pageControl.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
    ]];
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
    UINavigationBarAppearance *navigationBarAppearance = [VLCAppearanceManager navigationbarAppearance];
    self.navigationController.navigationBar.standardAppearance = navigationBarAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance;
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

    NSArray <Class> *pageClasses = VLCFirstStepsBaseViewController.pageClasses;
    NSUInteger beforeIndex = (VLCFirstStepsPageCount + currentPage - 1) % VLCFirstStepsPageCount;
    return [[pageClasses[beforeIndex] alloc] initWithNibName:nil bundle:nil];
}

- (VLCFirstStepsPage)currentPage
{
    VLCFirstStepsBaseViewController *currentVC = (VLCFirstStepsBaseViewController *)pageVC.viewControllers.firstObject;
    return currentVC.page;
}

- (void)pageControlValueChanged
{
    VLCFirstStepsPage currentPage = [self currentPage];
    VLCFirstStepsPage targetPage = (VLCFirstStepsPage)pageControl.currentPage;
    if (targetPage == currentPage) {
        return;
    }

    UIPageViewControllerNavigationDirection direction = targetPage > currentPage ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    UIViewController *targetVC = [[VLCFirstStepsBaseViewController.pageClasses[targetPage] alloc] initWithNibName:nil bundle:nil];
    pageControl.enabled = NO;
    [pageVC setViewControllers:@[targetVC] direction:direction animated:YES completion:^(BOOL finished) {
        self->pageControl.enabled = YES;
        self->pageControl.currentPage = [self currentPage];
        [self updateTitle];
    }];
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
    pageControl.currentPage = [self currentPage];
    [self updateTitle];
}

- (void)setupNavigationBar
{
    self.navigationController.navigationBar.prefersLargeTitles = NO;
}

@end
