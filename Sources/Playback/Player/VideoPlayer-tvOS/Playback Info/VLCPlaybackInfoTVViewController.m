/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
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

    [self setupTabBarItemAppearance];

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
    if ([UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        self.visualEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    }

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

- (void)setupTabBarItemAppearance
{
    UITabBarItem *tabBarItemApprearance = [UITabBarItem appearanceWhenContainedInInstancesOfClasses:@[[VLCPlaybackInfoTVTabBarController class]]];
    NSDictionary *attributesSelected = @{NSForegroundColorAttributeName : [UIColor colorWithWhite:0.75 alpha:1.0]};
    [tabBarItemApprearance setTitleTextAttributes:attributesSelected forState:UIControlStateSelected];
    NSDictionary *attributesFocused;
    if (@available(tvOS 13.0, *)) {
        attributesFocused = @{NSForegroundColorAttributeName : [UIColor blackColor]};
    } else {
        attributesFocused = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    }
    [tabBarItemApprearance setTitleTextAttributes:attributesFocused forState:UIControlStateFocused];
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

