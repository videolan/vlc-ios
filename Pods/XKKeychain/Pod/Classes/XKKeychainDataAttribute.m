//
//  XKKeychainDataAttribute.m
//  Pods
//
//  Created by Karl von Randow on 24/10/14.
//
//

#import "XKKeychainDataAttribute.h"

@implementation XKKeychainDataAttribute

+ (instancetype)dataAttributeWithData:(NSData *)data
{
    XKKeychainDataAttribute *result = [XKKeychainDataAttribute new];
    result.dataValue = data;
    return result;
}

+ (instancetype)dataAttributeWithObject:(id)object
{
    XKKeychainDataAttribute *result = [XKKeychainDataAttribute new];
    if ([object isKindOfClass:[NSData class]]) {
        result.dataValue = object;
    } else if ([object isKindOfClass:[NSString class]]) {
        result.stringValue = object;
    } else {
        result.transformableValue = object;
    }
    return result;
}

#pragma mark - Properties

- (NSString *)stringValue
{
    if (self.dataValue) {
        return [[NSString alloc] initWithData:self.dataValue encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

- (void)setStringValue:(NSString *)string
{
    self.dataValue = [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSDictionary *)dictionaryValue
{
    id value = [self transformableValue];
    if ([value isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)value;
    } else {
        return nil;
    }
}

- (void)setDictionaryValue:(NSDictionary *)dictionaryValue
{
    [self setTransformableValue:dictionaryValue];
}

- (id)transformableValue
{
    if (self.dataValue.length > 0) {
        @try {
            return [NSKeyedUnarchiver unarchiveObjectWithData:self.dataValue];
        }
        @catch (NSException *exception) {
            NSLog(@"Attempted to unarchive but couldn't: %@", exception);
            return nil;
        }
    } else {
        return nil;
    }
}

- (void)setTransformableValue:(id)transformable
{
    if (transformable) {
        self.dataValue = [NSKeyedArchiver archivedDataWithRootObject:transformable];
    } else {
        self.dataValue = nil;
    }
}

#pragma mark - Public

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:self.dictionaryValue];
    [dictionary setObject:anObject forKey:aKey];
    self.dictionaryValue = dictionary;
}

- (void)removeObjectForKey:(id)aKey
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:self.dictionaryValue];
    [dictionary removeObjectForKey:aKey];
    self.dictionaryValue = dictionary;
}

- (id)objectForKey:(id)aKey
{
    NSDictionary *dictionary = self.dictionaryValue;
    return [dictionary objectForKey:aKey];
}

- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)aKey
{
    [self setObject:object forKey:aKey];
}

@end
