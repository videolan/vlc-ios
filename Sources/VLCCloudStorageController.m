//
//  VLCCloudStorageController.m
//  VLC for iOS
//
//  Created by Carola Nitz on 31/12/14.
//  Copyright (c) 2014 VideoLAN. All rights reserved.
//

#import "VLCCloudStorageController.h"

@implementation VLCCloudStorageController

+ (VLCCloudStorageController *)sharedInstance {
    return nil;
}
- (void)startSession
{
    // nop
}
- (void)logout
{
    // nop
}
- (void)requestDirectoryListingAtPath:(NSString *)path
{
    // nop
}
- (BOOL)supportSorting {
    return NO;  //Return NO by default. If a subclass implemented sorting, override this method to return YES
}

@end
