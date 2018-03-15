//
//  BoxParallelOAuth2Session.m
//  BoxSDK
//
//  Created on 5/11/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxParallelOAuth2Session.h"
#import "BoxAPIOAuth2ToJSONOperation.h"
#import "BoxLog.h"
#import "BoxSDKConstants.h"

@interface BoxParallelOAuth2Session ()

@property (atomic, readwrite, strong) NSMutableSet *expiredOAuth2Tokens;

@end

@implementation BoxParallelOAuth2Session

@synthesize expiredOAuth2Tokens = _expiredOAuth2Tokens;

- (id)initWithClientID:(NSString *)ID secret:(NSString *)secret APIBaseURL:(NSString *)baseURL queueManager:(BoxAPIQueueManager *)queueManager
{
    self = [super initWithClientID:ID secret:secret APIBaseURL:baseURL queueManager:queueManager];
    if (self != nil)
    {
        _expiredOAuth2Tokens = [NSMutableSet set];
    }
    
    return self;
}

- (void)performRefreshTokenGrant:(NSString *)expiredAccessToken;
{
    @synchronized(self)
    {
        if ([self.expiredOAuth2Tokens containsObject:expiredAccessToken])
        {
            // Only attempt to refresh the token if this is the first time this access
            // token has expired
            return;
        }
        
        BOXLog(@"access token expired: %@", expiredAccessToken);
        BOXLog(@"refreshing tokens");
        if (expiredAccessToken)
        {
            [self.expiredOAuth2Tokens addObject:expiredAccessToken];
        }
        
        NSDictionary *POSTParams = @{
        BoxOAuth2TokenRequestGrantTypeKey : BoxOAuth2TokenRequestGrantTypeRefreshToken,
        BoxOAuth2TokenRequestRefreshTokenKey : (!self.refreshToken) ?   @"invalidToken" : self.refreshToken,
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
}


@end
