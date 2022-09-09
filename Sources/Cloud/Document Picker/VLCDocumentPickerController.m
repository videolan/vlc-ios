/*****************************************************************************
 * VLCDocumentPickerController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tamas Timar <ttimar.vlc # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDocumentPickerController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "VLCMediaFileDiscoverer.h"

@interface VLCDocumentPickerController () <UIDocumentMenuDelegate, UIDocumentPickerDelegate>

@end

@implementation VLCDocumentPickerController

#pragma mark - Internal Methods

- (NSArray *)supportedUTIs
{
    NSArray *dict = [[[NSBundle mainBundle] infoDictionary]
                     objectForKey:@"CFBundleDocumentTypes"];

    NSMutableArray *result = [NSMutableArray array];

    for (NSDictionary *item in dict) {
        NSArray *contentTypes = [item objectForKey:@"LSItemContentTypes"];

        if (contentTypes != nil) {
            [result addObjectsFromArray:contentTypes];
        }
    }
    return [result copy];
}

- (UIViewController *)configuredPickerViewController
{
    NSArray *types = [self supportedUTIs];
    UIDocumentPickerMode mode = UIDocumentPickerModeImport;

    if (@available(iOS 11.2, *)) {
        UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:mode];
        picker.delegate = self;
        picker.allowsMultipleSelection = YES;

        return picker;
    } else {
        UIDocumentMenuViewController *picker = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:types inMode:mode];
        picker.delegate = self;

        return picker;
    }
}

- (void)showDocumentMenuViewController:(id)sender
{
    UIViewController *picker = [self configuredPickerViewController];

    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIPopoverPresentationController *popoverPres = picker.popoverPresentationController;

    if (popoverPres) { // not-nil on iPad
        UIView *sourceView = nil;
        if ([sender isKindOfClass:[UIView class]]) {
            sourceView = sender;
        } else {
            sourceView = rootVC.view;
        }

        popoverPres.sourceView = sourceView;
        popoverPres.sourceRect = sourceView.bounds;
        popoverPres.permittedArrowDirections = UIPopoverArrowDirectionLeft;
    }

    [rootVC presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIDocumentMenuDelegate

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker
{
    documentPicker.delegate = self;

    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:documentPicker animated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls NS_AVAILABLE_IOS(11_0);
{
    for (NSURL *url in urls) {
        [self documentPicker:controller didPickDocumentAtURL:url];
    }
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[url lastPathComponent]];

    NSError *error = nil;
    [fileManager moveItemAtPath:[url path] toPath:filePath error:&error];
    if (!error) {
        [[VLCMediaFileDiscoverer sharedInstance] updateMediaList];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"GDRIVE_ERROR_DOWNLOADING_FILE_TITLE", nil) message:error.description preferredStyle:UIAlertControllerStyleAlert];
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [rootVC dismissViewControllerAnimated:true completion:nil];
        }];
        [alert addAction:okAction];
        [rootVC presentViewController:alert animated:true completion:nil];
    }
}

@end
