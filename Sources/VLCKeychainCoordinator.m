/*****************************************************************************
 * VLCKeychainCoordinator.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCKeychainCoordinator.h"
#import "PAPasscodeViewController.h"
#import <XKKeychain/XKKeychainGenericPasswordItem.h>
#import <LocalAuthentication/LocalAuthentication.h>

NSString *const VLCPasscode = @"org.videolan.vlc-ios.passcode";

@interface VLCKeychainCoordinator () <PAPasscodeViewControllerDelegate>
{
    PAPasscodeViewController *_passcodeLockController;
    void (^_completion)(void);
    BOOL _avoidPromptingTouchID;
}

@end

@implementation VLCKeychainCoordinator

+ (instancetype)defaultCoordinator
{
    static VLCKeychainCoordinator *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCKeychainCoordinator new];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appInForeground:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    return self;
}

- (void)appInForeground:(NSNotification *)notification
{
    /* our touch ID session is killed by the OS if the app moves to background, so re-init */
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]){
        UINavigationController *navCon = (UINavigationController *)rootViewController.presentedViewController;
        if ([navCon.topViewController isKindOfClass:[PAPasscodeViewController class]] && [self touchIDEnabled]){
            [self _touchIDQuery];
        }
    }
}

- (NSString *)passcodeFromKeychain
{
    XKKeychainGenericPasswordItem *item = [XKKeychainGenericPasswordItem itemForService:VLCPasscode account:VLCPasscode error:nil];
    NSString *passcode = item.secret.stringValue;
    return passcode;
}

- (BOOL)touchIDEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingPasscodeAllowTouchID];
}

- (BOOL)passcodeLockEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingPasscodeOnKey];
}

- (void)validatePasscodeWithCompletion:(void(^)(void))completion
{
    _passcodeLockController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionEnter];
    _passcodeLockController.delegate = self;
    _passcodeLockController.passcode = [self passcodeFromKeychain];
    _completion = completion;

    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;

    if (rootViewController.presentedViewController)
        [rootViewController dismissViewControllerAnimated:NO completion:nil];

    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:_passcodeLockController];
    navCon.modalPresentationStyle = UIModalPresentationFullScreen;
    [rootViewController presentViewController:navCon animated:YES completion:^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingPasscodeAllowTouchID]) {
            [self _touchIDQuery];
        }
    }];
}

- (void)_touchIDQuery
{
    //if we just entered background don't show TouchID
    if (_avoidPromptingTouchID || [UIApplication sharedApplication].applicationState != UIApplicationStateActive)
        return;

    LAContext *myContext = [[LAContext alloc] init];
    if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil]) {
        _avoidPromptingTouchID = YES;
        [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                  localizedReason:NSLocalizedString(@"TOUCHID_UNLOCK", nil)
                            reply:^(BOOL success, NSError *error) {
                                //if we cancel we don't want to show TouchID again
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (success) {
                                        [[UIApplication sharedApplication].delegate.window.rootViewController dismissViewControllerAnimated:YES completion:^{
                                            _completion();
                                            _completion = nil;
                                            _avoidPromptingTouchID = NO;
                                        }];
                                    } else {
                                        //user hit cancel and wants to enter the passcode
                                        _avoidPromptingTouchID = YES;
                                    }
                                });
                            }];
    }
}

- (void)PAPasscodeViewControllerDidEnterPasscode:(PAPasscodeViewController *)controller
{
    _avoidPromptingTouchID = NO;
    [[UIApplication sharedApplication].delegate.window.rootViewController dismissViewControllerAnimated:YES completion:^{
        _completion();
        _completion = nil;
    }];
}

- (void)PAPasscodeViewController:(PAPasscodeViewController *)controller didFailToEnterPasscode:(NSInteger)attempts
{
    // FIXME: handle countless failed passcode attempts
}

- (void)setPasscode:(NSString *)passcode
{
    if (!passcode) {
        [XKKeychainGenericPasswordItem removeItemsForService:VLCPasscode error:nil];
        return;
    }

    XKKeychainGenericPasswordItem *keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
    keychainItem.service = VLCPasscode;
    keychainItem.account = VLCPasscode;
    keychainItem.secret.stringValue = passcode;
    [keychainItem saveWithError:nil];
}

@end
