/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSearchController.h"
#import "VLCSearchableServerBrowsingTVViewController.h"

@implementation VLCSearchController

- (UIViewController *)targetViewControllerForAction:(SEL)action sender:(id)sender
{
    return self;
}

- (void)showViewController:(UIViewController *)vc sender:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:^{
        // The search bar's delegate should be the one displaying the folder's content,
        // not the search controller itself.
        if ([self.delegate isMemberOfClass:[VLCSearchableServerBrowsingTVViewController class]]) {
            [(VLCSearchableServerBrowsingTVViewController *)self.delegate showViewController:vc sender:sender];
        }
    }];
}

- (void)setupTapGesture
{
    UITapGestureRecognizer *menuTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuButtonPressed)];
    menuTapGestureRecognizer.allowedPressTypes = @[@(UIPressTypeMenu)];
    [self.view addGestureRecognizer:menuTapGestureRecognizer];
}

- (void)menuButtonPressed
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
