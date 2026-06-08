/*****************************************************************************
 * VLCPhotoLibraryController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPhotoLibraryController.h"
#import <PhotosUI/PhotosUI.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

API_AVAILABLE(ios(14.0))
@interface VLCPhotoLibraryController () <PHPickerViewControllerDelegate>

@end

@implementation VLCPhotoLibraryController

#pragma mark - Presentation

- (void)showPhotoLibraryPicker:(id)sender
{
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.filter = [PHPickerFilter videosFilter];
    configuration.selectionLimit = 0;

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    picker.delegate = self;

    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVC presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results
{
    [picker dismissViewControllerAnimated:YES completion:nil];

    if (results.count == 0) {
        return;
    }

    NSString *typeIdentifier = UTTypeMovie.identifier;
    dispatch_group_t group = dispatch_group_create();
    __block NSUInteger failureCount = 0;

    for (PHPickerResult *result in results) {
        NSItemProvider *itemProvider = result.itemProvider;

        dispatch_group_enter(group);
        [itemProvider loadFileRepresentationForTypeIdentifier:typeIdentifier
                                            completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
            BOOL success = (url != nil) && [self copyMediaAtURL:url];
            if (!success) {
                @synchronized (self) {
                    failureCount++;
                }
            }
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (failureCount > 0) {
            [self presentImportFailureAlertForCount:failureCount];
        }
    });
}

- (BOOL)copyMediaAtURL:(NSURL *)url
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];

    NSString *filePath = [self availablePathInDirectory:documentsPath forFileName:[url lastPathComponent]];

    NSError *error = nil;
    BOOL success = [fileManager copyItemAtPath:[url path] toPath:filePath error:&error];
    if (!success) {
        APLog(@"Failed to copy media from %@ to %@: %@", url, filePath, error);
    }
    return success;
}

- (void)presentImportFailureAlertForCount:(NSUInteger)count
{
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"PHOTO_LIBRARY_IMPORT_FAILED_MESSAGE", nil), (int)count];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"PHOTO_LIBRARY_IMPORT_FAILED", nil)
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];

    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

- (NSString *)availablePathInDirectory:(NSString *)directory forFileName:(NSString *)fileName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *candidate = [directory stringByAppendingPathComponent:fileName];

    if (![fileManager fileExistsAtPath:candidate]) {
        return candidate;
    }

    NSString *baseName = [fileName stringByDeletingPathExtension];
    NSString *pathExtension = [fileName pathExtension];
    NSUInteger counter = 1;

    do {
        NSString *numberedName = [NSString stringWithFormat:@"%@ %lu", baseName, (unsigned long)counter];
        if (pathExtension.length > 0) {
            numberedName = [numberedName stringByAppendingPathExtension:pathExtension];
        }
        candidate = [directory stringByAppendingPathComponent:numberedName];
        counter++;
    } while ([fileManager fileExistsAtPath:candidate]);

    return candidate;
}

@end
