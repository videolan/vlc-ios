//
//  XKKeychainGenericPasswordItem.m
//  XKKeychain
//
//  Created by Karl von Randow on 22/10/14.
//  Copyright (c) 2014 XK72. All rights reserved.
//

#import "XKKeychainGenericPasswordItem.h"

@implementation XKKeychainGenericPasswordItem {
    XKKeychainDataAttribute *_secret;
}

+ (instancetype)itemForService:(NSString *)service account:(NSString *)account error:(NSError **)error
{
    NSMutableDictionary *query = [XKKeychainGenericPasswordItem queryDictionaryForService:service account:account];
    
    [query setObject:(__bridge NSString *)kSecMatchLimitOne forKey:(__bridge NSString *)kSecMatchLimit];
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge NSString *)kSecReturnData];
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge NSString *)kSecReturnAttributes];
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess) {
        if (error) {
            *error = nil;
        }
        
        NSDictionary *attributes = (__bridge_transfer NSDictionary *)result;
        
        return [[XKKeychainGenericPasswordItem alloc] initWithAttributes:attributes];
    } else if (status == errSecItemNotFound) {
        if (error) {
            *error = nil;
        }
        return nil;
    } else {
        [XKKeychainGenericPasswordItem error:error forStatus:status];
        return nil;
    }
}

+ (NSArray *)itemsForService:(NSString *)service error:(NSError **)error
{
    NSMutableDictionary *query = [XKKeychainGenericPasswordItem queryDictionaryForService:service account:nil];
    
    [query setObject:(__bridge NSString *)kSecMatchLimitAll forKey:(__bridge NSString *)kSecMatchLimit];
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge NSString *)kSecReturnAttributes];
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess) {
        if (error) {
            *error = nil;
        }
        
        NSArray *results = (__bridge_transfer NSArray *)result;
        NSMutableArray *items = [NSMutableArray array];
        for (NSDictionary *attributes in results) {
            XKKeychainGenericPasswordItem *item = [[XKKeychainGenericPasswordItem alloc] initWithAttributes:attributes];
            [items addObject:item];
        }
        return items;
    } else if (status == errSecItemNotFound) {
        if (error) {
            *error = nil;
        }
        return [NSArray array];
    } else {
        [XKKeychainGenericPasswordItem error:error forStatus:status];
        return nil;
    }
}

+ (NSArray *)itemsForService:(NSString *)service accountPrefix:(NSString *)accountPrefix error:(NSError **)error
{
    NSArray *items = [XKKeychainGenericPasswordItem itemsForService:service error:error];
    if (!items) {
        return nil;
    }
    
    NSMutableArray *result = [NSMutableArray array];
    for (XKKeychainGenericPasswordItem *item in items) {
        if ([item.account hasPrefix:accountPrefix]) {
            [result addObject:item];
        }
    }
    return result;
}

+ (BOOL)removeItemsForService:(NSString *)service error:(NSError **)error
{
    NSMutableDictionary *query = [XKKeychainGenericPasswordItem queryDictionaryForService:service account:nil];
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status == errSecSuccess || status == errSecItemNotFound) {
        if (error) {
            *error = nil;
        }
        return YES;
    } else {
        [XKKeychainGenericPasswordItem error:error forStatus:status];
        return NO;
    }
}

+ (BOOL)removeItemsForService:(NSString *)service accountPrefix:(NSString *)accountPrefix error:(NSError **)error
{
    NSArray *items = [XKKeychainGenericPasswordItem itemsForService:service accountPrefix:accountPrefix error:error];
    if (!items) {
        return NO;
    }
    
    for (XKKeychainItem *item in items) {
        BOOL success = [item deleteWithError:error];
        if (!success) {
            return NO;
        }
    }
    return YES;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        _generic = [XKKeychainDataAttribute dataAttributeWithData:nil];
        _secret = [XKKeychainDataAttribute dataAttributeWithData:nil];
    }
    return self;
}

- (instancetype)initWithAttributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        self.accessible = (__bridge CFTypeRef)(attributes[(__bridge NSString *)kSecAttrAccessible]);
        self.accessGroup = attributes[(__bridge NSString *)kSecAttrAccessGroup];
        
        _creationDate = attributes[(__bridge NSString *)kSecAttrCreationDate];
        _modificationDate = attributes[(__bridge NSString *)kSecAttrModificationDate];
        _descriptionText = attributes[(__bridge NSString *)kSecAttrDescription];
        _comment = attributes[(__bridge NSString *)kSecAttrComment];
        _creator = attributes[(__bridge NSString *)kSecAttrCreator];
        _type = attributes[(__bridge NSString *)kSecAttrType];
        _label = attributes[(__bridge NSString *)kSecAttrLabel];
        _invisible = attributes[(__bridge NSString *)kSecAttrIsInvisible];
        _negative = attributes[(__bridge NSString *)kSecAttrIsNegative];
        _account = attributes[(__bridge NSString *)kSecAttrAccount];
        _service = attributes[(__bridge NSString *)kSecAttrService];
        _generic = [XKKeychainDataAttribute dataAttributeWithObject:attributes[(__bridge NSString *)kSecAttrGeneric]];
        
        NSData *secretData = attributes[(__bridge NSString *)kSecValueData];
        if (secretData) {
            _secret = [XKKeychainDataAttribute dataAttributeWithObject:secretData];
        }
    }
    return self;
}

#pragma mark - Utilities

+ (NSMutableDictionary *)queryDictionaryForService:(NSString *)service account:(NSString *)account
{
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    [query setObject:(__bridge NSString *)kSecClassGenericPassword forKey:(__bridge NSString *)kSecClass];
    [query setObject:service forKey:(__bridge NSString *)kSecAttrService];
    if (account) {
        [query setObject:account forKey:(__bridge NSString *)kSecAttrAccount];
    }
    return query;
}

+ (BOOL)error:(NSError **)error forStatus:(OSStatus)status
{
    if (error) {
        if (status == errSecSuccess) {
            *error = nil;
        } else {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Keychain error #%i", (int)status]};
            *error = [NSError errorWithDomain:@"XKKeychain" code:status userInfo:userInfo];
        }
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Public

- (BOOL)saveWithError:(NSError **)error
{
    [self deleteWithError:nil];
    
    NSDictionary *saveDictionary = [self saveDictionary];
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)saveDictionary, NULL);
    if (status == errSecSuccess) {
        if (error) {
            *error = nil;
        }
        return YES;
    } else {
        [XKKeychainGenericPasswordItem error:error forStatus:status];
        return NO;
    }
}

- (BOOL)deleteWithError:(NSError **)error
{
    NSMutableDictionary *query = [XKKeychainGenericPasswordItem queryDictionaryForService:self.service account:self.account];
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status == errSecSuccess || status == errSecItemNotFound) {
        if (error) {
            *error = nil;
        }
        return YES;
    } else {
        [XKKeychainGenericPasswordItem error:error forStatus:status];
        return NO;
    }
}

- (NSData *)secretDataWithError:(NSError **)error
{
    NSMutableDictionary *query = [XKKeychainGenericPasswordItem queryDictionaryForService:self.service account:self.account];
    
    [query setObject:(__bridge NSString *)kSecMatchLimitOne forKey:(__bridge NSString *)kSecMatchLimit];
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge NSString *)kSecReturnData];
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess) {
        if (error) {
            *error = nil;
        }
        
        return (__bridge_transfer NSData *)result;
    } else if (status == errSecItemNotFound) {
        if (error) {
            *error = nil;
        }
        return nil;
    } else {
        [XKKeychainGenericPasswordItem error:error forStatus:status];
        return nil;
    }
}

#pragma mark - Properties

- (XKKeychainDataAttribute *)secret
{
    if (_secret) {
        return _secret;
    }
    
    NSData *data = [self secretDataWithError:nil];
    if (data) {
        XKKeychainDataAttribute *secret = [XKKeychainDataAttribute dataAttributeWithData:data];
        _secret = secret;
        return secret;
    } else {
        XKKeychainDataAttribute *secret = [XKKeychainDataAttribute dataAttributeWithData:nil];
        _secret = secret;
        return secret;
    }
}

#pragma mark - Private

- (NSDictionary *)saveDictionary
{
    NSMutableDictionary *result = [XKKeychainGenericPasswordItem queryDictionaryForService:self.service account:self.account];
    if (self.accessible) {
        [result setObject:self.accessible forKey:(__bridge NSString *)kSecAttrAccessible];
    }
    if (self.accessGroup) {
        [result setObject:self.accessGroup forKey:(__bridge NSString *)kSecAttrAccessGroup];
    }
    if (_descriptionText) {
        [result setObject:_descriptionText forKey:(__bridge NSString *)kSecAttrDescription];
    }
    if (_comment) {
        [result setObject:_comment forKey:(__bridge NSString *)kSecAttrComment];
    }
    if (_creator) {
        [result setObject:_creator forKey:(__bridge NSString *)kSecAttrCreator];
    }
    if (_type) {
        [result setObject:_type forKey:(__bridge NSString *)kSecAttrType];
    }
    if (_label) {
        [result setObject:_label forKey:(__bridge NSString *)kSecAttrLabel];
    }
    if (_invisible) {
        [result setObject:_invisible forKey:(__bridge NSString *)kSecAttrIsInvisible];
    }
    if (_negative) {
        [result setObject:_negative forKey:(__bridge NSString *)kSecAttrIsNegative];
    }
    if (_generic.dataValue) {
        [result setObject:_generic.dataValue forKey:(__bridge NSString *)kSecAttrGeneric];
    }
    if (_secret.dataValue) {
        [result setObject:_secret.dataValue forKey:(__bridge NSString *)kSecValueData];
    }
    return result;
}

@end
