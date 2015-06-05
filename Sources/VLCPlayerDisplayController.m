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
#import "VLCPlaybackNavigationController.h"
#import "VLCMovieViewController.h"
#import "VLCMiniPlaybackView.h"

static NSString *const VLCPlayerDisplayControllerDisplayModeKey = @"VLCPlayerDisplayControllerDisplayMode";

@interface VLCPlayerDisplayController ()
@property (nonatomic, strong) VLCMovieViewController *movieViewController;
@property (nonatomic, strong) VLCMiniPlaybackView *miniPlaybackView;
@end

@implementation VLCPlayerDisplayController

+ (void)initialize
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{VLCPlayerDisplayControllerDisplayModeKey : @(VLCPlayerDisplayControllerDisplayModeFullscreen)}];
}

static inline void commonSetup(VLCPlayerDisplayController *self)
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(playbackDidStart:) name:VLCPlaybackControllerPlaybackDidStart object:nil];
    [notificationCenter addObserver:self selector:@selector(playbackDidFail:) name:VLCPlaybackControllerPlaybackDidFail object:nil];
    [notificationCenter addObserver:self selector:@selector(playbackDidStop:) name:VLCPlaybackControllerPlaybackDidStop object:nil];

}
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        commonSetup(self);
    }
    return self;
}
- (void)awakeFromNib
{
    [super awakeFromNib];
    commonSetup(self);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupChildViewController];
}

#pragma mark - ChildViewController

- (void)setChildViewController:(UIViewController *)childViewController
{
    if (_childViewController) {
        [_childViewController willMoveToParentViewController:nil];
        [_childViewController.view removeFromSuperview];
        [_childViewController removeFromParentViewController];
    }
    _childViewController = childViewController;
    if (self.isViewLoaded) {
        [self setupChildViewController];
    }
}

- (void)setupChildViewController
{
    UIViewController *childViewController = self.childViewController;
    [self addChildViewController:childViewController];
    [self.view addSubview:childViewController.view];
    [childViewController didMoveToParentViewController:self];
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

- (VLCMovieViewController *)movieViewController
{
    if (!_movieViewController) {
        _movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];
        [VLCPlaybackController sharedInstance].delegate = _movieViewController;
    }
    return _movieViewController;
}

#pragma mark - Notification Handling

- (void)playbackDidStart:(NSNotification *)notification
{
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
    [self _closeFullscreenPlayback];
    self.displayMode = VLCPlayerDisplayControllerDisplayModeMiniplayer;
    [self _showHideMiniPlaybackView];
}

#pragma mark - presentation handling

- (BOOL)shouldAnimate
{
    return [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground;
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
    switch (self.displayMode) {
        case VLCPlayerDisplayControllerDisplayModeFullscreen:
            [self.movieViewController showStatusMessage:failedString];
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
}

#pragma mark - fullscreen player

- (void)_presentFullscreenPlaybackViewIfNeeded
{
    if (!self.movieViewController.presentingViewController) {
        [self _presentMovieViewControllerAnimated:[self shouldAnimate]];
    }
}

- (void)_closeFullscreenPlayback
{
    BOOL animated = [self shouldAnimate];
    [self.movieViewController setControlsHidden:YES animated:animated];
    [self.movieViewController dismissViewControllerAnimated:animated completion:nil];
    [self _showHideMiniPlaybackView];
}

- (void)_presentMovieViewControllerAnimated:(BOOL)animated
{
    VLCMovieViewController *movieViewController = self.movieViewController;
    UINavigationController *navCon = [[VLCPlaybackNavigationController alloc] initWithRootViewController:movieViewController];
    [movieViewController prepareForMediaPlayback:self.playbackController];
    navCon.modalPresentationStyle = UIModalPresentationFullScreen;
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window.rootViewController presentViewController:navCon animated:animated completion:nil];

}

#pragma mark - miniplayer

- (void)_showHideMiniPlaybackView
{
    VLCPlaybackController *playbackController = [VLCPlaybackController sharedInstance];
    VLCMiniPlaybackView *miniPlaybackView = self.miniPlaybackView;
    const NSTimeInterval animationDuration = 0.25;
    const BOOL activePlaybackSession = playbackController.activePlaybackSession;
    const BOOL miniPlayerVisible = miniPlaybackView.visible;

    const CGRect viewRect = self.view.frame;
    const CGFloat miniPlayerHeight = 60.;
    const CGRect miniPlayerFrameIn =  CGRectMake(0., viewRect.size.height-miniPlayerHeight, viewRect.size.width, miniPlayerHeight);
    const CGRect miniPlayerFrameOut = CGRectMake(0., viewRect.size.height, viewRect.size.width, miniPlayerHeight);

    BOOL needsShow = activePlaybackSession && !miniPlayerVisible;
    BOOL needsHide = !activePlaybackSession && miniPlayerVisible;

    if (self.editing) {
        needsHide = YES;
        needsShow = NO;
    }

    void (^completionBlock)(BOOL) = nil;
    if (needsShow) {
        if (!miniPlaybackView) {
            self.miniPlaybackView = miniPlaybackView = [[VLCMiniPlaybackView alloc] initWithFrame:miniPlayerFrameOut];
            miniPlaybackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
            [self.view addSubview:miniPlaybackView];
        }
        miniPlaybackView.visible = YES;
    } else if (needsHide) {
        miniPlaybackView.visible = NO;
        completionBlock = ^(BOOL finished) {
            VLCMiniPlaybackView *miniPlaybackView = self.miniPlaybackView;
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
    [miniPlaybackView setupForWork:playbackController];

    if (needsShow || needsHide) {
        UIViewController *childViewController = self.childViewController;

        const CGRect newMiniPlayerFrame = needsHide ? miniPlayerFrameOut : miniPlayerFrameIn;
        CGRect newChildViewFrame = childViewController.view.frame;
        newChildViewFrame.size.height = CGRectGetMinY(newMiniPlayerFrame)-CGRectGetMinY(newChildViewFrame);

        [UIView animateWithDuration:animationDuration
                              delay:animationDuration
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             miniPlaybackView.frame = newMiniPlayerFrame;
                             childViewController.view.frame = newChildViewFrame;
                         }
                         completion:completionBlock];
    }
    
}

@end
