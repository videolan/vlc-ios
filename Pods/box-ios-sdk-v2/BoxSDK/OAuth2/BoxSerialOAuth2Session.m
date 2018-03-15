//
//  BoxSerialOAuth2Session.m
//  BoxSDK
//
//  Created on 2/20/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxSerialOAuth2Session.h"
#import "BoxAPIOAuth2ToJSONOperation.h"
#import "BoxLog.h"
#import "BoxSDKConstants.h"

@implementation BoxSerialOAuth2Session

#pragma mark - Authorization

#pragma mark - Token Refresh
- (void)performRefreshTokenGrant:(NSString *)expiredAccessToken;
{
    NSDictionary *POSTParams = @{
        BoxOAuth2TokenRequestGrantTypeKey : BoxOAuth2TokenRequestGrantTypeRefreshToken,
        BoxOAuth2TokenRequestRefreshTokenKey : self.refreshToken,
        BoxOAuth2TokenRequestClientIDKey : self.clientID,
        BoxOAuth2TokenRequestClientSecretKey : self.clientSecret,
    };

    BoxAPIOAuth2ToJSONOperation *operation = [[BoxAPIOAuth2ToJSONOperation alloc] initWithURL:self.grantTokensURL
                                                                                   HTTPMethod:BoxAPIHTTPMethodPOST
                                                                                         body:POSTParams
                                                                                  queryParams:nil
                                                                                OAuth2Session:self];

    operation.success = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSONDictionary)
    {
        self.accessToken = [JSONDictionary valueForKey:BoxOAuth2TokenJSONAccessTokenKey];
        self.refreshToken = [JSONDictionary valueForKey:BoxOAuth2TokenJSONRefreshTokenKey];

        NSTimeInterval accessTokenExpiresIn = [[JSONDictionary valueForKey:BoxOAuth2TokenJSONExpiresInKey] integerValue];
        BOXAssert(accessTokenExpiresIn >= 0, @"accessTokenExpiresIn value is negative");
        self.accessTokenExpiration = [NSDate dateWithTimeIntervalSinceNow:accessTokenExpiresIn];

        // send success notification
        [[NSNotificationCenter defaultCenter] postNotificationName:BoxOAuth2SessionDidRefreshTokensNotification object:self];
    };

    operation.failure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSDictionary *JSONDictionary)
    {
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:error
                                                              forKey:BoxOAuth2AuthenticationErrorKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:BoxOAuth2SessionDidReceiveRefreshErrorNotification
                                                            object:self
                                                          userInfo:errorInfo];
    };
    
    [self.queueManager enqueueOperation:operation];
}

@end
