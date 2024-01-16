/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoTVViewController.h"
#import "VLCPlaybackInfoPlaybackTVViewController.h"
#import "VLCPlaybackInfoMediaInfoTVViewController.h"
#import "VLCPlaybackInfoTracksTVViewController.h"
#import "VLCPlaybackInfoChaptersTVViewController.h"

// just for appearance reasons
@interface VLCPlaybackInfoTVTabBarController : UITabBarController
@end
@implementation VLCPlaybackInfoTVTabBarController
@end

@interface VLCPlaybackInfoTVViewController ()
{
    NSArray<UIViewController<VLCPlaybackInfoPanelTVViewController> *> *_allTabViewControllers;
}
@end

@implementation VLCPlaybackInfoTVViewController

- (NSArray<UIViewController*>*)tabViewControllers
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    return [_allTabViewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id<VLCPlaybackInfoPanelTVViewController>  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [[evaluatedObject class] shouldBeVisibleForPlaybackController:vpc];
    }]];
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

    _allTabViewControllers = @[[[VLCPlaybackInfoChaptersTVViewController alloc] initWithNibName:nil bundle:nil],
                               [[VLCPlaybackInfoTracksTVViewController alloc] initWithNibName:nil bundle:nil],
                               [[VLCPlaybackInfoPlaybackTVViewController alloc] initWithNibName:nil bundle:nil],
                               [[VLCPlaybackInfoMediaInfoTVViewController alloc] initWithNibName:nil bundle:nil],
                               ];

    UITabBarController *controller = [[VLCPlaybackInfoTVTabBarController alloc] init];
    controller.delegate = self;
    self.tabBarController = controller;

    [self addChildViewController:controller];
    controller.view.frame = self.containerView.bounds;
    controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.containerView addSubview:controller.view];
    [controller didMoveToParentViewController:self];

    [self setupTabBarAppearance];

    UISwipeGestureRecognizer *swipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUpRecognized:)];
    swipeUpRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUpRecognizer.delegate = self;
    [self.view addGestureRecognizer:swipeUpRecognizer];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaPlayerChanged)
                                                 name:VLCPlaybackServicePlaybackMetadataDidChange
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.visualEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];

    UITabBarController *tabBarController = self.tabBarController;
    UIViewController *oldSelectedVC = tabBarController.selectedViewController;
    tabBarController.viewControllers = [self tabViewControllers];
    NSUInteger newIndex = [tabBarController.viewControllers indexOfObject:oldSelectedVC];
    if (newIndex == NSNotFound) {
        newIndex = 0;
    }
    tabBarController.selectedIndex = newIndex;
    [super viewWillAppear:animated];
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

- (void)setupTabBarAppearance
{
    _contentView.backgroundColor = UIColor.VLCTransparentDarkBackgroundColor;
    _tabBarController.tabBar.barTintColor = UIColor.VLCDarkBackgroundColor;

    UITabBarItem *tabBarItemApperance = [UITabBarItem appearanceWhenContainedInInstancesOfClasses:@[[VLCPlaybackInfoTVTabBarController class]]];
    NSDictionary *attributedSelected = @{NSForegroundColorAttributeName : UIColor.VLCLightTextColor};
    [tabBarItemApperance setTitleTextAttributes:attributedSelected forState:UIControlStateSelected];

    NSDictionary *attributesFocused = @{NSForegroundColorAttributeName : UIColor.VLCDarkTextColor};
    [tabBarItemApperance setTitleTextAttributes:attributesFocused forState:UIControlStateFocused];

    NSDictionary *attributesNormal = @{NSForegroundColorAttributeName : UIColor.VLCLightTextColor};
    [tabBarItemApperance setTitleTextAttributes:attributesNormal forState:UIControlStateNormal];
}

- (void)swipeUpRecognized:(UISwipeGestureRecognizer *)recognizer
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - media player delegate
- (void)mediaPlayerChanged
{
    [self updateViewConstraints];
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

@end

