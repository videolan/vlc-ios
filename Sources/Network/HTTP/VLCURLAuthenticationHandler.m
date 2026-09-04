/*****************************************************************************
 * VLCURLAuthenticationHandler.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCURLAuthenticationHandler.h"
#import "UIApplication+VLCTopViewController.h"

@implementation VLCURLAuthenticationHandler

- (void)handleChallenge:(NSURLAuthenticationChallenge *)challenge
                 forURL:(NSURL *)url
      completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    NSString *authenticationMethod = challenge.protectionSpace.authenticationMethod;
    if (![authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]
        && ![authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest]
        && ![authenticationMethod isEqualToString:NSURLAuthenticationMethodNTLM]) {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }

    if (challenge.previousFailureCount == 0) {
        NSURLCredential *credential = [self credentialFromURL:url];
        if (!credential) {
            NSURLCredential *proposedCredential = challenge.proposedCredential;
            if (proposedCredential.user && proposedCredential.password) {
                credential = proposedCredential;
            }
        }
        if (credential) {
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            return;
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentPromptForChallenge:challenge completionHandler:completionHandler];
    });
}

- (NSURLCredential *)credentialFromURL:(NSURL *)url
{
    NSString *user = url.user;
    NSString *password = url.password;
    if (user.length == 0 || !password) {
        return nil;
    }
    return [NSURLCredential credentialWithUser:user
                                      password:password
                                   persistence:NSURLCredentialPersistenceNone];
}

- (void)presentPromptForChallenge:(NSURLAuthenticationChallenge *)challenge
                completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    UIViewController *presentingViewController = [UIApplication sharedApplication].topViewController;
    if (!presentingViewController) {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        return;
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"NETWORK_AUTH_TITLE", nil)
                                                                            message:[self messageForChallenge:challenge]
                                                                     preferredStyle:UIAlertControllerStyleAlert];

    __block UITextField *usernameField;
    __block UITextField *passwordField;
    NSString *proposedUsername = challenge.proposedCredential.user;

    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        usernameField = textField;
        textField.textContentType = UITextContentTypeUsername;
        textField.placeholder = NSLocalizedString(@"USER_LABEL", nil);
        textField.text = proposedUsername;
    }];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        passwordField = textField;
        textField.textContentType = UITextContentTypePassword;
        textField.secureTextEntry = YES;
        textField.placeholder = NSLocalizedString(@"PASSWORD_LABEL", nil);
    }];

    UIAlertAction *loginAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"LOGIN", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
        NSURLCredential *credential = [NSURLCredential credentialWithUser:usernameField.text ?: @""
                                                                 password:passwordField.text ?: @""
                                                              persistence:NSURLCredentialPersistenceForSession];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }];
    [alertController addAction:loginAction];
    alertController.preferredAction = loginAction;

    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }]];

    [presentingViewController presentViewController:alertController animated:YES completion:nil];
}

- (NSString *)messageForChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSURLProtectionSpace *protectionSpace = challenge.protectionSpace;
    NSString *realm = protectionSpace.realm;
    NSString *message;

    if (realm.length > 0) {
        message = [NSString stringWithFormat:NSLocalizedString(@"NETWORK_AUTH_MESSAGE_REALM", nil),
                   protectionSpace.host, realm];
    } else {
        message = [NSString stringWithFormat:NSLocalizedString(@"NETWORK_AUTH_MESSAGE", nil),
                   protectionSpace.host];
    }

    if (challenge.previousFailureCount > 0) {
        message = [NSString stringWithFormat:@"%@\n%@",
                   NSLocalizedString(@"NETWORK_AUTH_WRONG_CREDENTIALS", nil), message];
    }

    return message;
}

@end
