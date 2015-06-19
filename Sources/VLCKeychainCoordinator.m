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

NSString *const VLCPasscodeValidated = @"VLCPasscodeValidated";

NSString *const VLCPasscode = @"org.videolan.vlc-ios.passcode";

@interface VLCKeychainCoordinator () <PAPasscodeViewControllerDelegate>
{
    PAPasscodeViewController *_passcodeLockController;
    NSDictionary *_passcodeQuery;
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

- (NSString *)_obtainPasscode
{
    NSString *passcode = [SSKeychain passwordForService:VLCPasscode account:VLCPasscode];

    if (!passcode) {
        /* legacy passcode retrieval */
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        passcode = [defaults objectForKey:kVLCSettingPasscodeKey];
        if (passcode)
            [self setPasscode:passcode];
    }

    return passcode;
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
    NSString *passcode = [self _obtainPasscode];
    if ([passcode isEqualToString:@""]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPasscodeValidated object:self];
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
}


- (void)PAPasscodeViewControllerDidEnterPasscode:(PAPasscodeViewController *)controller
{
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPasscodeValidated object:self];

    VLCAppDelegate *appDelegate = (VLCAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
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
