//
//  XKKeychainGenericPasswordItem.h
//  XKKeychain
//
//  Created by Karl von Randow on 22/10/14.
//  Copyright (c) 2014 XK72. All rights reserved.
//

#import "XKKeychainItem.h"

#import "XKKeychainDataAttribute.h"

@interface XKKeychainGenericPasswordItem : XKKeychainItem

+ (instancetype)itemForService:(NSString *)service account:(NSString *)account error:(NSError **)error;
+ (NSArray *)itemsForService:(NSString *)service error:(NSError **)error;
+ (NSArray *)itemsForService:(NSString *)service accountPrefix:(NSString *)accountPrefix error:(NSError **)error;

+ (BOOL)removeItemsForService:(NSString *)service error:(NSError **)error;
+ (BOOL)removeItemsForService:(NSString *)service accountPrefix:(NSString *)accountPrefix error:(NSError **)error;

@property (readonly, strong, nonatomic) NSDate *creationDate;
@property (readonly, strong, nonatomic) NSDate *modificationDate;
@property (strong, nonatomic) NSString *descriptionText;
@property (strong, nonatomic) NSString *comment;
@property (strong, nonatomic) NSNumber *creator;
@property (strong, nonatomic) NSNumber *type;
@property (strong, nonatomic) NSString *label;
@property (strong, nonatomic) NSNumber *invisible;
@property (strong, nonatomic) NSNumber *negative;
@property (strong, nonatomic) NSString *account;
@property (strong, nonatomic) NSString *service;

@property (readonly, strong, nonatomic) XKKeychainDataAttribute *generic;
@property (readonly, strong, nonatomic) XKKeychainDataAttribute *secret;

@end
