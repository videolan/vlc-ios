/*****************************************************************************
 * VLCArrangementViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCArrangementViewController.h"
#import "VLC-Swift.h"

@implementation VLCArrangementViewController
#ifdef VLC_HAS_ARRANGEMENT_SDK
{
    BOOL _secondaryVisible;
}

- (instancetype)initWithPrimaryViewController:(UIViewController *)primaryViewController
                      secondaryViewController:(UIViewController *)secondaryViewController
{
    self = [super init];
    if (self) {
        _primaryViewController = primaryViewController;
        [self setViewController:primaryViewController forPlacement:UIArrangementViewControllerViewPlacementPrimary];
        [self setViewController:secondaryViewController forPlacement:UIArrangementViewControllerViewPlacementSecondary];

        UISplitArrangement *arrangement = [UISplitArrangement splitArrangement];
        arrangement.axes = UIAxisHorizontal;
        [self updateArrangement:arrangement];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeDidChange)
                                                 name:kVLCThemeDidChangeNotification
                                               object:nil];
    [self themeDidChange];
}

- (void)themeDidChange
{
    self.view.backgroundColor = PresentationTheme.current.colors.background;
}

- (UINavigationItem *)navigationItem
{
    return _primaryViewController.navigationItem;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return _primaryViewController;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    UIArrangementViewState *secondaryState = [self stateForPlacement:UIArrangementViewControllerViewPlacementSecondary];
    BOOL secondaryVisible = secondaryState && !secondaryState.hidden;
    if (secondaryVisible == _secondaryVisible) {
        return;
    }

    _secondaryVisible = secondaryVisible;
    [self.delegate arrangementViewController:self didChangeSecondaryVisibility:secondaryVisible];
}
#else
- (instancetype)initWithPrimaryViewController:(UIViewController *)primaryViewController
                      secondaryViewController:(UIViewController *)secondaryViewController
{
    return nil;
}
#endif

@end
