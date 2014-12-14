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
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"

@interface VLCDocumentPickerController () <UIDocumentMenuDelegate, UIDocumentPickerDelegate>

@end

@implementation VLCDocumentPickerController

#pragma mark - Public Methods

- (void)showDocumentMenuViewController:(id)sender
{
    if (![UIDocumentMenuViewController class])
        return;

    UIDocumentMenuViewController *importMenu = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[(id)kUTTypeAudiovisualContent] inMode:UIDocumentPickerModeImport];
    importMenu.delegate = self;

    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIPopoverPresentationController *popoverPres = importMenu.popoverPresentationController;

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

    [rootVC presentViewController:importMenu animated:YES completion:nil];
}

#pragma mark - UIDocumentMenuDelegate

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker
{
    documentPicker.delegate = self;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { // on iPhone it's done in menu table vc
        VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate.menuViewController selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }

    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:documentPicker animated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[url lastPathComponent]];

    if (![fileManager fileExistsAtPath:filePath]) {
        NSError *error = nil;
        BOOL succes = [fileManager moveItemAtPath:[url path] toPath:filePath error:&error];

        if (succes) {
            VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            [appDelegate updateMediaList];
        }
    }
}

@end
