//
//  XKKeychainDataAttribute.h
//  Pods
//
//  Created by Karl von Randow on 24/10/14.
//
//

#import <Foundation/Foundation.h>

/** A helper that represents a data attribute. The helper enables NSData, NSString, NSDictionary or any other NSKeyedArchiver compatible object
    to be converted to and from the data attribute's value.
 */
@interface XKKeychainDataAttribute : NSObject

+ (instancetype)dataAttributeWithData:(NSData *)data;
+ (instancetype)dataAttributeWithObject:(id)object;

@property (strong, nonatomic) NSData *dataValue;
@property (strong, nonatomic) NSString *stringValue;
@property (strong, nonatomic) NSDictionary *dictionaryValue;
@property (strong, nonatomic) id transformableValue;

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void)removeObjectForKey:(id)aKey;
- (id)objectForKey:(id)aKey;

- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)aKey;

@end
