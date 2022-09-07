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
#import "VLCPlaybackNavigationController.h"
#import "VLCPlaybackService+MediaLibrary.h"
#import "VLC-Swift.h"
#if TARGET_OS_TV
#import "VLCFullscreenMovieTVViewController.h"
#endif

#define SWIFT_VIDEO_PLAYER 1

static NSString *const VLCPlayerDisplayControllerDisplayModeKey = @"VLCPlayerDisplayControllerDisplayMode";

NSString *const VLCPlayerDisplayControllerDisplayMiniPlayer = @"VLCPlayerDisplayControllerDisplayMiniPlayer";
NSString *const VLCPlayerDisplayControllerHideMiniPlayer = @"VLCPlayerDisplayControllerHideMiniPlayer";

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
@property (nonatomic, strong) VLCServices *services;
@end

@implementation VLCPlayerDisplayController

- (instancetype _Nullable)initWithServices:(nullable id)services
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        NSAssert([services isKindOfClass:[VLCServices class]], @"VLCPlayerDisplayController: Injected services class issue");

        _services = services;

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(playbackDidStart:) name:VLCPlaybackServicePlaybackDidStart object:nil];
        [notificationCenter addObserver:self selector:@selector(playbackDidFail:) name:VLCPlaybackServicePlaybackDidFail object:nil];
        [notificationCenter addObserver:self selector:@selector(playbackDidStop:) name:VLCPlaybackServicePlaybackDidStop object:nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{VLCPlayerDisplayControllerDisplayModeKey : @(VLCPlayerDisplayControllerDisplayModeFullscreen)}];
    }
    return self;
}

- (void)viewDidLoad
{
    self.view = [[VLCUntouchableView alloc] initWithFrame:self.view.frame];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [[VLCPlaybackService sharedInstance] setPlayerDisplayController:self];

    VLCPlayerController *pc = [[VLCPlayerController alloc] initWithServices:_services];
    _videoPlayerViewController = [[VLCVideoPlayerViewController alloc]
                                  initWithServices:_services
                                  playerController:pc];

    [super viewDidLoad];
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
#if TARGET_OS_IOS
            _movieViewController = _videoPlayerViewController;
            ((VLCVideoPlayerViewController *)_movieViewController).delegate = self;
            [((VLCVideoPlayerViewController *)_movieViewController) setupQueueViewControllerWithQvc:_queueViewController];
#else
        _movieViewController = [[VLCFullscreenMovieTVViewController alloc] initWithNibName:nil bundle:nil];
#endif
        self.playbackController.delegate = _movieViewController;
        if (!_queueViewController) {
            [self initQueueViewController];
        }
    } else {
#if TARGET_OS_IOS
        _movieViewController = _videoPlayerViewController;
#endif
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
    UIViewController<VLCPlaybackServiceDelegate> *movieViewController = self.movieViewController;
    UINavigationController *navCon = [[VLCPlaybackNavigationController alloc] initWithRootViewController:movieViewController];
    navCon.modalPresentationStyle = UIModalPresentationFullScreen;
    [movieViewController prepareForMediaPlayback:self.playbackController];

    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window.rootViewController presentViewController:navCon animated:animated completion:nil];
}

#pragma mark - miniplayer

- (BOOL)isMiniPlayerVisible
{
    return ((UIView<VLCPlaybackServiceDelegate, VLCMiniPlayer>*)_miniPlaybackView).visible;
}

- (void)_showHideMiniPlaybackView
{
#if TARGET_OS_TV
    return;
#else
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(_showHideMiniPlaybackView) withObject:nil waitUntilDone:NO];
        return;
    }

    VLCPlaybackService *playbackController = [VLCPlaybackService sharedInstance];
    UIView<VLCPlaybackServiceDelegate, VLCMiniPlayer> *miniPlaybackView = (UIView<VLCPlaybackServiceDelegate, VLCMiniPlayer>*)self.miniPlaybackView;
    const NSTimeInterval animationDuration = 0.25;
    const BOOL activePlaybackSession = playbackController.isPlaying || playbackController.willPlay || playbackController.playerIsSetup;
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
            UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;

            // Until VideoMiniPlayer is integrated, only AudioMiniPlayer is used.
            self.miniPlaybackView = miniPlaybackView = [[VLCAudioMiniPlayer alloc] initWithService:_services.medialibraryService draggingDelegate:self];
            if (!_queueViewController) {
                [self initQueueViewController];
            }
            miniPlaybackView.translatesAutoresizingMaskIntoConstraints = NO;
            miniPlaybackView.userInteractionEnabled = YES;
            [self.view addSubview:miniPlaybackView];
            _bottomConstraint = [miniPlaybackView.topAnchor constraintEqualToAnchor:self.view.bottomAnchor];

            if (@available(iOS 11.0, *)) {
                _playqueueBottomConstraint = [miniPlaybackView.topAnchor constraintEqualToAnchor:rootViewController.view.safeAreaLayoutGuide.topAnchor
                                                                                        constant: 25.0];
                _leadingConstraint = [miniPlaybackView.leadingAnchor constraintEqualToAnchor:rootViewController.view.safeAreaLayoutGuide.leadingAnchor];
                _trailingConstraint = [miniPlaybackView.trailingAnchor constraintEqualToAnchor:rootViewController.view.safeAreaLayoutGuide.trailingAnchor];
            } else {
                _playqueueBottomConstraint = [miniPlaybackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant: 25.0];
                _leadingConstraint = [miniPlaybackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor];
                _trailingConstraint = [miniPlaybackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor];
            }

            [NSLayoutConstraint activateConstraints:
             @[_bottomConstraint,
               [miniPlaybackView.heightAnchor constraintEqualToConstant:((UIView<VLCPlaybackServiceDelegate, VLCMiniPlayer>*)self.miniPlaybackView).contentHeight],
               _leadingConstraint,
               _trailingConstraint,
               ]];
            ((VLCAudioMiniPlayer*)_miniPlaybackView).queueViewController = _queueViewController;
            [self.view layoutIfNeeded];
        }
        [self addPlayqueueToMiniPlayer];
        miniPlaybackView.visible = YES;
        [[NSNotificationCenter defaultCenter]
         postNotificationName:VLCPlayerDisplayControllerDisplayMiniPlayer object:self];
    } else if (needsHide) {
        miniPlaybackView.visible = NO;
        completionBlock = ^(BOOL finished) {
            UIView<VLCPlaybackServiceDelegate, VLCMiniPlayer> *miniPlaybackView = (UIView<VLCPlaybackServiceDelegate, VLCMiniPlayer>*)self.miniPlaybackView;
            if (miniPlaybackView.visible == NO) {
                [miniPlaybackView removeFromSuperview];
                self.miniPlaybackView = nil;
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:VLCPlayerDisplayControllerHideMiniPlayer object:self];
            }
            [self->_queueViewController hide];
            [self->_queueViewController removeFromParentViewController];
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
                             self.bottomConstraint.active = NO;
                             if (needsShow) {
                                 self.bottomConstraint = [miniPlaybackView.bottomAnchor constraintEqualToAnchor:self.realBottomAnchor];
                             } else {
                                 self.bottomConstraint = [miniPlaybackView.topAnchor constraintEqualToAnchor:self.bottomLayoutGuide.bottomAnchor];
                             }
                             self.bottomConstraint.active = YES;
                             [self.view layoutIfNeeded];
                         }
                         completion:completionBlock];
    }
#endif
}

- (void)addPlayqueueToMiniPlayer
{
    [_queueViewController didMoveToParentViewController:self];
}

#pragma mark - QueueViewController
#if TARGET_OS_IOS

- (void)initQueueViewController
{
    _queueViewController = [[VLCQueueViewController alloc] initWithMedialibraryService:_services.medialibraryService];
}

- (void)hintPlayqueueWithDelay:(NSTimeInterval)delay
{
    if (_miniPlaybackView && _queueViewController && !_hintingPlayqueue) {
        [_queueViewController reload];
        _hintingPlayqueue = YES;
        _bottomConstraint.constant -= 50.0;
        [UIView animateWithDuration:0.3 delay:delay options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.view layoutIfNeeded];
            self->_queueViewController.view.alpha = 1.0;
        } completion: ^(BOOL finished){
            self->_bottomConstraint.constant += 50.0;
            [UIView animateWithDuration:0.7 animations:^{
                [self.view layoutIfNeeded];
                self->_queueViewController.view.alpha = 0.0;
            } completion:^(BOOL finished) {
                self->_hintingPlayqueue = NO;
            }];
        }];
    }
}

#endif

#pragma mark - VideoPlayerViewControllerDelegate

- (void)videoPlayerViewControllerDidMinimize:(VLCVideoPlayerViewController *)videoPlayerViewController
{
    [self closeFullscreenPlayback];
    [self addPlayqueueToMiniPlayer];
}

- (BOOL)videoPlayerViewControllerShouldBeDisplayed:(VLCVideoPlayerViewController *)videoPlayerViewController
{
    return self.displayMode == VLCPlayerDisplayControllerDisplayModeFullscreen;
}

@end
