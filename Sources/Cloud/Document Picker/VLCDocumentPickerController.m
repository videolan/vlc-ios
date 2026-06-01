/*****************************************************************************
 * VLCDocumentPickerController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tamas Timar <ttimar.vlc # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDocumentPickerController.h"
#import "VLCPlaybackService.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface VLCDocumentPickerController () <UIDocumentPickerDelegate>
@property (nonatomic, strong) VLCDocumentPickerController *retainedSelf;
@property (nonatomic, weak) UIViewController *presentingViewController;
@end

@implementation VLCDocumentPickerController

- (UIDocumentPickerViewController *)createPickerViewController
{
    if (@available(iOS 14.0, *)) {
        return [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeItem, UTTypeFolder] asCopy:NO];
    } else {
        return [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.item", @"public.folder"] inMode:UIDocumentPickerModeOpen];
    }
}

- (void)presentFromViewController:(UIViewController *)presentingViewController
                 initialDirectory:(NSURL *)initialDirectoryURL
{
    UIDocumentPickerViewController *picker = [self createPickerViewController];
    picker.delegate = self;
    picker.allowsMultipleSelection = YES;
    if (@available(iOS 13.0, *)) {
        picker.directoryURL = initialDirectoryURL;
    }

    self.presentingViewController = presentingViewController;
    self.retainedSelf = self;

    [presentingViewController presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    VLCMediaList *medialist = [[VLCMediaList alloc] init];

    if (urls.count == 1 && [[urls.firstObject pathExtension] isEqualToString:@""]) {
        [self appendFolderContentsAtURL:urls.firstObject toMediaList:medialist];
    } else {
        [self appendURLs:urls toMediaList:medialist];
    }

    if ([medialist count] > 0) {
        [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
    } else {
        [self showEmptyMediaListAlert];
    }

    self.retainedSelf = nil;
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    self.retainedSelf = nil;
}

#pragma mark - Private

- (void)appendFolderContentsAtURL:(NSURL *)folderURL toMediaList:(VLCMediaList *)medialist
{
    [folderURL startAccessingSecurityScopedResource];

    NSError *error = nil;
    NSArray<NSURL *> *filesInFolder = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:folderURL
                                                                    includingPropertiesForKeys:@[]
                                                                                       options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                         error:&error];
    if (error) {
        NSLog(@"Error reading directory: %@", error);
        return;
    }

    [self appendURLs:filesInFolder toMediaList:medialist];
}

- (void)appendURLs:(NSArray<NSURL *> *)urls toMediaList:(VLCMediaList *)medialist
{
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"absoluteString"
                                                                    ascending:YES
                                                                     selector:@selector(localizedStandardCompare:)];
    NSArray<NSURL *> *sortedURLs = [urls sortedArrayUsingDescriptors:@[sortDescriptor]];

    for (NSURL *url in sortedURLs) {
        if ([[url pathExtension] isEqualToString:@""]) {
            continue;
        }
        if ([url startAccessingSecurityScopedResource]) {
            [medialist addMedia:[VLCMedia mediaWithURL:url]];
            [[VLCPlaybackService sharedInstance].openedLocalURLs addObject:url];
        }
    }
}

- (void)showEmptyMediaListAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"EMPTY_MEDIA_LIST", "")
                                                                   message:NSLocalizedString(@"EMPTY_MEDIA_LIST_DESCRIPTION", "")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_DISMISS", "")
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self.presentingViewController presentViewController:alert animated:YES completion:nil];
}

@end
