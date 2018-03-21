//
//  BoxItem.h
//  BoxSDK
//
//  Created on 3/22/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxModel.h"

@class BoxFolder, BoxCollection, BoxUser;

/**
 * BoxItem is an abstract model class representing items on Box. An item is any object
 * that can be a child of a BoxFolder. These are:
 *
 * - BoxFile
 * - BoxFolder
 * - BoxWebLink
 */
@interface BoxItem : BoxModel

/**
 * An item's sequence ID. This field monotonically increases when
 * an item's core properties change.
 */
@property (nonatomic, readonly) NSString *sequenceID;

/**
 * An item's ETag. This string is guaranteed to be unique across all versions
 * of an item, but not across items. This should be treated as an opaque string.
 * ETags have no meaning other than that they are ETags.
 */
@property (nonatomic, readonly) NSString *ETag;

/**
 * An item's name.
 */
@property (nonatomic, readonly) NSString *name;

/**
 * The date this item was first created on Box.
 */
@property (nonatomic, readonly) NSDate *createdAt;

/**
 * The date this item was last updated on Box.
 */
@property (nonatomic, readonly) NSDate *modifiedAt;

/**
 * The date the content of this item was created on some client machine.
 *
 * This is similar to the UNIX `ctime`.
 */
@property (nonatomic, readonly) NSDate *contentCreatedAt;

/**
 * The date the content of this item was modified on some client machine.
 *
 * This is similar to the UNIX `mtime`.
 */
@property (nonatomic, readonly) NSDate *contentModifiedAt;

/**
 * The date this item was moved to the trash.
 * This field will only be set for items in the trash.
 */
@property (nonatomic, readonly) NSDate *trashedAt; // @TODO: Add tests for this property

/**
 * The date this item will be automatically deleted from the trash.
 * This field will only be set for items in the trash.
 */
@property (nonatomic, readonly) NSDate *purgedAt; // @TODO: Add tests for this property

/**
 * An item's description.
 */
@property (nonatomic, readonly) NSString *description;

/**
 * An item's size in bytes.
 */
@property (nonatomic, readonly) NSNumber *size;

/**
 * Breadcrumbs of the file system path to this item. This collection is
 * always returned from the point of view of the caller.
 *
 * The path collection never includes the current item.
 */
@property (nonatomic, readonly) BoxCollection *pathCollection;

/**
 * The BoxUser who created this item.
 */
@property (nonatomic, readonly) BoxUser *createdBy;

/**
 * The BoxUser who last modified this item.
 */
@property (nonatomic, readonly) BoxUser *modifiedBy;

/**
 * The BoxUSer who owns this item.
 */
@property (nonatomic, readonly) BoxUser *ownedBy;

/**
 * A dictionary containing information about an item's shared link.
 */
@property (nonatomic, readonly) NSDictionary *sharedLink;

/**
 * The BoxFolder where this item is located. This field is always given
 * in terms of the owner's view. If this item does not live in the current
 * user's tree or is the root of a tree, this field will be `NSNull`.
 */
@property (nonatomic, readonly) id parent;

/**
 * Whether this item is deleted or not.
 */
@property (nonatomic, readonly) NSString *itemStatus;

@end
