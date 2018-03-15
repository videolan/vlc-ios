//
//  BoxFoldersRequestBuilder.h
//  BoxSDK
//
//  Created on 3/12/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxItemsRequestBuilder.h"

// Folder email access levels
typedef NSString BoxAPIFolderUploadEmailAccess;
extern BoxAPIFolderUploadEmailAccess *const BoxAPIFolderUploadEmailAccessCollaborators;
extern BoxAPIFolderUploadEmailAccess *const BoxAPIFolderUploadEmailAccessOpen;
extern BoxAPIFolderUploadEmailAccess *const BoxAPIFolderUploadEmailAccessDisable;

extern NSString *const BoxAPIFolderRecursiveQueryParameter;

/**
 * BoxFoldersRequestBuilder is an request builder for folder operations.
 *
 * This class allows constructing of the HTTP body for `POST` and 'PUT` requests as well
 * as setting query string parameters on the request.
 *
 * Constants and typedefs
 * ======================
 * For configuuring folder upload email access, this class exposes a typedef and several constants:
 *
 * <pre><code>typedef NSString BoxAPIFolderUploadEmailAccess;</code><pre>
 *
 * And the constants:
 *
 * - `BoxAPIFolderUploadEmailAccessCollaborators`
 * - `BoxAPIFolderUploadEmailAccessOpen`
 * - `BoxAPIFolderUploadEmailAccessDisable`
 */
@interface BoxFoldersRequestBuilder : BoxItemsRequestBuilder

@property (nonatomic, readwrite, strong) BoxAPIFolderUploadEmailAccess *folderUploadEmailAccess;

/** @name Initization */

/**
 * An additional initializer that sets the `recursive` query string parameter for folder deletes.
 *
 * @param recursive Whether a folder delete should be recursive or not.
 * @return a BoxFoldersRequestBuilder with the recrusive key set.
 */
- (id)initWithRecursiveKey:(BOOL)recursive;

@end
