/*****************************************************************************
 * VLCPlayerDisplayController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlayerDisplayController.h"
#import "VLCPlaybackController.h"
#import "VLCMiniPlaybackView.h"
#import "VLCPlaybackNavigationController.h"
#import "VLCPlaybackController+MediaLibrary.h"

#if TARGET_OS_IOS
#import "VLCMovieViewController.h"
#else
#import "VLCFullscreenMovieTVViewController.h"
#endif

static NSString *const VLCPlayerDisplayControllerDisplayModeKey = @"VLCPlayerDisplayControllerDisplayMode";

@interface VLCUntouchableView: UIView
@end

@implementation VLCUntouchableView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *result = [super hitTest:point withEvent:event];
    return result == self ? nil : result;
}

@end

@interface VLCPlayerDisplayController () <VLCMovieViewControllerDelegate>
@property (nonatomic, strong) UIViewController<VLCPlaybackControllerDelegate> *movieViewController;
@property (nonatomic, strong) UIView<VLCPlaybackControllerDelegate, VLCMiniPlaybackViewInterface> *miniPlaybackView;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@end

@implementation VLCPlayerDisplayController

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(playbackDidStart:) name:VLCPlaybackControllerPlaybackDidStart object:nil];
        [notificationCenter addObserver:self selector:@selector(playbackDidFail:) name:VLCPlaybackControllerPlaybackDidFail object:nil];
        [notificationCenter addObserver:self selector:@selector(playbackDidStop:) name:VLCPlaybackControllerPlaybackDidStop object:nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{VLCPlayerDisplayControllerDisplayModeKey : @(VLCPlayerDisplayControllerDisplayModeFullscreen)}];
    }
    return self;
}

- (void)viewDidLoad
{
    self.view = [[VLCUntouchableView alloc] initWithFrame:self.view.frame];
}

#pragma mark - properties

- (VLCPlayerDisplayControllerDisplayMode)displayMode
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:VLCPlayerDisplayControllerDisplayModeKey];
}

- (void)setDisplayMode:(VLCPlayerDisplayControllerDisplayMode)displayMode
{
    [[NSUserDefaults standardUserDefaults] setInteger:displayMode forKey:VLCPlayerDisplayControllerDisplayModeKey];
}

- (VLCPlaybackController *)playbackController {
    if (_playbackController == nil) {
        _playbackController = [VLCPlaybackController sharedInstance];
    }
    return _playbackController;
}

- (UIViewController<VLCPlaybackControllerDelegate> *)movieViewController
{
    if (!_movieViewController) {
#if TARGET_OS_IOS
        _movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];
        ((VLCMovieViewController *)_movieViewController).delegate = self;
#else
        _movieViewController = [[VLCFullscreenMovieTVViewController alloc] initWithNibName:nil bundle:nil];
#endif
        self.playbackController.delegate = _movieViewController;
    }
    return _movieViewController;
}

#pragma mark - Notification Handling

- (void)playbackDidStart:(NSNotification *)notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL enforceFullscreen = [[defaults objectForKey:kVLCSettingVideoFullscreenPlayback] boolValue];

    if (self.playbackController.fullscreenSessionRequested && enforceFullscreen) {
        [self showFullscreenPlayback];
        return;
    }

    switch (self.displayMode) {
        case VLCPlayerDisplayControllerDisplayModeFullscreen:
            [self _presentFullscreenPlaybackViewIfNeeded];
            break;
        case VLCPlayerDisplayControllerDisplayModeMiniplayer:
            [self _showHideMiniPlaybackView];
            break;
        default:
            break;
    }
}

- (void)playbackDidStop:(NSNotification *)notification
{
    [self dismissPlaybackView];
}

- (void)playbackDidFail:(NSNotification *)notification
{
    [self showPlaybackError];
}

#pragma mark - API

- (void)showFullscreenPlayback
{
    self.displayMode = VLCPlayerDisplayControllerDisplayModeFullscreen;
    [self _presentFullscreenPlaybackViewIfNeeded];
}

- (void)closeFullscreenPlayback
{
    [self.movieViewController dismissViewControllerAnimated:[self shouldAnimate] completion:nil];
    self.displayMode = VLCPlayerDisplayControllerDisplayModeMiniplayer;
    [self _showHideMiniPlaybackView];
}

#pragma mark - presentation handling

- (BOOL)shouldAnimate
{
    return [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground;
}

- (void)pushPlaybackView
{
    switch (self.displayMode) {
        case VLCPlayerDisplayControllerDisplayModeFullscreen:
            [self _presentFullscreenPlaybackViewIfNeeded];
            break;
        case VLCPlayerDisplayControllerDisplayModeMiniplayer:
            [self _showHideMiniPlaybackView];
        default:
            break;
    }
}

- (void)dismissPlaybackView
{
    switch (self.displayMode) {
        case VLCPlayerDisplayControllerDisplayModeFullscreen:
            [self _closeFullscreenPlayback];
            break;
        case VLCPlayerDisplayControllerDisplayModeMiniplayer:
            [self _showHideMiniPlaybackView];
        default:
            break;
    }
}

- (void)showPlaybackError
{
    NSString *failedString = NSLocalizedString(@"PLAYBACK_FAILED", nil);
#if TARGET_OS_IOS
    switch (self.displayMode) {
        case VLCPlayerDisplayControllerDisplayModeFullscreen:
            if ([self.movieViewController respondsToSelector:@selector(showStatusMessage:forPlaybackController:)]) {
                [self.movieViewController showStatusMessage:failedString forPlaybackController:nil];
            }
            break;
        case VLCPlayerDisplayControllerDisplayModeMiniplayer:
        default:

            [[[VLCAlertView alloc] initWithTitle:failedString
                                         message:nil
                                        delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                               otherButtonTitles:nil] show];
            break;
    }
#else
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:failedString
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];

    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
#endif
}

#pragma mark - fullscreen player

- (void)_presentFullscreenPlaybackViewIfNeeded
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.movieViewController.presentingViewController) {
            [self _presentMovieViewControllerAnimated:[self shouldAnimate]];
        }
    });
}

- (void)_closeFullscreenPlayback
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL animated = [self shouldAnimate];
        [self.movieViewController dismissViewControllerAnimated:animated completion:nil];
        [self _showHideMiniPlaybackView];
    });
}

- (void)_presentMovieViewControllerAnimated:(BOOL)animated
{
    UIViewController<VLCPlaybackControllerDelegate> *movieViewController = self.movieViewController;
    UINavigationController *navCon = [[VLCPlaybackNavigationController alloc] initWithRootViewController:movieViewController];
    [movieViewController prepareForMediaPlayback:self.playbackController];

    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window.rootViewController presentViewController:navCon animated:animated completion:nil];
}

#pragma mark - miniplayer

- (void)_showHideMiniPlaybackView
{
#if TARGET_OS_TV
    return;
#else
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(_showHideMiniPlaybackView) withObject:nil waitUntilDone:NO];
        return;
    }

    VLCPlaybackController *playbackController = [VLCPlaybackController sharedInstance];
    UIView<VLCPlaybackControllerDelegate, VLCMiniPlaybackViewInterface> *miniPlaybackView = self.miniPlaybackView;
    const NSTimeInterval animationDuration = 0.25;
    const BOOL activePlaybackSession = playbackController.isPlaying || playbackController.willPlay;
    const BOOL miniPlayerVisible = miniPlaybackView.visible;

    BOOL needsShow = activePlaybackSession && !miniPlayerVisible;
    BOOL needsHide = !activePlaybackSession && miniPlayerVisible;

    if (self.editing) {
        needsHide = YES;
        needsShow = NO;
    }

    void (^completionBlock)(BOOL) = nil;
    if (needsShow) {
        if (!miniPlaybackView) {
            self.miniPlaybackView = miniPlaybackView = [[VLCMiniPlaybackView alloc] initWithFrame:CGRectZero];
            miniPlaybackView.translatesAutoresizingMaskIntoConstraints = NO;
            miniPlaybackView.userInteractionEnabled = YES;
            [self.view addSubview:miniPlaybackView];
            _bottomConstraint = [miniPlaybackView.topAnchor constraintEqualToAnchor:self.view.bottomAnchor];
            [NSLayoutConstraint activateConstraints:
             @[_bottomConstraint,
               [miniPlaybackView.heightAnchor constraintEqualToConstant:60.0],
               [miniPlaybackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
               [miniPlaybackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
               ]];
            [self.view layoutIfNeeded];
        }
        miniPlaybackView.visible = YES;
    } else if (needsHide) {
        miniPlaybackView.visible = NO;
        completionBlock = ^(BOOL finished) {
            UIView<VLCPlaybackControllerDelegate, VLCMiniPlaybackViewInterface> *miniPlaybackView = self.miniPlaybackView;
            if (miniPlaybackView.visible == NO) {
                [miniPlaybackView removeFromSuperview];
                self.miniPlaybackView = nil;
            }
        };
    }
    //when switching between tableview and collectionview all subviews are removed, make sure to readd it when this happens
    if (!miniPlaybackView.superview && miniPlayerVisible) {
        [self.view addSubview:miniPlaybackView];
    }
    // either way update view
    [miniPlaybackView prepareForMediaPlayback:playbackController];

    if (needsShow || needsHide) {
        [UIView animateWithDuration:animationDuration
                              delay:animationDuration
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.bottomConstraint.constant = needsHide ? 0 : -_miniPlaybackView.frame.size.height -self.view.layoutMargins.bottom;
                             [self.view layoutIfNeeded];
                         }
                         completion:completionBlock];
    }
#endif
}

#pragma mark - MovieViewControllerDelegate

- (void)movieViewControllerDidSelectMinimize:(VLCMovieViewController *)movieViewController
{
    [self closeFullscreenPlayback];
}

- (BOOL)movieViewControllerShouldBeDisplayed:(VLCMovieViewController *)movieViewController
{
    return self.displayMode == VLCPlayerDisplayControllerDisplayModeFullscreen;
}
@end
