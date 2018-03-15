//
//  BoxUser.m
//  BoxSDK
//
//  Created on 3/14/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxUser.h"

#import "BoxCollection.h"
#import "BoxLog.h"
#import "BoxSDKConstants.h"

@implementation BoxUser

- (NSString *)name
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyName
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}

- (NSString *)login
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyLogin
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}

- (NSDate *)createdAt
{
    NSString *timestamp = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyCreatedAt
                                                     inDictionary:self.rawResponseJSON
                                                  hasExpectedType:[NSString class]
                                                      nullAllowed:NO];
    return [self dateWithISO8601String:timestamp];
}

- (NSDate *)modifiedAt
{
    NSString *timestamp = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyModifiedAt
                                                     inDictionary:self.rawResponseJSON
                                                  hasExpectedType:[NSString class]
                                                      nullAllowed:NO];
    return [self dateWithISO8601String:timestamp];
}

- (NSString *)role
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyRole
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}

- (NSString *)language
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyLanguage
                                                     inDictionary:self.rawResponseJSON
                                                  hasExpectedType:[NSString class]
                                                      nullAllowed:NO];
}

- (NSNumber *)spaceAmount
{
    NSNumber *spaceAmount = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeySpaceAmount
                                                       inDictionary:self.rawResponseJSON
                                                    hasExpectedType:[NSNumber class]
                                                        nullAllowed:NO];
    if (spaceAmount != nil)
    {
        spaceAmount = [NSNumber numberWithDouble:[spaceAmount doubleValue]];
    }
    return spaceAmount;
}

- (NSNumber *)spaceUsed
{
    NSNumber *spaceUsed = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeySpaceUsed
                                                     inDictionary:self.rawResponseJSON
                                                  hasExpectedType:[NSNumber class]
                                                      nullAllowed:NO];
    if (spaceUsed != nil)
    {
        spaceUsed = [NSNumber numberWithDouble:[spaceUsed doubleValue]];
    }
    return spaceUsed;
}

- (NSNumber *)maxUploadSize
{
    NSNumber *maxUploadSize = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyMaxUploadSize
                                                         inDictionary:self.rawResponseJSON
                                                      hasExpectedType:[NSNumber class]
                                                          nullAllowed:NO];
    if (maxUploadSize != nil)
    {
        maxUploadSize = [NSNumber numberWithDouble:[maxUploadSize doubleValue]];
    }
    return maxUploadSize;
}

- (id)trackingCodes
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyTrackingCodes
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSDictionary class]
                                       nullAllowed:NO];
}

- (NSNumber *)canSeeManagedUsers
{
    NSNumber *canSeeManagedUsers = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyCanSeeManagedUsers
                                                              inDictionary:self.rawResponseJSON
                                                           hasExpectedType:[NSNumber class]
                                                               nullAllowed:NO];
    if (canSeeManagedUsers != nil)
    {
        canSeeManagedUsers = [NSNumber numberWithBool:[canSeeManagedUsers boolValue]];
    }
    return canSeeManagedUsers;
}

- (NSNumber *) isSyncEnabled
{
    NSNumber *isSyncEnabled = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyIsSyncEnabled
                                                         inDictionary:self.rawResponseJSON
                                                      hasExpectedType:[NSNumber class]
                                                          nullAllowed:NO];
    if (isSyncEnabled != nil)
    {
        isSyncEnabled = [NSNumber numberWithBool:[isSyncEnabled boolValue]];
    }
    return isSyncEnabled;
}

- (NSString *) status
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyStatus
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}

- (NSString *) jobTitle
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyJobTitle
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}

- (NSString *)phone
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyPhone
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}

- (NSString *)address
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyAddress
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}

- (NSURL *)avatarURL
{
    NSString *avatarURLStr = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyAvatarURL
                                                     inDictionary:self.rawResponseJSON
                                                  hasExpectedType:[NSString class]
                                                      nullAllowed:NO];
    NSURL *avatarURL = nil;
    
    if (avatarURLStr != nil)
    {
        avatarURL = [NSURL URLWithString:avatarURLStr];
    }
    
    return avatarURL;
}

- (NSNumber *)isExemptFromDeviceLimits
{
    NSNumber *isExemptFromDeviceLimits = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyIsExemptFromDeviceLimits
                                                                    inDictionary:self.rawResponseJSON
                                                                 hasExpectedType:[NSNumber class]
                                                                     nullAllowed:NO];
    if (isExemptFromDeviceLimits != nil)
    {
        isExemptFromDeviceLimits = [NSNumber numberWithBool:[isExemptFromDeviceLimits boolValue]];
    }
    return isExemptFromDeviceLimits;
}

- (NSNumber *)isExemptFromLoginVerification
{
    NSNumber *isExemptFromLoginVerification = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyIsExemptFromLoginVerification
                                                                         inDictionary:self.rawResponseJSON
                                                                      hasExpectedType:[NSNumber class]
                                                                          nullAllowed:NO];
    if (isExemptFromLoginVerification != nil)
    {
        isExemptFromLoginVerification = [NSNumber numberWithBool:[isExemptFromLoginVerification boolValue]];
    }
    return isExemptFromLoginVerification;
}

- (NSNumber *)isDeactivated
{
    NSNumber *isDeactivated = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyIsDeactivated
                                                         inDictionary:self.rawResponseJSON
                                                      hasExpectedType:[NSNumber class]
                                                          nullAllowed:NO];
    if (isDeactivated != nil)
    {
        isDeactivated = [NSNumber numberWithBool:[isDeactivated boolValue]];
    }
    return isDeactivated;
}

- (NSNumber *)isPasswordResetRequired
{
    NSNumber *isPasswordResetRequired = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyIsPasswordResetRequired
                                                                   inDictionary:self.rawResponseJSON
                                                                hasExpectedType:[NSNumber class]
                                                                    nullAllowed:NO];
    if (isPasswordResetRequired != nil)
    {
        isPasswordResetRequired = [NSNumber numberWithBool:[isPasswordResetRequired boolValue]];
    }
    return isPasswordResetRequired;
}

- (NSString *)deactivatedReason
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyRole
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}

- (NSNumber *)hasCustomAvatar
{
    NSNumber *hasCustomAvatar = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyIsPasswordResetRequired
                                                           inDictionary:self.rawResponseJSON
                                                        hasExpectedType:[NSNumber class]
                                                            nullAllowed:NO];
    if (hasCustomAvatar != nil)
    {
        hasCustomAvatar = [NSNumber numberWithBool:[hasCustomAvatar boolValue]];
    }
    return hasCustomAvatar;
}

@end
