///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBHandlerTypes.h"
#import "DBHandlerTypesInternal.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Progress data

///
/// Progress data storage.
///
/// Progress and response handlers can be added to `DBDelegate` after a request is initiated. If a handler does not
/// exist at the time the network response is received, progress data and/or response data will be saved until a handler
/// is queued up to the corresponding task id. This gives the client the flexibility to install handlers when
/// convenient. This class stores data for all progress handlers.
///
@interface DBProgressData : NSObject

/// Bytes committed (sent if RPC or Upload request, and downloaded if Download request).
@property (nonatomic, readonly) int64_t committed;

/// Total bytes committed (sent if RPC or Upload request, and downloaded if Download request).
@property (nonatomic, readonly) int64_t totalCommitted;

/// Total bytes expected to commit (sent if RPC or Upload request, and downloaded if Download request).
@property (nonatomic, readonly) int64_t expectedToCommit;

///
/// `DBProgressData` full constructor.
///
/// @param committed Bytes committed (sent if RPC or Upload request, and downloaded if Download request).
/// @param totalCommitted Total bytes committed (sent if RPC or Upload request, and downloaded if Download request).
/// @param expectedToCommit Total bytes expected to commit (sent if RPC or Upload request, and downloaded if Download
/// request).
///
/// @return An initialized `DBProgressData` instance.
///
- (instancetype)initWithProgressData:(int64_t)committed
                      totalCommitted:(int64_t)totalCommitted
                    expectedToCommit:(int64_t)expectedToCommit;

@end

#pragma mark - Completion data

///
/// Completion data storage.
///
/// Progress and response handlers can be added to `DBDelegate` after a request is initiated. If a handler does not
/// exist at the time the network response is received, progress data and/or response data will be saved until a handler
/// is queued up to the corresponding task id. This gives the client the flexibility to install handlers when
/// convenient. This class stores data for all completion handlers.
///
@interface DBCompletionData : NSObject

/// Data returned by the server in the response body.
@property (nonatomic, readonly, nullable) NSData *responseBody;

/// Metadata returned by the server in the response headers.
@property (nonatomic, readonly, nullable) NSURLResponse *responseMetadata;

/// Client-side networking error.
@property (nonatomic, readonly, nullable) NSError *responseError;

/// Location of output content (for Download-style requests only).
@property (nonatomic, readonly, nullable) NSURL *urlOutput;

///
/// `DBCompletionData` full constructor.
///
/// @param responseBody Data returned by the server in the response body.
/// @param responseMetadata Metadata returned by the server in the response headers.
/// @param responseError Client-side networking error.
/// @param urlOutput Location of output content (for Download-style requests only).
///
/// @return An initialized `DBCompletionData` instance.
///
- (instancetype)initWithCompletionData:(nullable NSData *)responseBody
                      responseMetadata:(nullable NSURLResponse *)responseMetadata
                         responseError:(nullable NSError *)responseError
                             urlOutput:(nullable NSURL *)urlOutput;

@end

#pragma mark - Session data

///
/// Session data storage.
///
/// All response data and handler data for a given session id is stored in this class. `DBDelegate` maintains a map of
/// session ids to `DBSessionData` objects to manage response handling.
///
@interface DBSessionData : NSObject

/// The unique identifier of the session. Data is stored by session (rather than task id, because task ids are not
/// unique across sessions.
@property (nonatomic, copy) NSString *sessionId;

/// Map from task id to response body data (for RPC and Upload style requests).
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableData *> *responsesData;

/// Map from task id to progress handler. Progress handlers are of the same type for all different styles of API
/// requests.
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, DBProgressBlock> *progressHandlers;

/// Map from task id to RPC-style response handler.
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, DBRpcResponseBlockStorage> *rpcHandlers;

/// Map from task id to Upload-style response handler.
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, DBUploadResponseBlockStorage> *uploadHandlers;

/// Map from task id to Download-style response handler.
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, DBDownloadResponseBlockStorage> *downloadHandlers;

/// Map from task id to completion data object. Stores completion data for all styles of API requests.
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, DBCompletionData *> *completionData;

/// Map from task id to progress data object. Stores progress data for all styles of API requests.
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, DBProgressData *> *progressData;

/// Map from task id to progress handler queue. Stores handler queues for all styles of API requests.
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSOperationQueue *> *progressHandlerQueues;

/// Map from task id to response handler queue. Stores handler queues for all styles of API requests.
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSOperationQueue *> *responseHandlerQueues;

///
/// `DBSessionData` full constructor.
///
/// @param sessionid The unique identifier of the session.
///
/// @return An initialized `DBSessionData` instance.
///
- (instancetype)initWithSessionId:(NSString *)sessionid;

@end

NS_ASSUME_NONNULL_END
