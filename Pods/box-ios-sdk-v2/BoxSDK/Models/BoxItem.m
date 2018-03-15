//
//  BoxItem.m
//  BoxSDK
//
//  Created on 3/22/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxItem.h"

#import "BoxCollection.h"
#import "BoxFolder.h"
#import "BoxUser.h"

#import "BoxLog.h"
#import "BoxSDKConstants.h"

@implementation BoxItem

- (NSString *)sequenceID
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeySequenceID
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:YES // root folders have no sequence id
                                 suppressNullAsNil:YES];
}

- (NSString *)ETag
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyETag
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:YES // root folders have no ETags
                                 suppressNullAsNil:YES];
}

- (NSString *)name
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyName
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}

- (NSDate *)createdAt
{
    NSString *timestamp = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyCreatedAt
                                                     inDictionary:self.rawResponseJSON
                                                  hasExpectedType:[NSString class]
                                                      nullAllowed:YES // root folders have no timestamps
                                                suppressNullAsNil:YES];
    return [self dateWithISO8601String:timestamp];
}

- (NSDate *)modifiedAt
{
    NSString *timestamp = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyModifiedAt
                                                     inDictionary:self.rawResponseJSON
                                                  hasExpectedType:[NSString class]
                                                      nullAllowed:YES // root folders have no timestamps
                                                suppressNullAsNil:YES];
    return [self dateWithISO8601String:timestamp];
}

- (NSDate *)contentCreatedAt
{
    NSString *timestamp = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyContentCreatedAt
                                                     inDictionary:self.rawResponseJSON
                                                  hasExpectedType:[NSString class]
                                                      nullAllowed:YES // root folders have no timestamps
                                                suppressNullAsNil:YES];
    return [self dateWithISO8601String:timestamp];
}

- (NSDate *)contentModifiedAt
{
    NSString *timestamp = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyContentModifiedAt
                                                     inDictionary:self.rawResponseJSON
                                                  hasExpectedType:[NSString class]
                                                      nullAllowed:YES // root folders have no timestamps
                                                suppressNullAsNil:YES];
    return [self dateWithISO8601String:timestamp];
}

- (NSDate *)trashedAt
{
    NSString *timestamp = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyTrashedAt
                                                     inDictionary:self.rawResponseJSON
                                                  hasExpectedType:[NSString class]
                                                      nullAllowed:YES // root folders have no timestamps
                                                suppressNullAsNil:YES];
    return [self dateWithISO8601String:timestamp];
}

- (NSDate *)purgedAt
{
    NSString *timestamp = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyPurgedAt
                                                     inDictionary:self.rawResponseJSON
                                                  hasExpectedType:[NSString class]
                                                      nullAllowed:YES // root folders have no timestamps
                                                suppressNullAsNil:YES];
    return [self dateWithISO8601String:timestamp];
}

- (NSString *)description
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyDescription
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}

- (NSNumber *)size
{
    NSNumber *size = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeySize
                                                inDictionary:self.rawResponseJSON
                                             hasExpectedType:[NSNumber class]
                                                 nullAllowed:NO];
    if (size != nil)
    {
        size = [NSNumber numberWithDouble:[size doubleValue]];
    }
    return size;
}

- (BoxCollection *)pathCollection
{
    NSDictionary *pathCollectionJSON = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyPathCollection
                                                                  inDictionary:self.rawResponseJSON
                                                               hasExpectedType:[NSDictionary class]
                                                                   nullAllowed:NO];

    BoxCollection *pathCollection = nil;
    if (pathCollectionJSON != nil)
    {
        pathCollection = [[BoxCollection alloc] initWithResponseJSON:pathCollectionJSON mini:YES];
    }
    return pathCollection;
}

- (BoxUser *)createdBy
{
    NSDictionary *userJSON = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyCreatedBy
                                                        inDictionary:self.rawResponseJSON
                                                     hasExpectedType:[NSDictionary class]
                                                         nullAllowed:NO];

    BoxUser *user = nil;
    if (userJSON != nil)
    {
        user = [[BoxUser alloc] initWithResponseJSON:userJSON mini:YES];
    }
    return user;
}

- (BoxUser *)modifiedBy
{
    NSDictionary *userJSON = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyModifiedBy
                                                        inDictionary:self.rawResponseJSON
                                                     hasExpectedType:[NSDictionary class]
                                                         nullAllowed:NO];

    BoxUser *user = nil;
    if (userJSON != nil)
    {
        user = [[BoxUser alloc] initWithResponseJSON:userJSON mini:YES];
    }
    return user;
}

- (BoxUser *)ownedBy
{
    NSDictionary *userJSON = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyOwnedBy
                                                        inDictionary:self.rawResponseJSON
                                                     hasExpectedType:[NSDictionary class]
                                                         nullAllowed:NO];

    BoxUser *user = nil;
    if (userJSON != nil)
    {
        user = [[BoxUser alloc] initWithResponseJSON:userJSON mini:YES];
    }
    return user;
}

- (id)sharedLink
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeySharedLink
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSDictionary class]
                                       nullAllowed:YES];
}

- (id)parent
{
    id parentJSON = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyParent
                                               inDictionary:self.rawResponseJSON
                                            hasExpectedType:[NSDictionary class]
                                                nullAllowed:YES];

    BoxFolder *parent = nil;
    if (parentJSON != nil)
    {
        if ([parentJSON isKindOfClass:[NSNull class]])
        {
            return [NSNull null];
        }
        else
        {
            NSDictionary *parentJSONDictionary = (NSDictionary *)parentJSON;
            parent = [[BoxFolder alloc] initWithResponseJSON:parentJSONDictionary mini:YES];
        }
    }
    return parent;
}

- (NSString *)itemStatus
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyItemStatus
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}


@end
