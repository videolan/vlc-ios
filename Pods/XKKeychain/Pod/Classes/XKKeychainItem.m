//
//  XKKeychainItem.m
//  XKKeychain
//
//  Created by Karl von Randow on 22/10/14.
//  Copyright (c) 2014 XK72. All rights reserved.
//

#import "XKKeychainItem.h"

@implementation XKKeychainItem

- (void)dealloc
{
    if (_accessible) {
        CFRelease(_accessible);
    }
}

#pragma mark - Properties

- (void)setAccessible:(CFTypeRef)accessible
{
    if (accessible != _accessible) {
        if (_accessible != NULL) {
            CFRelease(_accessible);
        }
        _accessible = CFRetain(accessible);
    }
}

#pragma mark - Public

- (BOOL)saveWithError:(NSError **)error
{
    return NO;
}

- (BOOL)deleteWithError:(NSError **)error
{
    return NO;
}

@end
