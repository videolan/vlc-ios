//
//  BoxModelBuilder.m
//  BoxSDK
//
//  Created on 11/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxModelBuilder.h"

#import "BoxLog.h"

@implementation BoxModelBuilder

@synthesize type = _type;
@synthesize modelID = _modelID;

- (id)init
{
    self = [super init];
    
    return self;
}

- (NSDictionary *)bodyParameters
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
    BOXAssert(self.modelID != nil, @"modelID is a required parameter for the model object");

    if (self.modelID != nil)
    {
        [dictionary setObject:self.modelID forKey:BoxAPIObjectKeyID];
    }
    
    if (self.type != nil)
    {
        [dictionary setObject:self.type forKey:BoxAPIObjectKeyType];
    }
    
    return dictionary;
}

@end
