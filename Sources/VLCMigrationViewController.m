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

@implementation VLCMigrationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.statusLabel setText:NSLocalizedString(@"UPGRADING_LIBRARY", "")];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        APLog(@"migrating coredata");
        [[MLMediaLibrary sharedMediaLibrary] migrateLibrary];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionHandler();
        });
    });
}
@end
