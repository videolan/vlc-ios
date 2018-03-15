//
//  BoxFile.m
//  BoxSDK
//
//  Created on 3/14/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxFile.h"

#import "BoxLog.h"
#import "BoxSDKConstants.h"

@implementation BoxFile

- (NSString *)SHA1
{
    return [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeySHA1
                                      inDictionary:self.rawResponseJSON
                                   hasExpectedType:[NSString class]
                                       nullAllowed:NO];
}

- (NSNumber *)commentCount
{
    NSNumber *commentCount = [NSJSONSerialization box_ensureObjectForKey:BoxAPIObjectKeyCommentCount
                                                        inDictionary:self.rawResponseJSON
                                                     hasExpectedType:[NSNumber class]
                                                         nullAllowed:NO];
    if (commentCount != nil)
    {
        commentCount = [NSNumber numberWithInteger:[commentCount intValue]];
    }
    return commentCount;
}

@end
