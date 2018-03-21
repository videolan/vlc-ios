//
//  BoxWebLink.m
//  BoxSDK
//
//  Created on 4/22/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxWebLink.h"
#import "BoxSDKConstants.h"
#import "BoxLog.h"

@implementation BoxWebLink

- (NSURL *)URL
{
    id URL = [self.rawResponseJSON objectForKey:BoxAPIObjectKeyURL];
    if (URL == nil)
    {
        return nil;
    }
    else if (![URL isKindOfClass:[NSString class]])
    {
        BOXAssertFail(@"URL should be a string");
        return nil;
    }
    return [NSURL URLWithString:(NSString *)URL];
}

@end
