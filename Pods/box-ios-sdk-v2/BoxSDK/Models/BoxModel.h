//
//  BoxModel.h
//  BoxSDK
//
//  Created on 3/14/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BoxLog.h"
#import "NSJSONSerialization+BoxAdditions.h"

/**
 * BoxModel is the base class for all objects that may be returned by the Box API.
 * It exposes two fields that every object has: a `type` and `modelID`.
 *
 * Models are immutable: they represent a snapshot of an object in Box from when it
 * was fetched via the API. This implies that models should only have accessor methods.
 * BoxModel objects should be manipulated via subclasses of BoxAPIResourceManager.
 *
 * Models should convert the on-the-wire representation used by the API to a native
 * objective-c type whenever possible. This includes transforming ISO 8601 timestamps
 * to `NSDate`s and JSON booleans to `BOOL`s.
 *
 * Model objects should assume the API may return inconsistent or garbage data when
 * implementing accessor methods. They should fail safely in these instances.
 *
 * Model objects may not always be instantiated with the full set of fields associated
 * with an object. Some API responses return mini representations of objects and ?fields
 * may cause objects to be returned with a subset of fields.
 *
 * Field names and object types have constants defined for them in `BoxSDKConstants.h`.
 *
 * @warning BoxModel instances disambiguate between fields that are not present and fields
 * that are present in the underlying JSON with the value null.
 *
 * Fields not present in the underlying JSON will be returned as `nil`.
 *
 * Fields present with the JSON value null will be returned as instances of `NSNull`.
 */
@interface BoxModel : NSObject

/** @name API representation */

/**
 * The JSON that is received from the Box API.
 */
@property (nonatomic, readonly) NSDictionary *rawResponseJSON;

/**
 * Whether the API call that instantiated this BoxModel expects to receive
 * a mini representation.
 */
@property (nonatomic, readonly, getter = isMini) BOOL mini;

/** @name Accessors */

/**
 * The type of object returned by the API.
 */
@property (nonatomic, readonly) NSString *type;

/**
 * The ID of this model. This field is unique for all objects of the same type but may
 * not be unique across model types.
 */
@property (nonatomic, readonly) NSString *modelID;

/** @name Initialization */

/**
 * Designated initializer.
 *
 * @param responseJSON The JSON representation of this model received from the Box API.
 * @param mini Whether the API call instantiating this model expects to receive the object
 *   in mini representation.
 *
 * @return A BoxModel object backed by a JSON dictionary.
 */
- (id)initWithResponseJSON:(NSDictionary *)responseJSON mini:(BOOL)mini;

/** @name Decode to native types */

/**
 * Convert an ISO 8601 date string to a native `NSDate`. ISO 8601 strings are
 * the Box API's on-the-wire representation for dates
 *
 * @param timestamp The ISO 8601 date timestamp.
 * @return A decoded date.
 */
- (NSDate *)dateWithISO8601String:(NSString *)timestamp;

/** @name Comparison */

/**
 * Compare this model to another model object using the supplied comparator.
 * Several comparators are provided in BoxModelComparators
 *
 * @param model Model object to compare to this one.
 * @param comparator Comparator to use for the comparison.
 * @return NSComparisonResult
 */
- (NSComparisonResult)compare:(BoxModel *)model usingComparator:(NSComparator)comparator;

@end
