/*****************************************************************************
 * VLCPlayerDisplayController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *          Neo Salmon <neos_dev@outlook.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlayerDisplayController.h"
#import "VLCPlaybackNavigationController.h"
#import "VLCPlaybackService+MediaLibrary.h"
#import "VLC-Swift.h"
#if TARGET_OS_TV
#import "VLCFullscreenMovieTVViewController.h"
#else
#import "UIStackView+Orientation.h"
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

@interface VLCPlayerDisplayController () <VLCVideoPlayerViewControllerDelegate>
@property (nonatomic, strong) UIViewController<VLCPlaybackServiceDelegate> *movieViewController;
@property (nonatomic, strong) UIViewController<VLCPlaybackServiceDelegate> *videoPlayerViewController;
@end

@interface VLCPlayerDisplayController () <VLCAudioPlayerViewControllerDelegate, VLCZoomTransitionDataSource>
@property (nonatomic, strong) UIViewController<VLCPlaybackServiceDelegate> *audioPlayerViewController;
@end

@implementation VLCPlayerDisplayController
{
    VLCMiniPlayerZoomTransitioningDelegate *_zoomTransitioningDelegate;
    VLCQueueViewController *_queueViewController;
    VLCStatusLabel *_statusLabel;
#if TARGET_OS_IOS
    UINotificationFeedbackGenerator *_queueFeedbackGenerator;
#endif
}

- (instancetype)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(playbackDidStart:) name:VLCPlaybackServicePlaybackDidStart object:nil];
        [notificationCenter addObserver:self selector:@selector(playbackDidFail:) name:VLCPlaybackServicePlaybackDidFail object:nil];
        [notificationCenter addObserver:self selector:@selector(playbackDidStop:) name:VLCPlaybackServicePlaybackDidStop object:nil];
        [notificationCenter addObserver:self selector:@selector(playbackDidMoveToNextMedia:) name:VLCPlaybackServicePlaybackDidMoveOnToNextItem object:nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{VLCPlayerDisplayControllerDisplayModeKey : @(VLCPlayerDisplayControllerDisplayModeFullscreen)}];
    }
    return self;
}

- (void)viewDidLoad
{
    self.view = [[VLCUntouchableView alloc] initWithFrame:self.view.frame];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [[VLCPlaybackService sharedInstance] setPlayerDisplayController:self];

    [super viewDidLoad];
}

#pragma mark - properties

- (UIViewController *)videoPlayerViewController
{
    if (_videoPlayerViewController) {
        return _videoPlayerViewController;
    }

    VLCPlayerController *pc = [[VLCPlayerController alloc] init];
    VLCAppCoordinator *ac = [VLCAppCoordinator sharedInstance];
#if TARGET_OS_IOS
    _videoPlayerViewController = [[VLCVideoPlayerViewController alloc]
                                  initWithMediaLibraryService:ac.mediaLibraryService
                                  rendererDiscovererManager:ac.rendererDiscovererManager
                                  playerController:pc];
#else
    _videoPlayerViewController = [[VLCVideoPlayerViewController alloc]
                                  initWithMediaLibraryService:ac.mediaLibraryService
                                  playerController:pc];
#endif

    return _videoPlayerViewController;
}

- (VLCPlayerDisplayControllerDisplayMode)displayMode
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:VLCPlayerDisplayControllerDisplayModeKey];
}

- (void)setDisplayMode:(VLCPlayerDisplayControllerDisplayMode)displayMode
{
    [[NSUserDefaults standardUserDefaults] setInteger:displayMode forKey:VLCPlayerDisplayControllerDisplayModeKey];
}

- (VLCPlaybackService *)playbackController {
    if (_playbackController == nil) {
        _playbackController = [VLCPlaybackService sharedInstance];
    }
    return _playbackController;
}

- (UIViewController<VLCPlaybackServiceDelegate> *)movieViewController
{
    if (!_movieViewController) {
        if (!_queueViewController) {
            [self initQueueViewController];
        }
#if TARGET_OS_TV
        _movieViewController = [[VLCFullscreenMovieTVViewController alloc] initWithNibName:nil bundle:nil];
#else
        _movieViewController = self.videoPlayerViewController;
        ((VLCVideoPlayerViewController *)_movieViewController).delegate = self;
        [((VLCVideoPlayerViewController *)_movieViewController) setupQueueViewControllerWithQvc:_queueViewController];
#endif
        self.playbackController.delegate = _movieViewController;
        if (!_queueViewController) {
            [self initQueueViewController];
        }
    } else {
#if !TARGET_OS_TV
        _movieViewController = self.videoPlayerViewController;
#endif
    }
    return _movieViewController;
}

- (UIViewController<VLCPlaybackServiceDelegate> *)audioPlayerViewController
{
    if (!_audioPlayerViewController) {
        if (!_queueViewController) {
            [self initQueueViewController];
        }

        VLCPlayerController *pc = [[VLCPlayerController alloc] init];
        VLCAppCoordinator *ac = [VLCAppCoordinator sharedInstance];
#if TARGET_OS_IOS
        _audioPlayerViewController = [[VLCAudioPlayerViewController alloc] initWithMediaLibraryService:ac.mediaLibraryService
                                                                             rendererDiscovererManager:ac.rendererDiscovererManager
                                                                                      playerController:pc];
#else
        _audioPlayerViewController = [[VLCAudioPlayerViewController alloc] initWithMediaLibraryService:ac.mediaLibraryService
                                                                                      playerController:pc];
#endif
        [((VLCAudioPlayerViewController *)_audioPlayerViewController) setupQueueViewControllerWith:_queueViewController];
        ((VLCAudioPlayerViewController *) _audioPlayerViewController).delegate = self;
        self.playbackController.delegate = _audioPlayerViewController;
    }

    return _audioPlayerViewController;
}

#pragma mark - Notification Handling

- (void)playbackDidStart:(NSNotification *)notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL enforceFullscreen = [[defaults objectForKey:kVLCSettingVideoFullscreenPlayback] boolValue];

    VLCMLMedia *media = _playbackController.currentlyPlayingLibraryMedia;
    BOOL expectsAudioOnlyContent = [notification.userInfo[kVLCPlayerExpectsAudioOnlyContent] isEqual:@YES];

    _currentMediaType = [media type];
    _playbackController.fullscreenSessionRequested = _currentMediaType != VLCMLMediaTypeAudio;

    if (self.playbackController.fullscreenSessionRequested && enforceFullscreen) {
        [self setDisplayMode:VLCPlayerDisplayControllerDisplayModeFullscreen];
    } else if (_currentMediaType == VLCMLMediaTypeAudio && _playbackController.numberOfVideoTracks > 0) {
        [self setDisplayMode:VLCPlayerDisplayControllerDisplayModeFullscreen];
    }

    if ([notification.userInfo[kVLCPlayerOpenInMiniPlayer] isEqual: @YES]) {
        [self setDisplayMode:VLCPlayerDisplayControllerDisplayModeMiniplayer];
    }

    switch (self.displayMode) {
        case VLCPlayerDisplayControllerDisplayModeFullscreen:
            if ((media.type == VLCMLMediaTypeAudio || _playbackController.playAsAudio || expectsAudioOnlyContent) &&
                _playbackController.numberOfVideoTracks == 0) {
                [self _presentAudioPlayerViewIfNeeded];
            } else {
                [self _presentFullscreenPlaybackViewIfNeeded];
            }
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
    _currentMediaType = VLCMLMediaTypeUnknown;
}

- (void)playbackDidFail:(NSNotification *)notification
{
    [self showPlaybackError];
}

- (void)playbackDidMoveToNextMedia:(NSNotification *)notification
{
    VLCMLMedia *media = _playbackController.currentlyPlayingLibraryMedia;
    BOOL isMiniPlayerVisible = VLCAppCoordinator.sharedInstance.tabBarController.isMiniPlayerVisible;

    VLCMLMediaType mediaType = [media type];
    if (media == nil || mediaType == VLCMLMediaTypeUnknown || isMiniPlayerVisible) {
        return;
    }

    if (_currentMediaType == VLCMLMediaTypeAudio && mediaType == VLCMLMediaTypeVideo) {
        [self setDisplayMode:VLCPlayerDisplayControllerDisplayModeFullscreen];
        [self _swapPlaybackRootTo:self.movieViewController];
    } else if (_currentMediaType == VLCMLMediaTypeVideo && mediaType == VLCMLMediaTypeAudio) {
        [self setDisplayMode:VLCPlayerDisplayControllerDisplayModeFullscreen];
        [self _swapPlaybackRootTo:self.audioPlayerViewController];
    }

    _currentMediaType = mediaType;
}

#pragma mark - API

- (void)showFullscreenPlayback
{
    self.displayMode = VLCPlayerDisplayControllerDisplayModeFullscreen;
    [self _presentFullscreenPlaybackViewIfNeeded];
}

- (void)showAudioPlayer
{
    self.displayMode = VLCPlayerDisplayControllerDisplayModeFullscreen;
    [self _presentAudioPlayerViewIfNeeded];
}

- (UIViewController *)_presentingControllerForPlaybackController:(UIViewController *)playbackController
{
    if (playbackController.navigationController) {
        return playbackController.navigationController;
    }
    return playbackController;
}

- (UIViewController *)_presentedPlaybackController
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIViewController *presentedController = window.rootViewController.presentedViewController;

    if (![presentedController isKindOfClass:[VLCPlaybackNavigationController class]]) {
        return nil;
    }

    return ((UINavigationController *)presentedController).topViewController;
}

- (BOOL)_isPlaybackControllerPresentedOrTransitioning:(UIViewController *)playbackController
{
    UIViewController *presentingController = [self _presentingControllerForPlaybackController:playbackController];
    return presentingController.presentingViewController != nil ||
           presentingController.isBeingPresented ||
           presentingController.isBeingDismissed;
}

- (void)closeFullscreenPlayback
{
    UIViewController *presentingController = [self _presentingControllerForPlaybackController:self.movieViewController];
    [presentingController dismissViewControllerAnimated:[self shouldAnimate] completion:^{
        [self _updateInterfaceOrientation];
    }];
    self.displayMode = VLCPlayerDisplayControllerDisplayModeMiniplayer;
    [self _showHideMiniPlaybackView];
}

- (void)closeAudioPlayer
{
    UIViewController *presentingController = [self _presentingControllerForPlaybackController:self.audioPlayerViewController];
    // Dismiss from the level above so any sub-menu presented on top of the player is torn down with it.
    UIViewController *dismisser = presentingController.presentingViewController ?: presentingController;
    self.displayMode = VLCPlayerDisplayControllerDisplayModeMiniplayer;
    [self _showHideMiniPlaybackViewAnimated:NO];
    [dismisser dismissViewControllerAnimated:[self shouldAnimate] completion:nil];
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
            if ([VLCKeychainCoordinator passcodeService].isApplicationLocked) {
                break;
            }
            if ([[self _presentedPlaybackController] isKindOfClass:[VLCAudioPlayerViewController class]]) {
                [self closeAudioPlayer];
            } else {
                [self _closeFullscreenPlayback];
            }
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
            if ([self.movieViewController respondsToSelector:@selector(showStatusMessage:)]) {
                [self.movieViewController showStatusMessage:failedString];
            }
            break;
        case VLCPlayerDisplayControllerDisplayModeMiniplayer:
        default:
            [VLCAlertViewController alertViewManagerWithTitle:failedString
                                                 errorMessage:nil
                                               viewController:self];
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
        if (![self _isPlaybackControllerPresentedOrTransitioning:self.movieViewController]) {
            [self _presentMovieViewControllerAnimated:[self shouldAnimate]];
        }
    });
}

-(void)_presentAudioPlayerViewIfNeeded
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self _isPlaybackControllerPresentedOrTransitioning:self.audioPlayerViewController]) {
            [self _presentAudioViewControllerAnimated:[self shouldAnimate]];
        }
    });
}

- (void)_closeFullscreenPlayback
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL animated = [self shouldAnimate];
        UIViewController *presentingController = [self _presentingControllerForPlaybackController:self.movieViewController];
        // Dismiss from the level above so any sub-menu presented on top of the player is torn down with it.
        UIViewController *dismisser = presentingController.presentingViewController ?: presentingController;
        [dismisser dismissViewControllerAnimated:animated completion:^{
            [self _updateInterfaceOrientation];
        }];
        [self _showHideMiniPlaybackView];
    });
}

- (void)_presentMovieViewControllerAnimated:(BOOL)animated
{
    UIViewController<VLCPlaybackServiceDelegate> *movieViewController = self.movieViewController;
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIViewController *rootViewController = window.rootViewController;
    UIViewController *presentedController = rootViewController.presentedViewController;

    if (presentedController) {
        if ([presentedController isKindOfClass:[VLCPlaybackNavigationController class]]) {
            UIViewController *presentedTopController = ((UINavigationController *)presentedController).topViewController;
            if (presentedTopController == movieViewController) {
                return;
            }

            [self _swapPlaybackRootTo:movieViewController];
        }
        return;
    }

    UINavigationController *navCon = [[VLCPlaybackNavigationController alloc] initWithRootViewController:movieViewController];
    navCon.modalPresentationStyle = UIModalPresentationOverFullScreen;
    navCon.modalPresentationCapturesStatusBarAppearance = YES;
    [movieViewController prepareForMediaPlayback:self.playbackController];

    [rootViewController presentViewController:navCon animated:animated completion:^{
        [self hideMiniPlayerIfNeeded];
    }];
}

- (void)_presentAudioViewControllerAnimated:(BOOL)animated
{
    UIViewController<VLCPlaybackServiceDelegate> *audioPlayerViewController = self.audioPlayerViewController;
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIViewController *rootViewController = window.rootViewController;
    UIViewController *presentedController = rootViewController.presentedViewController;

    if (presentedController) {
        if ([presentedController isKindOfClass:[VLCPlaybackNavigationController class]]) {
            UIViewController *presentedTopController = ((UINavigationController *)presentedController).topViewController;
            if (presentedTopController == audioPlayerViewController) {
                return;
            }

            [self _swapPlaybackRootTo:audioPlayerViewController];
        }
        return;
    }

    UINavigationController *navCon = [[VLCPlaybackNavigationController alloc] initWithRootViewController:audioPlayerViewController];
    navCon.modalPresentationStyle = UIModalPresentationOverFullScreen;
    navCon.modalPresentationCapturesStatusBarAppearance = YES;

    if (!_zoomTransitioningDelegate) {
        _zoomTransitioningDelegate = [[VLCMiniPlayerZoomTransitioningDelegate alloc] initWithDataSource:self];
    }
    navCon.transitioningDelegate = _zoomTransitioningDelegate;

    _playbackController.delegate = audioPlayerViewController;
    [audioPlayerViewController prepareForMediaPlayback:self.playbackController];

    [rootViewController presentViewController:navCon animated:animated completion:^{
        [self hideMiniPlayerIfNeeded];
    }];
}

- (void)_swapPlaybackRootTo:(UIViewController<VLCPlaybackServiceDelegate> *)target
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIViewController *presented = window.rootViewController.presentedViewController;

    if (![presented isKindOfClass:[VLCPlaybackNavigationController class]]) {
        if (target == self.audioPlayerViewController) {
            [self _presentAudioPlayerViewIfNeeded];
        } else {
            [self _presentFullscreenPlaybackViewIfNeeded];
        }
        return;
    }

    UINavigationController *navCon = (UINavigationController *)presented;
    if (navCon.topViewController == target) {
        return;
    }
    if (navCon.isBeingPresented || navCon.isBeingDismissed) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self _swapPlaybackRootTo:target];
        });
        return;
    }

    self.playbackController.delegate = target;
    [target prepareForMediaPlayback:self.playbackController];

    if ([self shouldAnimate]) {
        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.type = kCATransitionFade;
        [navCon.view.layer addAnimation:transition forKey:kCATransition];
    }
    [navCon setViewControllers:@[target] animated:NO];
    [self _updateInterfaceOrientation];
}

#if !TARGET_OS_TV
- (void)_updateInterfaceOrientation
{
    if (@available(iOS 16, *)) {
        UIWindowScene *windowScene = self.view.window.windowScene;
        if (windowScene) {
            id geometry = [[VLCWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:UIInterfaceOrientationMaskAllButUpsideDown];
            [windowScene requestGeometryUpdateWithPreferences:geometry errorHandler:nil];
            [self setNeedsUpdateOfSupportedInterfaceOrientations];
        }
    } else {
        VLCPlayerDisplayController *vpdc = [[VLCPlaybackService sharedInstance] playerDisplayController];
        VLCVideoPlayerViewController *videoVC = (VLCVideoPlayerViewController *)vpdc.videoPlayerViewController;
        videoVC.supportedInterfaceOrientations = UIInterfaceOrientationMaskAllButUpsideDown;
        [UIViewController attemptRotationToDeviceOrientation];
    }
}
#endif

#pragma mark - miniplayer

- (id<VLCZoomTransitionEndpoint>)miniPlayerZoomTransitionEndpoint
{
    return VLCAppCoordinator.sharedInstance.tabBarController.miniPlayerZoomEndpoint;
}

- (void)_showHideMiniPlaybackView
{
    [self _showHideMiniPlaybackViewAnimated:YES];
}

- (void)_showHideMiniPlaybackViewAnimated:(BOOL)animated
{
#if TARGET_OS_TV
    return;
#else
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _showHideMiniPlaybackViewAnimated:animated];
        });
        return;
    }

    VLCPlaybackService *playbackController = [VLCPlaybackService sharedInstance];
    VLCBottomTabBarController *bottomTabBar = VLCAppCoordinator.sharedInstance.tabBarController;
    const BOOL activePlaybackSession = playbackController.isPlaying || playbackController.playerIsSetup;

    BOOL needsShow = activePlaybackSession && !bottomTabBar.isMiniPlayerVisible;
    BOOL needsHide = !activePlaybackSession && bottomTabBar.isMiniPlayerVisible;

    if (self.editing) {
        needsHide = YES;
        needsShow = NO;
    }

    if (needsShow) {
        [self becomeFirstResponder];
        [VLCAppCoordinator.sharedInstance.tabBarController displayMiniPlayer:YES animated:animated];

        // Properly set the shuffle and repeat mode
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([userDefaults boolForKey:kVLCPlayerShouldRememberState]) {
            _playbackController.shuffleMode = [userDefaults boolForKey:kVLCPlayerIsShuffleEnabled];
            NSInteger repeatMode = [userDefaults integerForKey:kVLCPlayerIsRepeatEnabled];
            _playbackController.repeatMode = repeatMode;
        }
    } else if (needsHide) {
        [VLCAppCoordinator.sharedInstance.tabBarController displayMiniPlayer:NO animated:animated];
    }

    if (needsHide) {
        [playbackController savePlaybackState];
    }
#endif
}

- (void)hideMiniPlayerIfNeeded
{
    VLCBottomTabBarController *bottomTabBarController = VLCAppCoordinator.sharedInstance.tabBarController;
    if (bottomTabBarController.isMiniPlayerVisible) {
        [bottomTabBarController displayMiniPlayer:NO animated:YES];
        [self resignFirstResponder];
    }
}

#pragma mark - QueueViewController
#if !TARGET_OS_TV

- (void)initQueueViewController
{
    _queueViewController = [[VLCQueueViewController alloc] initWithMedialibraryService:[VLCAppCoordinator sharedInstance].mediaLibraryService];
}

- (void)_setupStatusLabel
{
    _statusLabel = [[VLCStatusLabel alloc] init];
    _statusLabel.hidden = YES;
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _statusLabel.textColor = UIColor.whiteColor;
    [self.view addSubview:_statusLabel];
    [self.view bringSubviewToFront:_statusLabel];
    [NSLayoutConstraint activateConstraints:@[
        [_statusLabel.centerXAnchor constraintEqualToAnchor: self.view.centerXAnchor],
        [_statusLabel.centerYAnchor constraintEqualToAnchor: self.view.centerYAnchor]
    ]];
}

- (void)showPlayqueueStatus:(VLCPlayerDisplayControllerQueueStatusMessage)status withDelay:(NSTimeInterval)delay
{
    if (!_statusLabel) {
        [self _setupStatusLabel];
    }
#if TARGET_OS_IOS
    if (!_queueFeedbackGenerator) {
        _queueFeedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
    }
#endif

    [NSTimer scheduledTimerWithTimeInterval:delay repeats:NO block:^(NSTimer *timer) {
#if TARGET_OS_IOS
        [self->_queueFeedbackGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
#endif
        NSString *message;
        switch (status) {
            case VLCPlayerDisplayControllerQueueStatusMessageAppended:
                message = NSLocalizedString(@"APPENDED_TO_QUEUE_STATUS_MESSAGE", nil);
                break;
            case VLCPlayerDisplayControllerQueueStatusMessagePlayingNext:
                message = NSLocalizedString(@"QUEUED_NEXT_STATUS_MESSAGE", nil);
                break;
        }
        [self->_statusLabel showStatusMessage:message];
    }];
}

#endif

#pragma mark - VideoPlayerViewControllerDelegate

- (void)videoPlayerViewControllerDidMinimize:(VLCVideoPlayerViewController *)videoPlayerViewController
{
    [self closeFullscreenPlayback];
}

- (BOOL)videoPlayerViewControllerShouldBeDisplayed:(VLCVideoPlayerViewController *)videoPlayerViewController
{
    return self.displayMode == VLCPlayerDisplayControllerDisplayModeFullscreen;
}

- (void)videoPlayerViewControllerShouldSwitchPlayer:(VLCVideoPlayerViewController *)videoPlayerViewController
{
    [self setDisplayMode:VLCPlayerDisplayControllerDisplayModeFullscreen];
    [self _swapPlaybackRootTo:self.audioPlayerViewController];
}

#pragma mark - AudioPlayerViewControllerDelegate

- (void)audioPlayerViewControllerDidMinimize:(VLCAudioPlayerViewController *)audioPlayerViewController
{
    [self closeAudioPlayer];
}

- (void)audioPlayerViewControllerDidClose:(VLCAudioPlayerViewController *)audioPlayerViewController
{
    UIViewController *presentingController = [self _presentingControllerForPlaybackController:self.audioPlayerViewController];
    [presentingController dismissViewControllerAnimated:[self shouldAnimate] completion:nil];
    self.displayMode = VLCPlayerDisplayControllerDisplayModeFullscreen;
    [[VLCPlaybackService sharedInstance] stopPlayback];
}

- (BOOL)audioPlayerViewControllerShouldBeDisplayed:(VLCAudioPlayerViewController *)audioPlayerViewController
{
    return self.displayMode == VLCPlayerDisplayControllerDisplayModeFullscreen;
}

- (void)audioPlayerViewControllerShouldSwitchPlayer:(VLCAudioPlayerViewController *)audioPlayerViewController
{
    [self setDisplayMode:VLCPlayerDisplayControllerDisplayModeFullscreen];
    [self _swapPlaybackRootTo:self.movieViewController];
}

#pragma mark - KeyCommands

- (void)handlePlayPauseKeyInput
{
    [_playbackController playPause];
}

- (void)keyLeftArrow
{
    NSInteger seekBy = [[NSUserDefaults standardUserDefaults] integerForKey:kVLCSettingPlaybackBackwardSkipLength];
    [_playbackController jumpBackward:(int)seekBy];
}

- (void)keyRightArrow
{
    NSInteger seekBy = [[NSUserDefaults standardUserDefaults] integerForKey:kVLCSettingPlaybackForwardSkipLength];
    [_playbackController jumpForward:(int)seekBy];
}

- (void)keyRightBracket
{
    [_playbackController changePlaybackRateByFactor:1.5];
}

- (void)keyLeftBracket
{
    [_playbackController changePlaybackRateByFactor:0.75];
}

- (void)keyEqual
{
    _playbackController.playbackRate = 1.0;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (NSArray<UIKeyCommand *> *)keyCommands
{
    UIKeyCommand *spaceKeyCommand = [UIKeyCommand keyCommandWithInput:@" " modifierFlags:0 action:@selector(handlePlayPauseKeyInput)];
    UIKeyCommand *enterKeyCommand = [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:@selector(handlePlayPauseGesture)];
    UIKeyCommand *leftKeyCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(keyLeftArrow)];
    UIKeyCommand *rightKeyCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:@selector(keyRightArrow)];
    UIKeyCommand *leftBracketKeyCommand = [UIKeyCommand keyCommandWithInput:@"[" modifierFlags:0 action:@selector(keyLeftBracket)];
    UIKeyCommand *rightBracketKeyCommand = [UIKeyCommand keyCommandWithInput:@"]" modifierFlags:0 action:@selector(keyRightBracket)];

    NSArray<UIKeyCommand *> *commands = @[spaceKeyCommand, enterKeyCommand, leftKeyCommand, rightKeyCommand, leftBracketKeyCommand, rightBracketKeyCommand];

    if (fabs([VLCPlaybackService sharedInstance].playbackRate - 1.0) > FLT_EPSILON) {
        UIKeyCommand *equalKeyCommand = [UIKeyCommand keyCommandWithInput:@"=" modifierFlags:0 action:@selector(keyEqual)];
        commands = [commands arrayByAddingObject:equalKeyCommand];
    }

    return commands;
}

@end
