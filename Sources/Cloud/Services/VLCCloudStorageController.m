/*****************************************************************************
 * VLCCloudStorageController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015, 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCloudStorageController.h"

#import "VLCBoxController.h"
#import <OneDriveSDK.h>
#import "VLCOneDriveConstants.h"
#import "VLCDropboxController.h"
#import "VLCDropboxConstants.h"
#import "VLC-Swift.h"

@interface VLCCloudStorageController()
{
    BOOL _controllersLoaded;
}
@end

@implementation VLCCloudStorageController

+ (VLCCloudStorageController *)sharedInstance
{
    static VLCCloudStorageController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [[VLCCloudStorageController alloc] init];
    });

    return sharedInstance;
}

- (void)configureCloudControllers
{
    if (_controllersLoaded) {
        return;
    }

    VLCBoxController *boxController = [VLCBoxController sharedInstance];
    // Start Box session on init to check whether it is logged in or not as soon as possible
    [boxController startSession];

    // Configure Dropbox
    [DBClientsManager setupWithAppKey:kVLCDropboxAppKey];

    // Configure OneDrive
    [ODClient setMicrosoftAccountAppId:kVLCOneDriveClientID scopes:@[@"onedrive.readwrite", @"offline_access"]];

    VLCPCloudController  *controller = [VLCPCloudController pCloudInstance];
    // Start P Cloud session on init to check whether it is logged in or not as soon as possible
    [controller startSession];

    [DBClientsManager authorizedClient];

    _controllersLoaded = YES;
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

- (NSString *)createPotentialPathFrom:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *fileName = [path lastPathComponent];
    NSString *finalFilePath = [path stringByDeletingLastPathComponent];

    if ([fileManager fileExistsAtPath:path]) {
        NSString *potentialFilename;
        NSString *fileExtension = [fileName pathExtension];
        NSString *rawFileName = [fileName stringByDeletingPathExtension];
        for (NSUInteger x = 1; x < 100; x++) {
            potentialFilename = [NSString stringWithFormat:@"%@_%lu.%@", rawFileName, (unsigned long)x, fileExtension];
            if (![fileManager fileExistsAtPath:[finalFilePath stringByAppendingPathComponent:potentialFilename]]) {
                break;
            }
        }
        return [finalFilePath stringByAppendingPathComponent:potentialFilename];
    }
    return path;
}

- (VLCMedia *)setMediaNameMetadata:(VLCMedia *)media withName:(NSString *)name
{
    if (name.length) {
        media.metaData.title = name;
    }
    return media;
}

@end
