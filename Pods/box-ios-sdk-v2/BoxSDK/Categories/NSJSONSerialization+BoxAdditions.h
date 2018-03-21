//
//  NSJSONSerialization+BoxAdditions.h
//  BoxSDK
//
//  Created on 8/19/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * The BoxAdditions category on NSJSONSerialization provides a class method for ensuring
 * that an object extracted from a decoded JSON object is of the expected type.
 *
 * This category is used by BoxModel subclasses to extract properties from [BoxModel rawResponseJSON].
 */
@interface NSJSONSerialization (BoxAdditions)

/** @name Reflection helpers */

/**
 * Ensure that the object at `key` in `dictionary` is a member of the expected class.
 * `NSNull` may be specified as an allowable value. This method may return nil if `key`
 * is not present in `dictionary`.
 *
 * @param key The key to lookup in `dictionary`.
 * @param dictionary A dictionary resulting from deserializing a JSON object.
 * @param cls The expected class of the value at key.
 * @param nullAllowed If true, `NSNull` is an allowable value. Property getters that pass
 *   `YES` for this parameter should have the return type of `id`.
 *
 * @return The object at `key` in `dictionary` if expectations are satisfied; `nil` otherwise.
 */
+ (id)box_ensureObjectForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary hasExpectedType:(Class)cls nullAllowed:(BOOL)nullAllowed;

/**
 * Ensure that the object at `key` in `dictionary` is a member of the expected class.
 * `NSNull` may be converted to nil. This method may return nil if `key`
 * is not present in `dictionary`.
 *
 * @param key The key to lookup in `dictionary`.
 * @param dictionary A dictionary resulting from deserializing a JSON object.
 * @param cls The expected class of the value at key.
 * @param nullAllowed If true, `NSNull` is an allowable value. Property getters that pass
 *   `YES` for this parameter should have the return type of `id`.
 * @param suppressNullAsNil If true and nullAllowed is true, `NSNull` will be converted to `nil`.
 *
 * @return The object at `key` in `dictionary` if expectations are satisfied; `nil` otherwise.
 */
+ (id)box_ensureObjectForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary hasExpectedType:(Class)cls nullAllowed:(BOOL)nullAllowed suppressNullAsNil:(BOOL)suppressNullAsNil;

@end
