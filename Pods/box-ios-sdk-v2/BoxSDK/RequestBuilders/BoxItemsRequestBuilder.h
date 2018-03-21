//
//  BoxItemRequestBuilder.h
//  BoxSDK
//
//  Created on 3/28/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIRequestBuilder.h"

@class BoxSharedObjectBuilder;

/**
 * BoxItemsRequestBuilder is an abstract base class for building API requests relating
 * to subclasses of BoxItem. Because this class is abstract, you should not instantiate
 * it directly. This class does not enforce its abstractness.
 *
 * This class allows constructing of the HTTP body for `POST` and 'PUT` requests as well
 * as setting query string parameters on the request.
 */
@interface BoxItemsRequestBuilder : BoxAPIRequestBuilder

/** @name Settable fields */

/**
 * The name of the item.
 */
@property (nonatomic, readwrite, strong) NSString *name;

/**
 * The description of the item.
 */
@property (nonatomic, readwrite, strong) NSString *description;

/**
 * The content created time of the item. This timestamp represents the time
 * a physical item was created on a client machine.
 *
 * @warning This property is only settable on item creation.
 */
@property (nonatomic, readwrite, strong) NSDate *contentCreatedAt;

/**
 * The content modified time of the item. This timestamp represents the time
 * a physical item was last modified on a client machine.
 *
 * @warning This property is only settable on item creation or the creation of new item
 *   versions.
 */
@property (nonatomic, readwrite, strong) NSDate *contentModifiedAt;

/**
 * The modelID of the parent of this folder. This property is used for creation and moves.
 */
@property (nonatomic, readwrite, strong) NSString *parentID;

/**
 * A BoxSharedObjectBuilder for setting and/or unsetting shared links on the item.
 */
@property (nonatomic, readwrite, strong) BoxSharedObjectBuilder *sharedLink;

@end
