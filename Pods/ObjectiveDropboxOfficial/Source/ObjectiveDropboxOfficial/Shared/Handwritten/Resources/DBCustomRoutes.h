///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

///
/// Custom client-side routes
///

#import <Foundation/Foundation.h>

#import "DBFILESUserAuthRoutes.h"
#import "DBHandlerTypes.h"

@class DBBatchUploadTask;
@class DBFILESCommitInfo;

NS_ASSUME_NONNULL_BEGIN

///
/// Extension of routes in the `Files` namespace.
///
/// These routes serve as a convenience layer built on top of our auto-generated routes.
///
@interface DBFILESUserAuthRoutes (DBCustomRoutes)

///
/// Batch uploads small and large files.
///
/// This is a custom route built as a convenience layer over several Dropbox endpoints. Files will not only be batch
/// uploaded, but large files will also automatically be chunk-uploaded to the Dropbox server, for maximum efficiency.
///
/// @note The interface of this route does not have the same structure as other routes in the SDK. Here, a special
/// `DBBatchUploadTask` object is returned. Progress and response handlers are passed in directly to the route, rather
/// than installed via this response object.
///
/// @param fileUrlsToCommitInfo Map from the file urls of the files to upload to the corresponding commit info objects.
/// @param queue The operation queue to execute progress / response handlers on. Main queue if `nil` is passed.
/// @param progressBlock The progress block that is periodically executed once a file upload is complete. It's important
/// to note that this progress handler will update only when a file or file chunk is successfully uploaded. It will not
/// give the client any progress notifications once all of the file data is uploaded, but not yet committed. Once the
/// batch commit call is made, the client will have to simply wait for the server to commit all of the uploaded data,
/// until the response handler is called.
/// @param responseBlock The response block that is executed once all file uploads and the final batch commit is
/// complete.
///
/// @returns Special `DBBatchUploadTask` that exposes cancellation method.
///
- (DBBatchUploadTask *)batchUploadFiles:(NSDictionary<NSURL *, DBFILESCommitInfo *> *)fileUrlsToCommitInfo
                                  queue:(nullable NSOperationQueue *)queue
                          progressBlock:(DBProgressBlock _Nullable)progressBlock
                          responseBlock:(DBBatchUploadResponseBlock)responseBlock;

@end

NS_ASSUME_NONNULL_END
