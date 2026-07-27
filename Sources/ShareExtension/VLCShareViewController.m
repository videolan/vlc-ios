/*****************************************************************************
 * VLCShareViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCShareViewController.h"

#ifndef NDEBUG
#define APLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define APLog(format, ...)
#endif

@interface VLCShareViewController ()
{
    UIActivityIndicatorView *_activityIndicator;
    UIProgressView *_progressView;
    UIImageView *_coneView;
    UILabel *_label;
    NSProgress *_progress;
    dispatch_queue_t _importQueue;
    NSUInteger _importedCount;
    BOOL _didStartImport;
}

@end

static void *VLCShareProgressContext = &VLCShareProgressContext;

@implementation VLCShareViewController

- (void)loadView
{
    UIColor *backgroundColor = [UIColor whiteColor];
    UIColor *textColor = [UIColor blackColor];
    UIColor *detailColor = [UIColor grayColor];
    if (@available(iOS 13.0, *)) {
        backgroundColor = UIColor.systemBackgroundColor;
        textColor = UIColor.labelColor;
        detailColor = UIColor.secondaryLabelColor;
    }

    self.view = [[UIView alloc] init];
    self.view.backgroundColor = backgroundColor;

    _activityIndicator = [[UIActivityIndicatorView alloc] init];
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    _activityIndicator.color = detailColor;
    [_activityIndicator startAnimating];
    [self.view addSubview:_activityIndicator];

    _label = [[UILabel alloc] init];
    _label.translatesAutoresizingMaskIntoConstraints = NO;
    _label.text = NSLocalizedString(@"SHARE_EXTENSION_IMPORTING", nil);
    _label.textColor = textColor;
    _label.textAlignment = NSTextAlignmentCenter;
    _label.numberOfLines = 0;
    _label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [self.view addSubview:_label];

    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_progressView];

    UIImage *cone = [[UIImage imageNamed:@"LaunchCone"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _coneView = [[UIImageView alloc] initWithImage:cone];
    _coneView.translatesAutoresizingMaskIntoConstraints = NO;
    _coneView.contentMode = UIViewContentModeScaleAspectFit;
    _coneView.tintColor = detailColor;
    [self.view addSubview:_coneView];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;

    NSLayoutConstraint *centerConstraint = [_label.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor];
    centerConstraint.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        centerConstraint,
        [_label.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:16.],
        [_label.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-16.],
        [_activityIndicator.bottomAnchor constraintEqualToAnchor:_label.topAnchor constant:-16.],
        [_activityIndicator.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_progressView.topAnchor constraintEqualToAnchor:_label.bottomAnchor constant:16.],
        [_progressView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:16.],
        [_progressView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-16.],
        [_coneView.topAnchor constraintGreaterThanOrEqualToAnchor:_progressView.bottomAnchor constant:16.],
        [_coneView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-20.],
        [_coneView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-16.],
        [_coneView.widthAnchor constraintEqualToConstant:48.],
        [_coneView.heightAnchor constraintEqualToConstant:48.]
    ]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.preferredContentSize = CGSizeMake(320., 220.);

    _importQueue = dispatch_queue_create("org.videolan.vlc-ios.shareextension", DISPATCH_QUEUE_SERIAL);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (_didStartImport) {
        return;
    }
    _didStartImport = YES;

    [self importAttachments];
}

- (void)dealloc
{
    [_progress removeObserver:self forKeyPath:@"fractionCompleted" context:VLCShareProgressContext];
}

#pragma mark - progress

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != VLCShareProgressContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    float fraction = (float)_progress.fractionCompleted;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_progressView setProgress:fraction animated:YES];
    });
}

#pragma mark - import

- (NSURL *)dropFolderURL
{
    NSString *groupIdentifier = [NSBundle.mainBundle objectForInfoDictionaryKey:@"MLKitGroupIdentifier"];
    if (!groupIdentifier) {
        return nil;
    }

    NSURL *containerURL = [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    return [containerURL URLByAppendingPathComponent:@"Inbox" isDirectory:YES];
}

- (void)importAttachments
{
    NSExtensionContext *extensionContext = self.extensionContext;
    NSURL *dropFolderURL = [self dropFolderURL];
    if (!extensionContext || !dropFolderURL) {
        [self finishWithSuccess:NO];
        return;
    }

    NSError *error;
    if (![NSFileManager.defaultManager createDirectoryAtURL:dropFolderURL
                               withIntermediateDirectories:YES
                                                attributes:nil
                                                     error:&error]) {
        APLog(@"%s: failed to create the drop folder: %@", __func__, error.localizedDescription);
        [self finishWithSuccess:NO];
        return;
    }

    NSMutableArray<NSItemProvider *> *providers = [NSMutableArray array];
    for (NSExtensionItem *item in extensionContext.inputItems) {
        NSArray<NSItemProvider *> *attachments = item.attachments;
        if (attachments.count > 0) {
            [providers addObjectsFromArray:attachments];
        }
    }

    if (providers.count == 0) {
        [self finishWithSuccess:NO];
        return;
    }

    dispatch_group_t importGroup = dispatch_group_create();

    _progress = [NSProgress discreteProgressWithTotalUnitCount:providers.count * 100];
    [_progress addObserver:self
                forKeyPath:@"fractionCompleted"
                   options:NSKeyValueObservingOptionNew
                   context:VLCShareProgressContext];

    for (NSItemProvider *provider in providers) {
        dispatch_group_enter(importGroup);
        NSProgress *itemProgress = [provider loadFileRepresentationForTypeIdentifier:@"public.data"
                                                                   completionHandler:^(NSURL *url, NSError *itemError) {
            BOOL imported = NO;
            if (url) {
                imported = [self copyToDropFolder:url dropFolderURL:dropFolderURL];
            } else {
                APLog(@"%s: no file representation received: %@", __func__, itemError.localizedDescription);
            }
            dispatch_sync(self->_importQueue, ^{
                if (imported) {
                    self->_importedCount++;
                }
                self->_progress.completedUnitCount += 10;
            });
            dispatch_group_leave(importGroup);
        }];

        [_progress addChild:itemProgress withPendingUnitCount:90];
    }

    dispatch_group_notify(importGroup, dispatch_get_main_queue(), ^{
        [self finishWithSuccess:self->_importedCount > 0];
    });
}

/* copy to a hidden name first so the app never picks up a file we are still writing */
- (BOOL)copyToDropFolder:(NSURL *)url dropFolderURL:(NSURL *)dropFolderURL
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSURL *destination = [self availableURLForFileNamed:url.lastPathComponent inFolder:dropFolderURL];
    NSURL *partialURL = [dropFolderURL URLByAppendingPathComponent:[@"." stringByAppendingString:destination.lastPathComponent]];

    [fileManager removeItemAtURL:partialURL error:nil];

    NSError *error;
    if (![fileManager copyItemAtURL:url toURL:partialURL error:&error]
        || ![fileManager moveItemAtURL:partialURL toURL:destination error:&error]) {
        APLog(@"%s: failed to import %@: %@", __func__, url.lastPathComponent, error.localizedDescription);
        [fileManager removeItemAtURL:partialURL error:nil];
        return NO;
    }

    return YES;
}

- (NSURL *)availableURLForFileNamed:(NSString *)fileName inFolder:(NSURL *)folderURL
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSURL *destination = [folderURL URLByAppendingPathComponent:fileName];

    if (![fileManager fileExistsAtPath:destination.path]) {
        return destination;
    }

    NSString *baseName = fileName.stringByDeletingPathExtension;
    NSString *fileExtension = fileName.pathExtension;
    NSUInteger index = 1;

    do {
        NSString *candidate = [NSString stringWithFormat:@"%@_%lu", baseName, (unsigned long)index];
        if (fileExtension.length > 0) {
            candidate = [candidate stringByAppendingPathExtension:fileExtension];
        }
        destination = [folderURL URLByAppendingPathComponent:candidate];
        index++;
    } while ([fileManager fileExistsAtPath:destination.path]);

    return destination;
}

- (void)finishWithSuccess:(BOOL)success
{
    [_activityIndicator stopAnimating];
    _progressView.hidden = !success;
    [_progressView setProgress:1. animated:YES];
    _label.text = success ? NSLocalizedString(@"SHARE_EXTENSION_IMPORTED", nil)
                          : NSLocalizedString(@"SHARE_EXTENSION_FAILED", nil);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((success ? .8 : 1.6) * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    });
}

@end
