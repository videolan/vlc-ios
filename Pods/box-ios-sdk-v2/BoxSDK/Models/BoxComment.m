//
//  BoxComment.m
//  BoxSDK
//
//  Created on 11/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxComment.h"
#import "BoxCommentableItem.h"
#import "BoxUser.h"
#import "BoxFile.h"
#import "BoxLog.h"
#import "BoxSDKConstants.h"

@implementation BoxComment

- (NSString *)message
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyMessage
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}

- (NSString *)taggedMessage
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyTaggedMessage
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
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

- (NSNumber *) isReplyComment
{
    NSNumber *isReplyComment = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyIsReplyComment
                                                              inDictionary:self.rawResponseJSON
                                                           hasExpectedType:[NSNumber class]
                                                               nullAllowed:NO];
    if (isReplyComment != nil)
    {
        isReplyComment = [NSNumber numberWithBool:[isReplyComment boolValue]];
    }
    return isReplyComment;
}

- (BoxModel<BoxCommentableItem> *) item
{
    NSDictionary *itemJSON = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyItem
                                                        inDictionary:self.rawResponseJSON
                                                     hasExpectedType:[NSDictionary class]
                                                         nullAllowed:NO];

    if (itemJSON != nil)
    {
        NSString *type = [itemJSON objectForKey:BoxAPIObjectKeyType];

        if ([type isEqualToString:BoxAPIItemTypeFile])
        {
            return [[BoxFile alloc] initWithResponseJSON:itemJSON mini:YES];
        }
        else if ([type isEqualToString:BoxAPIItemTypeComment])
        {
            return [[BoxComment alloc] initWithResponseJSON:itemJSON mini:YES];
        }
        else
        {
            BOXAssertFail(@"Unsupported type %@ returned for the item property of BoxComment", type);
        }
    }
    return nil;
}

@end
