//
//  BoxCollection.h
//  BoxSDK
//
//  Created on 3/14/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BoxModel.h"

/**
 * A BoxCollection is a special type of BoxModel that represents a page of
 * a set of BoxModels. Some Box APIs return many objects. These endpoints are paged.
 * A BoxCollection represents a page of objects.
 */
@interface BoxCollection : BoxModel

/**
 * The total number of BoxModels across all `BoxCollection` instances for
 * the same API call.
 */
@property (nonatomic, readonly) NSNumber *totalCount;

/**
 * The total number of BoxModels on this page.
 */
@property (nonatomic, readonly) NSUInteger numberOfEntries;

/**
 * Return a model from the collection. All BoxCollection instances are zero-indexed
 * regardless what page they represent.
 *
 * @param index The index of the model to retreive. Always zero-indexed.
 * @return A BoxModel from the BoxCollection.
 */
- (BoxModel *)modelAtIndex:(NSUInteger)index;

@end
