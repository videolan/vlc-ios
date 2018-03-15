//
//  BoxUsersRequestBuilder.m
//  BoxSDK
//
//  Created on 8/15/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxUsersRequestBuilder.h"

#import "BoxSDKConstants.h"

@implementation BoxUsersRequestBuilder

@synthesize login = _login;
@synthesize name = _name;
@synthesize role = _role;
@synthesize language = _language;
@synthesize isSyncEnabled = _isSyncEnabled;
@synthesize jobTitle = _jobTitle;
@synthesize phone = _phone;
@synthesize address = _address;
@synthesize spaceAmount = _spaceAmount;
@synthesize trackingCodes = _trackingCodes;
@synthesize canSeeManagedUsers = _canSeeManagedUsers;
@synthesize status = _status;
@synthesize isExemptFromDeviceLimits = _isExemptFromDeviceLimits;
@synthesize isExemptFromLoginVerification = _isExemptFromLoginVerification;
@synthesize isPasswordResetRequired = _isPasswordResetRequired;

- (id)init
{
    self = [self initWithQueryStringParameters:nil];
    
    return self;
}

- (id)initWithQueryStringParameters:(NSDictionary *)queryStringParameters
{
    self = [super initWithQueryStringParameters:queryStringParameters];
    if (self != nil)
    {
        _login = nil;
        _name = nil;
        _role = nil;
        _language = nil;
        _isSyncEnabled = nil;
        _jobTitle = nil;
        _phone = nil;
        _address = nil;
        _spaceAmount = nil;
        _trackingCodes = nil;
        _canSeeManagedUsers = nil;
        _status = nil;
        _isExemptFromDeviceLimits = nil;
        _isExemptFromLoginVerification = nil;
        _isPasswordResetRequired = nil;
    }
    
    return self;
}

- (NSDictionary *)bodyParameters
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [self setObjectIfNotNil:self.login forKey:BoxAPIObjectKeyLogin inDictionary:dictionary];
    [self setObjectIfNotNil:self.name forKey:BoxAPIObjectKeyName inDictionary:dictionary];
    [self setObjectIfNotNil:self.role forKey:BoxAPIObjectKeyRole inDictionary:dictionary];
    [self setObjectIfNotNil:self.language forKey:BoxAPIObjectKeyLanguage inDictionary:dictionary];
    [self setObjectIfNotNil:self.isSyncEnabled forKey:BoxAPIObjectKeyIsSyncEnabled inDictionary:dictionary];
    [self setObjectIfNotNil:self.jobTitle forKey:BoxAPIObjectKeyJobTitle inDictionary:dictionary];
    [self setObjectIfNotNil:self.phone forKey:BoxAPIObjectKeyPhone inDictionary:dictionary];
    [self setObjectIfNotNil:self.address forKey:BoxAPIObjectKeyAddress inDictionary:dictionary];
    [self setObjectIfNotNil:self.spaceAmount forKey:BoxAPIObjectKeySpaceAmount inDictionary:dictionary];
    [self setObjectIfNotNil:self.trackingCodes forKey:BoxAPIObjectKeyTrackingCodes inDictionary:dictionary];
    [self setObjectIfNotNil:self.canSeeManagedUsers forKey:BoxAPIObjectKeyCanSeeManagedUsers inDictionary:dictionary];
    [self setObjectIfNotNil:self.status forKey:BoxAPIObjectKeyStatus inDictionary:dictionary];
    [self setObjectIfNotNil:self.isExemptFromDeviceLimits forKey:BoxAPIObjectKeyIsExemptFromDeviceLimits inDictionary:dictionary];
    [self setObjectIfNotNil:self.isExemptFromLoginVerification forKey:BoxAPIObjectKeyIsExemptFromLoginVerification inDictionary:dictionary];
    [self setObjectIfNotNil:self.isPasswordResetRequired forKey:BoxAPIObjectKeyIsPasswordResetRequired inDictionary:dictionary];
    
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

@end
