//
//  BoxSharedObjectBuilder.h
//  BoxSDK
//
//  Created on 3/12/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIRequestBuilder.h"

typedef NSString BoxAPISharedObjectAccess;
extern BoxAPISharedObjectAccess *const BoxAPISharedObjectAccessOpen;
extern BoxAPISharedObjectAccess *const BoxAPISharedObjectAccessCompany;
extern BoxAPISharedObjectAccess *const BoxAPISharedObjectAccessCollaborators;

typedef enum {
    BoxAPISharedObjectPermissionStateEnabled = -1,
    BoxAPISharedObjectPermissionStateDisabled = 0,
    BoxAPISharedObjectPermissionStateUnset = 1,
} BoxAPISharedObjectPermissionState;

/**
 * BoxSharedObjectBuilder allows callers to build the on-the-wire representation
 * for setting and unsetting shared links on subclasses of BoxItem.
 *
 * Constants
 * =========
 * This class exposes several constants to set the state of a shared link.
 *
 * For setting access levels:
 *
 * - `BoxAPISharedObjectAccessOpen`
 * - `BoxAPISharedObjectAccessCompany`
 * - `BoxAPISharedObjectAccessCollaborators`
 *
 * For setting permission levels:
 *
 * - `BoxAPISharedObjectPermissionStateEnabled`
 * - `BoxAPISharedObjectPermissionStateDisabled`
 * - `BoxAPISharedObjectPermissionStateUnset`
 */
@interface BoxSharedObjectBuilder : BoxAPIRequestBuilder

/**
 * Access level of the shared link. Determines link visibility. This property is required.
 */
@property (nonatomic, readwrite, strong) BoxAPISharedObjectAccess *access;

/**
 * The date at which the link should be diasbled. Leave unset for links
 * that should not expire.
 */
@property (nonatomic, readwrite, strong) NSDate *unsharedAt;

/**
 * Whether this link allows downloads. Can only be used with access levels
 * `BoxAPISharedObjectAccessOpen` and `BoxAPISharedObjectAccessCompany`.
 */
@property (nonatomic, readwrite, assign) BoxAPISharedObjectPermissionState canDownload;

/**
 * Whether this link allows previewing. Can only be used with access levels
 * `BoxAPISharedObjectAccessOpen` and `BoxAPISharedObjectAccessCompany`.
 */
@property (nonatomic, readwrite, assign) BoxAPISharedObjectPermissionState canPreview;


@end
