//
//  BoxCommentsRequestBuilder.m
//  BoxSDK
//
//  Created on 11/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxCommentsRequestBuilder.h"
#import "BoxModelBuilder.h"
#import "BoxSDKConstants.h"

@implementation BoxCommentsRequestBuilder

@synthesize item = _item;
@synthesize message = _message;

- (id)init
{
    self = [super init];
    
    return self;
}

- (NSDictionary *)bodyParameters
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
    
    if (self.item != nil)
    {
        [dictionary setObject:[self.item bodyParameters] forKey:BoxAPIObjectKeyItem];
    }
    
    if (self.message != nil)
    {
        [dictionary setObject:self.message forKey:BoxAPIObjectKeyMessage];
    }
    
    return dictionary;
}

@end
