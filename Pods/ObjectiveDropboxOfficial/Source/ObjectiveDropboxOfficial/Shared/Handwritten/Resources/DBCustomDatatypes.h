///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Custom client-side datatypes
///

#import <Foundation/Foundation.h>

#import "DBHandlerTypes.h"

@class DBASYNCPollError;
@class DBFILESCommitInfo;
@class DBFILESUploadSessionFinishArg;
@class DBFILESUploadSessionFinishBatchJobStatus;
@class DBRequestError;
@class DBTasksStorage;

NS_ASSUME_NONNULL_BEGIN

///
/// Stores data for a particular batch upload attempt.
///
@interface DBBatchUploadData : NSObject

/// The queue on which most response handling is performed.
@property (nonatomic, readonly) NSOperationQueue *queue;

/// The dispatch group that pairs upload requests with upload responses so that we can wait for all request/response
/// pairs to complete before batch committing. In this way, we can start many upload requests (for files under the chunk
/// limit), without waiting for the corresponding response.
@property (nonatomic, readonly) dispatch_group_t uploadGroup;

/// A client-supplied parameter that maps the file urls of the files to upload to the corresponding commit info objects.
@property (nonatomic, readonly) NSDictionary<NSURL *, DBFILESCommitInfo *> *fileUrlsToCommitInfo;

/// Mapping of urls for files that were unsuccessfully uploaded to any request errors that were encounted.
@property (atomic, readonly) NSMutableDictionary<NSURL *, DBRequestError *> *fileUrlsToRequestErrors;

/// List of finish args (which include commit info, cursor, etc.) which the SDK maintains and passes to
/// `upload_session/finish_batch`.
@property (atomic, strong) NSMutableArray<DBFILESUploadSessionFinishArg *> *finishArgs;

/// The progress block that is periodically executed once a file upload is complete.
@property (nonatomic, readonly) DBProgressBlock _Nullable progressBlock;

/// The response block that is executed once all file uploads and the final batch commit is complete.
@property (nonatomic, readonly) DBBatchUploadResponseBlock responseBlock;

/// The total size of all the files to upload. Used to return progress data to the client.
@property (nonatomic) NSUInteger totalUploadSize;

/// The total size of all the file content upload so far. Used to return progress data to the client.
@property (nonatomic) NSUInteger totalUploadedSoFar;

/// The flag that determines whether upload continues or not.
@property (atomic) BOOL cancel;

/// The container object that stores all upload / download task objects for cancelling.
@property (nonatomic, strong) DBTasksStorage *taskStorage;

///
/// Full constructor.
///
/// @param fileUrlsToCommitInfo A client-supplied parameter that maps the file urls of the files to upload to the
/// corresponding commit info objects.
/// @param progressBlock The progress block that is periodically executed once a file upload is complete.
/// @param responseBlock The response block that is executed once all file uploads and the final batch commit is
/// complete.
/// @param queue The queue on which most response handling is performed.
///
/// @return An initialized instance.
///
- (instancetype)initWithFileCommitInfo:(NSDictionary<NSURL *, DBFILESCommitInfo *> *)fileUrlsToCommitInfo
                         progressBlock:(DBProgressBlock _Nullable)progressBlock
                         responseBlock:(DBBatchUploadResponseBlock)responseBlock
                                 queue:(NSOperationQueue *)queue;

@end

NS_ASSUME_NONNULL_END
