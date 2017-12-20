/*****************************************************************************
 * VLCOpenInActivity.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Marc Etcheverry <marc # taplightsoftware com>
 *          Carola Nitz <caro # videolan org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOpenInActivity.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface VLCOpenInActivity () <UIDocumentInteractionControllerDelegate>
@end

@implementation VLCOpenInActivity
{
    NSMutableArray /* NSURL */ *_fileURLs;
    UIDocumentInteractionController *_documentInteractionController;
}

#pragma mark - UIActivity

+ (UIActivityCategory)activityCategory
{
    return UIActivityCategoryAction;
}

- (NSString *)activityType
{
	return NSStringFromClass([self class]);
}

- (NSString *)activityTitle
{
	return NSLocalizedString(@"SHARING_ACTIVITY_OPEN_IN_TITLE", nil);
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"OpenInActivityIcon"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]] &&
            [(NSURL *)activityItem isFileURL]) {
            return YES;
        }
    }

    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    _fileURLs = [[NSMutableArray alloc] initWithCapacity:[activityItems count]];
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]]
            && [(NSURL *)activityItem isFileURL]) {
            [_fileURLs addObject:activityItem];
		}
	}
}

- (void)performActivity
{
    if (!self.presentingViewController || !self.presentingBarButtonItem) {
        [self activityDidFinish:NO];
        return;
    }

    NSUInteger count = [_fileURLs count];

    if (count > 1) {
        [self presentFileSelectionActionController];
    } else if (count == 1) {
        [self presentDocumentInteractionControllerWithFileURL:[_fileURLs firstObject]];
    } else {
        VLCAlertView *alertView = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"SHARING_ERROR_NO_FILES", nil)
                                                              message:nil
                                                             delegate:nil
                                                    cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                    otherButtonTitles:nil];
        [alertView show];

        [self activityDidFinish:NO];
    }
}

#pragma mark - UIDocumentInteractionController

- (NSString *)UTTypeForFileURL:(NSURL *)url
{
    CFStringRef UTTypeStringRef = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)url.pathExtension, NULL);
    return (NSString *)CFBridgingRelease(UTTypeStringRef);
}

- (void)presentDocumentInteractionControllerWithFileURL:(NSURL *)fileURL
{
    NSParameterAssert(fileURL);

    if (!fileURL) {
        [self activityDidFinish:NO];
        return;
    }

    if (!self.presentingBarButtonItem) {
        [self activityDidFinish:NO];
        return;
    }

    _documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    _documentInteractionController.delegate = self;
    _documentInteractionController.UTI = [self UTTypeForFileURL:fileURL];

    __block BOOL controllerWasPresentedSuccessfully = NO;

    dispatch_block_t controllerPresentationBlock = ^{
        controllerWasPresentedSuccessfully = [_documentInteractionController presentOpenInMenuFromBarButtonItem:self.presentingBarButtonItem animated:YES];

        if (!controllerWasPresentedSuccessfully) {
            VLCAlertView *alertView = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"SHARING_ERROR_NO_APPLICATIONS", nil)
                                                                  message:nil
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        otherButtonTitles:nil];
            [alertView show];

            [self activityDidFinish:NO];
        }
    };

    if (![self.presentingViewController presentedViewController]) {
        controllerPresentationBlock();
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:controllerPresentationBlock];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    [self activityDidFinish:YES];
    _documentInteractionController = nil;
}

#pragma mark - UIAlertController

- (void)presentFileSelectionActionController
{
    UIAlertController *actionController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"SHARING_ACTION_SHEET_TITLE_CHOOSE_FILE", nil)
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleActionSheet];


    for (NSURL *fileURL in _fileURLs) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:[fileURL lastPathComponent]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           [self presentDocumentInteractionControllerWithFileURL:fileURL];
                                                       }];
        [actionController addAction:action];
    }
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self activityDidFinish:NO];
                                                         }];
    [actionController addAction:cancelAction];
    [self.presentingViewController presentViewController:actionController animated:YES completion:nil];
}

@end
