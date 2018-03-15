//
//  BoxModelComparators.h
//  BoxSDK
//
//  Created on 8/4/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * BoxModelComparators defines several comparators for comparing BoxModel, BoxItem, and
 * BoxFile objects.
 *
 * Comparators are lazily created and each comparator block is only created once.
 *
 * Comparators are exposed as class methods. To add more comparators, you can either
 * extend this class or define a category.
 */
@interface BoxModelComparators : NSObject

#pragma mark - Comparators
/** @name Comparators */

/**
 * A comparator that orders BoxModel instances by [BoxModel type]
 * and then [BoxModel modelID].
 *
 */
+ (NSComparator)modelByTypeAndID;

/**
 * A comparator that orders BoxItem instances by [BoxItem name].
 *
 * If [BoxItem name] is nil for either model, the behavior of this comparator is undefined.
 */
+ (NSComparator)itemByName;

/**
 * A comparator that orders BoxItem instances by [BoxItem createdAt].
 *
 * If [BoxItem createdAt] is nil for either model, the behavior of this comparator is undefined.
 */
+ (NSComparator)itemByCreatedAt;

/**
 * A comparator that orders BoxItem instances by [BoxItem modifiedAt].
 *
 * If [BoxItem modifiedAt] is nil for either model, the behavior of this comparator is undefined.
 */
+ (NSComparator)itemByModifiedAt;

/**
 * A comparator that orders BoxItem instances by [BoxItem size].
 *
 * If [BoxItem size] is nil for either model, the behavior of this comparator is undefined.
 */
+ (NSComparator)itemBySize;

/**
 * A comparator that orders BoxFile instances by [BoxFile SHA1].
 *
 * If [BoxFile SHA1] is nil for either model, the behavior of this comparator is undefined.
 */
+ (NSComparator)fileBySHA1;

@end
