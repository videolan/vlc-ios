/*****************************************************************************
 * VLCCloudServiceFactory.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCloudServiceFactory.h"

#import "VLCCloudStorageTableViewController.h"
#import "VLCDropboxTableViewController.h"
#import "VLCGoogleDriveTableViewController.h"
#import "VLCBoxTableViewController.h"

#import "VLC-Swift.h"

static NSString *const kVLCCloudServiceScheme = @"file";
static NSString *const kVLCCloudStorageNibName = @"VLCCloudStorageTableViewController";

@implementation VLCCloudServiceFactory

+ (VLCCloudService)serviceForURL:(NSURL *)url
{
    if ([url.scheme caseInsensitiveCompare:kVLCCloudServiceScheme] != NSOrderedSame) {
        return VLCCloudServiceNone;
    }

    NSString *host = url.host;

    if ([host caseInsensitiveCompare:@"DropBox"] == NSOrderedSame) {
        return VLCCloudServiceDropbox;
    }
    if ([host caseInsensitiveCompare:@"Drive"] == NSOrderedSame) {
        return VLCCloudServiceGoogleDrive;
    }
    if ([host caseInsensitiveCompare:@"Box"] == NSOrderedSame) {
        return VLCCloudServiceBox;
    }
    if ([host caseInsensitiveCompare:@"PCloud"] == NSOrderedSame) {
        return VLCCloudServicePCloud;
    }

    return VLCCloudServiceNone;
}

+ (UIImage *)iconForService:(VLCCloudService)service
{
    switch (service) {
        case VLCCloudServiceDropbox:
            return [UIImage imageNamed:@"DropboxCell"];
        case VLCCloudServiceGoogleDrive:
            return [UIImage imageNamed:@"DriveCell"];
        case VLCCloudServiceBox:
            return [UIImage imageNamed:@"BoxCell"];
        case VLCCloudServicePCloud:
            return [UIImage imageNamed:@"pCloudCell"];
        case VLCCloudServiceNone:
            return nil;
    }
}

+ (VLCCloudStorageTableViewController *)controllerForService:(VLCCloudService)service
{
    switch (service) {
        case VLCCloudServiceDropbox:
            return [[VLCDropboxTableViewController alloc] initWithNibName:kVLCCloudStorageNibName bundle:nil];
        case VLCCloudServiceGoogleDrive:
            return [[VLCGoogleDriveTableViewController alloc] initWithNibName:kVLCCloudStorageNibName bundle:nil];
        case VLCCloudServiceBox:
            return [[VLCBoxTableViewController alloc] initWithNibName:kVLCCloudStorageNibName bundle:nil];
        case VLCCloudServicePCloud:
            return [[VLCPCloudViewController alloc] initWithNibName:kVLCCloudStorageNibName bundle:nil];
        case VLCCloudServiceNone:
            return nil;
    }
}

+ (UIViewController *)browserForURL:(NSURL *)url
{
    VLCCloudStorageTableViewController *controller = [self controllerForService:[self serviceForURL:url]];
    if (!controller) {
        return nil;
    }

    NSString *path = url.path;
    controller.currentPath = [path hasPrefix:@"/"] ? [path substringFromIndex:1] : path;

    return controller;
}

@end
