//
//  XKKeychainItem.h
//  XKKeychain
//
//  Created by Karl von Randow on 22/10/14.
//  Copyright (c) 2014 XK72. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XKKeychainItem : NSObject

@property (nonatomic) CFTypeRef accessible;
@property (strong, nonatomic) NSString *accessGroup;

- (BOOL)saveWithError:(NSError **)error;
- (BOOL)deleteWithError:(NSError **)error;

@end
