//
//  BoxAPIRequestBuilder.h
//  BoxSDK
//
//  Created on 3/12/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const BoxAPIQueryStringValueTrue;
extern NSString *const BoxAPIQueryStringValueFalse;

/**
 * BoxAPIRequestBuilder is an abstract base class for request builder objects. Because
 * it is an abstract class, you should not instantiate it directly. This class enforces
 * its abstractness with calls to the `BOXAbstract` macro, which throw `NSAssert` failures
 * when `DEBUG=1`.
 *
 * This class encapsulates methods for encoding the HTTP body of an API request.
 */
@interface BoxAPIRequestBuilder : NSObject

/**
 * Key value pairs to be included in the query string of the API request.
 */
@property (nonatomic, readonly, strong) NSMutableDictionary *queryStringParameters;

/** @name Initialization */

/**
 * Designated initializer.
 *
 * @param queryStringParameters Key value pairs to include in the query string of the API request.
 * @return An initialized BoxAPIRequestBuilder.
 */
- (id)initWithQueryStringParameters:(NSDictionary *)queryStringParameters;

/** @name Generating the HTTP body */

/**
 * Return an `NSDictionary` containing all of the properties set on this builder. These properties
 * should be encoded in the "on-the-wire" represention the API expects.
 *
 * @return A dictionary containing all properties set on this builder.
 */
- (NSDictionary *)bodyParameters;

/**
 * Format dates as ISO 8601 strings for sending over the wire to the Box API
 *
 * @param date The date to encode.
 * @return An ISO 8601 encoded date string in UTC.
 */
-(NSString *)ISO8601StringWithDate:(NSDate *)date;

/**
 * Helper method to set an object in a dictionary if the object is not nil.
 *
 * @param object The object to insert into the dictionary.
 * @param key The key to use when inserting object.
 * @param dictionary The dictionary to insert object into.
 */
- (void)setObjectIfNotNil:(id)object forKey:(id<NSCopying>)key inDictionary:(NSMutableDictionary *)dictionary;

/**
 * Helper method to set an ISO 8601 date string in a dictionary if the date is not nil.
 *
 * @param date The date to encode and insert into the dictionary.
 * @param key The key to use when inserting object.
 * @param dictionary The dictionary to insert object into.
 */
- (void)setDateStringIfNotNil:(NSDate *)date forKey:(id<NSCopying>)key inDictionary:(NSMutableDictionary *)dictionary;

@end
