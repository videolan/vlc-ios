/*****************************************************************************
 * VLCSidebarController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSidebarController.h"
#import "VLCMenuTableViewController.h"
#import "UIViewController+RESideMenu.h"
#import "RESideMenu.h"

@interface VLCSidebarController()
{
    RESideMenu *_sideMenuViewController;
    VLCMenuTableViewController *_menuViewController;
    UIViewController *_contentViewController;
}

@end

@implementation VLCSidebarController

+ (instancetype)sharedInstance
{
    static VLCSidebarController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCSidebarController new];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];

    if (!self)
        return self;
    _menuViewController = [[VLCMenuTableViewController alloc] initWithNibName:nil bundle:nil];
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionLeftToRight) {
        _sideMenuViewController = [[RESideMenu alloc] initWithContentViewController:nil
                                                             leftMenuViewController:_menuViewController
                                                            rightMenuViewController:nil];
    } else {
        _sideMenuViewController = [[RESideMenu alloc] initWithContentViewController:nil
                                                             leftMenuViewController:nil
                                                            rightMenuViewController:_menuViewController];
    }
    _sideMenuViewController.backgroundImage = [UIImage imageNamed:@"menu-background"];

    return self;
}

#pragma mark - VC handling

- (UIViewController *)fullViewController
{
    return _sideMenuViewController;
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
    contentViewController.view.backgroundColor = [UIColor VLCMenuBackgroundColor];
    _sideMenuViewController.contentViewController = contentViewController;
}

- (UIViewController *)contentViewController
{
    return _sideMenuViewController.contentViewController;
}

#pragma mark - actual work

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UITableViewScrollPosition)scrollPosition
{
    [_menuViewController selectRowAtIndexPath:indexPath
                                     animated:NO
                               scrollPosition:scrollPosition];
}

- (void)hideSidebar
{
    [_sideMenuViewController hideMenuViewController];
}

- (void)toggleSidebar
{
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionLeftToRight) {
            [_sideMenuViewController presentLeftMenuViewController];
    } else {
            [_sideMenuViewController presentRightMenuViewController];
    }
}

@end
