//
//  BoxOAuth2Session.m
//  BoxSDK
//
//  Created on 2/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxOAuth2Session.h"
#import "BoxLog.h"
#import "BoxSDKConstants.h"
#import "BoxAPIOAuth2ToJSONOperation.h"
#import "NSString+BoxURLHelper.h"
#import "NSURL+BoxURLHelper.h"

NSString *const BoxOAuth2SessionDidBecomeAuthenticatedNotification = @"BoxOAuth2SessionDidBecomeAuthenticated";
NSString *const BoxOAuth2SessionDidReceiveAuthenticationErrorNotification = @"BoxOAuth2SessionDidReceiveAuthenticationError";
NSString *const BoxOAuth2SessionDidRefreshTokensNotification = @"BoxOAuth2SessionDidRefreshTokens";
NSString *const BoxOAuth2SessionDidReceiveRefreshErrorNotification = @"BoxOAuth2SessionDidReceiveRefreshError";

NSString *const BoxOAuth2AuthenticationErrorKey = @"BoxOAuth2AuthenticationError";

@implementation BoxOAuth2Session

@synthesize APIBaseURLString = _APIBaseURLString;
@synthesize clientID = _clientID;
@synthesize clientSecret = _clientSecret;
@synthesize accessToken = _accessToken;
@synthesize refreshToken = _refreshToken;
@synthesize accessTokenExpiration = _accessTokenExpiration;
@synthesize queueManager = _queueManager;

#pragma mark - Initialization
- (id)initWithClientID:(NSString *)ID secret:(NSString *)secret APIBaseURL:(NSString *)baseURL queueManager:(BoxAPIQueueManager *)queueManager
{
    self = [super init];
    if (self != nil)
    {
        _clientID = ID;
        _clientSecret = secret;
        _APIBaseURLString = baseURL;
        _queueManager = queueManager;
    }
    return self;
}

#pragma mark - Authorization
- (void)performAuthorizationCodeGrantWithReceivedURL:(NSURL *)URL
{
    NSDictionary *URLQueryParams = [URL box_queryDictionary];
    NSString *authorizationCode = [URLQueryParams valueForKey:BoxOAuth2URLParameterAuthorizationCodeKey];
    NSString *authorizationError = [URLQueryParams valueForKey:BoxOAuth2URLParameterErrorCodeKey];

    if (authorizationError != nil)
    {
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:authorizationError
                                                              forKey:BoxOAuth2AuthenticationErrorKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:BoxOAuth2SessionDidReceiveAuthenticationErrorNotification
                                                            object:self
                                                          userInfo:errorInfo];
        return;
    }


    NSDictionary *POSTParams = @{
                                 BoxOAuth2TokenRequestGrantTypeKey : BoxOAuth2TokenRequestGrantTypeAuthorizationCode,
                                 BoxOAuth2TokenRequestAuthorizationCodeKey : authorizationCode,
                                 BoxOAuth2TokenRequestClientIDKey : self.clientID,
                                 BoxOAuth2TokenRequestClientSecretKey : self.clientSecret,
                                 BoxOAuth2TokenRequestRedirectURIKey : self.redirectURIString,
                                 };

    BoxAPIOAuth2ToJSONOperation *operation = [[BoxAPIOAuth2ToJSONOperation alloc] initWithURL:[self grantTokensURL]
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
        [[NSNotificationCenter defaultCenter] postNotificationName:BoxOAuth2SessionDidBecomeAuthenticatedNotification object:self];
    };

    operation.failure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSDictionary *JSONDictionary)
    {
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:error
                                                              forKey:BoxOAuth2AuthenticationErrorKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:BoxOAuth2SessionDidReceiveAuthenticationErrorNotification
                                                            object:self
                                                          userInfo:errorInfo];
    };

    [self.queueManager enqueueOperation:operation];
}

- (NSURL *)authorizeURL
{
    NSString *encodedRedirectURI = [NSString box_stringWithString:self.redirectURIString URLEncoded:YES];
    NSString *authorizeURLString = [NSString stringWithFormat:
                                    @"%@/oauth2/authorize?response_type=code&client_id=%@&state=ok&redirect_uri=%@",
                                    self.APIBaseURLString, self.clientID, encodedRedirectURI];
    return [NSURL URLWithString:authorizeURLString];
}

- (NSURL *)grantTokensURL
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth2/token", self.APIBaseURLString]];
}

- (NSString *)redirectURIString
{
    return [NSString stringWithFormat:@"boxsdk-%@://boxsdkoauth2redirect", self.clientID];
}

#pragma mark - Token Refresh
- (void)performRefreshTokenGrant:(NSString *)expiredAccessToken
{
    BOXAbstract();
}

#pragma mark - Logout
- (void)logout
{
    NSURL *revokeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth2/revoke", self.APIBaseURLString]];
    NSDictionary *POSTParams = @{
                                 BoxOAuth2TokenRequestClientIDKey : self.clientID,
                                 BoxOAuth2TokenRequestClientSecretKey : self.clientSecret,
                                 BoxOAuth2LogoutTokenKey : self.refreshToken
                                 };

    BoxAPIOAuth2ToJSONOperation *operation = [[BoxAPIOAuth2ToJSONOperation alloc] initWithURL:revokeURL
                                                                                   HTTPMethod:BoxAPIHTTPMethodPOST
                                                                                         body:POSTParams
                                                                                  queryParams:nil
                                                                                OAuth2Session:self];
    _accessToken = @"INVALID_TOKEN";
    _refreshToken = @"INVALID_TOKEN";
    self.accessTokenExpiration = nil;

    [self.queueManager enqueueOperation:operation];
}

#pragma mark - Session info
- (BOOL)isAuthorized
{
    NSDate *now = [NSDate date];
    return [self.accessTokenExpiration timeIntervalSinceDate:now] > 0;
}

#pragma mark - Request Authorization
- (void)addAuthorizationParametersToRequest:(NSMutableURLRequest *)request
{
    NSString *bearerToken = [NSString stringWithFormat:@"Bearer %@", self.accessToken];
    [request addValue:bearerToken forHTTPHeaderField:BoxAPIHTTPHeaderAuthorization];
}

@end
