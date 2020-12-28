/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDeletionCapableViewController.h"

@interface VLCDeletionCapableViewController ()
@property (nonatomic) UITapGestureRecognizer *playPausePressRecognizer;
@property (nonatomic) UITapGestureRecognizer *cancelRecognizer;
@property (nonatomic) NSIndexPath *currentlyFocusedIndexPath;
@property (nonatomic) NSTimer *hintTimer;

@end

@implementation VLCDeletionCapableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(startEditMode)];
    recognizer.allowedPressTypes = @[@(UIPressTypeSelect)];
    recognizer.minimumPressDuration = 1.0;
    [self.view addGestureRecognizer:recognizer];

    UITapGestureRecognizer *cancelRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditMode)];
    cancelRecognizer.allowedPressTypes = @[@(UIPressTypeSelect),@(UIPressTypeMenu)];
    cancelRecognizer.enabled = self.editing;
    self.cancelRecognizer = cancelRecognizer;
    [self.view addGestureRecognizer:cancelRecognizer];

    UITapGestureRecognizer *playPauseRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePlayPausePress)];
    playPauseRecognizer.allowedPressTypes = @[@(UIPressTypePlayPause)];
    playPauseRecognizer.enabled = self.editing;
    self.playPausePressRecognizer = playPauseRecognizer;
    [self.view addGestureRecognizer:playPauseRecognizer];
}

- (void)handlePlayPausePress
{
    if (!self.editing) {
        return;
    }

    NSString *fileToDelete = self.itemToDelete;
    if (fileToDelete == nil)
        return;
    NSIndexPath *indexPathToDelete = self.indexPathToDelete;

    NSString *title = fileToDelete.lastPathComponent;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_DELETE", nil)
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self deleteFileAtIndex:indexPathToDelete];
                                                         }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                           style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                                                               self.editing = NO;
                                                           }];

    [alertController addAction:deleteAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteFileAtIndex:(NSIndexPath *)indexPathToDelete
{
    [self.hintTimer invalidate];
    self.hintTimer = nil;
    [self animateDeletHintToVisibility:NO];
}

- (void)animateDeletHintToVisibility:(BOOL)visible
{
    const NSTimeInterval duration = 0.5;

    UIView *hintView = self.deleteHintView;

    if (hintView.hidden) {
        hintView.alpha = 0.0;
    }

    if (hintView.alpha == 0.0) {
        hintView.hidden = NO;
    }

    const CGFloat targetAlpha = visible ? 1.0 : 0.0;
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         hintView.alpha = targetAlpha;
                     }
                     completion:^(BOOL finished) {
                         if (hintView.alpha == 0.0) {
                             hintView.hidden = YES;
                         }
                     }];
}

- (void)hintTimerFired:(NSTimer *)timer
{
    const NSTimeInterval waitUntilHideInterval = 5.0;

    NSNumber *userInfo = [timer userInfo];
    BOOL shouldShow = [userInfo isKindOfClass:[NSNumber class]] && [userInfo boolValue];
    [self animateDeletHintToVisibility:shouldShow];
    if (shouldShow) {
        [self.hintTimer invalidate];
        self.hintTimer = [NSTimer scheduledTimerWithTimeInterval:waitUntilHideInterval target:self selector:@selector(hintTimerFired:) userInfo:@(NO) repeats:NO];
    }
}

- (void)startEditMode
{
    self.editing = YES;
}
- (void)endEditMode
{
    self.editing = NO;
}

- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];

    if (editing) {
        [self.hintTimer invalidate];
        self.hintTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(hintTimerFired:) userInfo:@(YES) repeats:NO];
    } else {
        [self.hintTimer invalidate];
        self.hintTimer = nil;
        [self animateDeletHintToVisibility:NO];
    }

    self.cancelRecognizer.enabled = editing;
    self.playPausePressRecognizer.enabled = editing;
}

@end
