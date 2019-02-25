/*****************************************************************************
 * VLCMigrationViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMigrationViewController.h"
#import "VLC-Swift.h"

@implementation VLCMigrationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = PresentationTheme.current.colors.background;
    [self.statusLabel setText:NSLocalizedString(@"UPGRADING_LIBRARY", "")];
}
@end
