//
//  BoxFoldersResourceManager.h
//  BoxSDK
//
//  Created on 3/12/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIResourceManager.h"

#import "BoxAPIJSONOperation.h"
#import "BoxFolder.h"
#import "BoxCollection.h"

extern NSString *const BoxAPIFolderIDRoot;
extern NSString *const BoxAPIFolderIDTrash;

typedef void (^BoxFolderBlock)(BoxFolder *folder);

@class BoxFoldersRequestBuilder;

/**
 * BoxFoldersResourceManager allows you to access and manipulate folders via the Box API. This class is
 * a concrete subclass of BoxAPIResourceManager. This class allows you to manipulate [BoxFolders]([BoxFolder])
 * referred to by their `modelID`, which is an `NSString`.
 *
 * This class enables the following operations:
 *
 * - [Get a folder's information](http://developers.box.com/docs/#folders-get-information-about-a-folder)
 * - [Retreive a folder's child items](http://developers.box.com/docs/#folders-retrieve-a-folders-items)
 * - [Edit a folder's information](http://developers.box.com/docs/#folders-update-information-about-a-folder)
 * - [Copy a folder](http://developers.box.com/docs/#folders-copy-a-folder)
 * - [Create a new folder](http://developers.box.com/docs/#folders-create-a-new-folder)
 * - [Delete a folder](http://developers.box.com/docs/#folders-delete-a-folder)
 * - [Get a list of items in the trash](http://developers.box.com/docs/#folders-get-the-items-in-the-trash)
 * - [Get a folder in the trash's information](http://developers.box.com/docs/#folders-get-a-trashed-folder)
 * - [Restore a folder in the trash](http://developers.box.com/docs/#folders-restore-a-trashed-folder)
 * - [Permanently delete a trashed folder](http://developers.box.com/docs/#folders-permanently-delete-a-trashed-folder)
 *
 * Callbacks and typedefs
 * ======================
 * This class defines the `BoxFolderBlock` type for successful API calls that return a BoxFolder object:
 *
 * <pre><code>typedef void (^BoxFolderBlock)(BoxFolder *folder);</code></pre>
 *
 * Constants
 * =========
 * This class exposes two additional constants:
 *
 * - `BoxAPIFolderIDRoot`, for referring to the root (All Files) folder.
 * - `BoxAPIFolderIDTrash`, for referring to the trash.
 */
@interface BoxFoldersResourceManager : BoxAPIResourceManager

/** @name API calls */

/**
 * Create and enqueue a BoxAPIJSONOperation to fetch a folder's information.
 *
 * See the Box documentation for [getting a folder's information](http://developers.box.com/docs/#folders-get-information-about-a-folder).
 *
 * Using `BoxAPIFolderIDTrash` as folderID allows viewing the contents of the trash.
 *
 * @param folderID The `modelID` of a BoxFolder you wish to fetch information for.
 * @param builder A BoxFoldersRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `GET` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)folderInfoWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxFolderBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to create a new folder.
 *
 * See the Box documentation for [creating a new folder](http://developers.box.com/docs/#folders-create-a-new-folder).
 *
 * @param builder A BoxFoldersRequestBuilder instance that contains query parameters and body data for the request.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)createFolderWithRequestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxFolderBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to fetch a folder's child items.
 *
 * See the Box documentation for [retreiving a folder's child items](http://developers.box.com/docs/#folders-retrieve-a-folders-items).
 *
 * @param folderID The `modelID` of a BoxFolder you wish to fetch information for.
 * @param builder A BoxFoldersRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `GET` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)folderItemsWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxCollectionBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to edit a folder's information.
 *
 * See the Box documentation for [editing a folder's information](http://developers.box.com/docs/#folders-update-information-about-a-folder).
 *
 * @param folderID The `modelID` of a BoxFolder you wish to fetch information for.
 * @param builder A BoxFoldersRequestBuilder instance that contains query parameters and body data for the request.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)editFolderWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxFolderBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to delete a folder. In most cases this moves a folder to the trash.
 * Behavior is dependent on enterprise settings.
 *
 * See the Box documentation for [deleting a folder](http://developers.box.com/docs/#folders-delete-a-folder).
 *
 * @param folderID The `modelID` of a BoxFolder you wish to fetch information for.
 * @param builder A BoxFoldersRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `DELETE` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)deleteFolderWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxSuccessfulDeleteBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to copy a folder and all of its contents.
 *
 * See the Box documentation for [copying a folder](http://developers.box.com/docs/#folders-copy-a-folder).
 *
 * @param folderID The `modelID` of a BoxFolder you wish to fetch information for.
 * @param builder A BoxFoldersRequestBuilder instance that contains query parameters and body data for the request.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)copyFolderWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxFolderBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to fetch a folder's information.
 *
 * See the Box documentation for [getting a folder in the trash's information](http://developers.box.com/docs/#folders-get-a-trashed-folder).
 *
 * @param folderID The `modelID` of a BoxFolder you wish to fetch information for.
 * @param builder A BoxFoldersRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `GET` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)folderInfoFromTrashWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxFolderBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to restore a folder from the trash.
 *
 * See the Box documentation for [restoring a folder in the trash](http://developers.box.com/docs/#folders-restore-a-trashed-folder).
 *
 * @param folderID The `modelID` of a BoxFolder you wish to fetch information for.
 * @param builder A BoxFoldersRequestBuilder instance that contains query parameters and body data for the request.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)restoreFolderFromTrashWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxFolderBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to permanently delete a folder from the trash.
 *
 * See the Box documentation for [permanently deleting a trashed folder](http://developers.box.com/docs/#folders-permanently-delete-a-trashed-folder).
 *
 * @param folderID The `modelID` of a BoxFolder you wish to fetch information for.
 * @param builder A BoxFoldersRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `DELETE` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)deleteFolderFromTrashWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxSuccessfulDeleteBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

@end
