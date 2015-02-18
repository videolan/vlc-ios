//
//  VLCMigrationViewController.m
//  VLC for iOS
//
//  Created by Carola Nitz on 17/02/15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import "VLCMigrationViewController.h"

@implementation VLCMigrationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {

    }
     return self;
}

- (void)viewDidLoad {
    [self.statusLabel setText:NSLocalizedString(@"UPGRADING_LIBRARY", "")];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"migrating coredata");
        [[MLMediaLibrary sharedMediaLibrary] persistentStoreCoordinator];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionHandler();
        });
    });
}
@end
