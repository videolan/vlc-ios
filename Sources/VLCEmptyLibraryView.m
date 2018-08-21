/*****************************************************************************
 * VLCEmptyLibraryView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Mike JS. Choi <mkchoi212 # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "VLCEmptyLibraryView.h"
#import "VLCFirstStepsViewController.h"
#import "VLC-Swift.h"

@implementation VLCEmptyLibraryView

- (void)awakeFromNib
{
    _emptyLibraryLabel.text = NSLocalizedString(@"EMPTY_LIBRARY", nil);
    _emptyLibraryLongDescriptionLabel.text = NSLocalizedString(@"EMPTY_LIBRARY_LONG", nil);
    [_learnMoreButton setTitle:NSLocalizedString(@"BUTTON_LEARN_MORE", nil) forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeDidChange)
                                                 name:kVLCThemeDidChangeNotification
                                               object:nil];
    [self themeDidChange];
    [super awakeFromNib];
}

- (IBAction)learnMore:(id)sender
{
      UIViewController *firstStepsVC = [[VLCFirstStepsViewController alloc] initWithNibName:nil bundle:nil];
      UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:firstStepsVC];
      navCon.modalPresentationStyle = UIModalPresentationFormSheet;
      [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
}

- (void)themeDidChange
{
    _emptyLibraryLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    _emptyLibraryLongDescriptionLabel.textColor = PresentationTheme.current.colors.lightTextColor;
}

@end
