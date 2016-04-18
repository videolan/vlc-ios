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
#import "VLCAppDelegate.h"
#import "SSKeychain.h"
#import <LocalAuthentication/LocalAuthentication.h>

NSString *const VLCPasscodeValidated = @"VLCPasscodeValidated";

NSString *const VLCPasscode = @"org.videolan.vlc-ios.passcode";

@interface VLCKeychainCoordinator () <PAPasscodeViewControllerDelegate>
{
    PAPasscodeViewController *_passcodeLockController;
    NSDictionary *_passcodeQuery;
    BOOL _inValidation;
    BOOL _inTouchID;
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)appInForeground:(NSNotification *)notification
{
    /* our touch ID session is killed by the OS if the app moves to background, so re-init */
    if (_inValidation) {
        if (SYSTEM_RUNS_IOS8_OR_LATER) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingPasscodeAllowTouchID]) {
                [self _touchIDQuery];
            }
        }
    }
}

- (NSString *)_obtainPasscode
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL wasReset = [defaults boolForKey:kVLCSettingPasscodeResetOnUpgrade];
    if (wasReset) {
        NSString *passcode = [SSKeychain passwordForService:VLCPasscode account:VLCPasscode];
        return passcode;
    }

    [SSKeychain deletePasswordForService:VLCPasscode account:VLCPasscode];
    [defaults setBool:YES forKey:kVLCSettingPasscodeResetOnUpgrade];
    [defaults synchronize];

    return nil;
}

- (BOOL)passcodeLockEnabled
{
    NSString *passcode = [self _obtainPasscode];

    if (!passcode)
        return NO;

    if (passcode.length == 0)
        return NO;

    return YES;
}

- (void)validatePasscode
{
    /* we may be called repeatedly as Touch ID uses an out-of-process dialog */
    if (_inValidation)
        return;
    _inValidation = YES;

    NSString *passcode = [self _obtainPasscode];
    if (passcode == nil || [passcode isEqualToString:@""]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPasscodeValidated object:self];
        return;
    }

    _passcodeLockController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionEnter];
    _passcodeLockController.delegate = self;
    _passcodeLockController.passcode = passcode;

    VLCAppDelegate *appDelegate = (VLCAppDelegate *)[UIApplication sharedApplication].delegate;

    if (appDelegate.window.rootViewController.presentedViewController)
        [appDelegate.window.rootViewController dismissViewControllerAnimated:NO completion:nil];

    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:_passcodeLockController];
    navCon.modalPresentationStyle = UIModalPresentationFullScreen;
    [appDelegate.window.rootViewController presentViewController:navCon animated:NO completion:nil];

    if (SYSTEM_RUNS_IOS8_OR_LATER) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingPasscodeAllowTouchID]) {
            [self _touchIDQuery];
        }
    }
}

- (void)_touchIDQuery
{
    /* don't launch multiple times */
    if (_inTouchID)
        return;
    _inTouchID = YES;
    LAContext *myContext = [[LAContext alloc] init];
    if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil]) {
        [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                  localizedReason:NSLocalizedString(@"TOUCHID_UNLOCK", nil)
                            reply:^(BOOL success, NSError *error) {
                                if (success) {
                                    [self PAPasscodeViewControllerDidEnterPasscode:nil];
                                } else if (error.code == LAErrorSystemCancel)
                                    _inTouchID = NO;
                            }];
    }
}

- (void)PAPasscodeViewControllerDidEnterPasscode:(PAPasscodeViewController *)controller
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(PAPasscodeViewControllerDidEnterPasscode:) withObject:controller waitUntilDone:NO];
        return;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPasscodeValidated object:self];

    VLCAppDelegate *appDelegate = (VLCAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    _inValidation = NO;
    _inTouchID = NO;
}

- (void)PAPasscodeViewController:(PAPasscodeViewController *)controller didFailToEnterPasscode:(NSInteger)attempts
{
    // FIXME: handle countless failed passcode attempts
}

- (void)setPasscode:(NSString *)passcode
{
    if (!passcode) {
        [SSKeychain deletePasswordForService:VLCPasscode account:VLCPasscode];
        return;
    }

    [SSKeychain setPassword:passcode forService:VLCPasscode account:VLCPasscode];
}

@end
