///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBHandlerTypes.h"
#import "DBHandlerTypesInternal.h"

@class DBRpcData;
@class DBUploadData;
@class DBDownloadData;

NS_ASSUME_NONNULL_BEGIN

///
/// Delegate class used to manage the execution of handler code for RPC, Upload and Download style requests.
///
/// @note This delegate forces all supplied delegate queues to be serial.
///
/// By default, this delegate is instantiated in the constructor of the `DBTransportDefaultClient` class, and uses the
/// main delegate queue, so all handler code will be executed serially and on the main thread.
///
/// Progress and response handlers can be added after the request is initiated. If a handler does not exist at the time
/// the network response is received, progress data and/or response data will be saved until a handler is queued up to
/// the corresponding task ID. For downloaded file content, the file content will be moved from an `NSURLSession`
/// managed temporary location to an SDK managed temporary location, until the response handler is installed, at which
/// point, the file content will be moved to the final destination. This gives the client the flexibility to install
/// handlers when convenient.
///
@interface DBDelegate : NSObject <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

#pragma mark - Constructors

///
/// `DBDelegate` full constructor.
///
/// @note The supplied queue must be serial.
///
/// @param delegateQueue The queue used to execute handler code. By defaut, this is the main queue, so all handler code
/// will be executed on the main thread.
///
/// @return An initialized `DBDelegate` instance.
///
- (instancetype)initWithQueue:(nullable NSOperationQueue *)delegateQueue;

///
/// Enqueues a handler to be executed periodically to retrieve information on the progress of the supplied
/// `NSURLSessionTask` task for the corresponding Upload-style request.
///
/// @param task The `NSURLSessionTask` task associated with the API request.
/// @param session The `NSURLSession` session associated with the API request.
/// @param handler The progress block to be executed in the event of a request update. The first argument is the number
/// of bytes downloaded. The second argument is the number of total bytes downloaded. And the third argument is the
/// number of total bytes expected to be downloaded.
/// @param handlerQueue The operation queue on which to execute progress handler code. If nil, then the progress queue
/// is the queue with which the delegate object was instantiated.
///
- (void)addProgressHandler:(NSURLSessionTask *)task
                   session:(NSURLSession *)session
           progressHandler:(DBProgressBlock)handler
      progressHandlerQueue:(nullable NSOperationQueue *)handlerQueue;

#pragma mark - Add RPC-style handlers

///
/// Enqueues a handler to be executed upon completion of the supplied `NSURLSessionTask` task for the corresponding
/// RPC-style request.
///
/// @param task The `NSURLSessionTask` task associated with the API request.
/// @param session The `NSURLSession` session associated with the API request.
/// @param handler The handler block to be executed in the event of a successful or unsuccessful network request.
/// @param handlerQueue The operation queue on which to execute response handler code. If nil, then the response queue
/// is the queue with which the delegate object was instantiated.
///
- (void)addRpcResponseHandler:(NSURLSessionTask *)task
                      session:(NSURLSession *)session
              responseHandler:(DBRpcResponseBlockStorage)handler
         responseHandlerQueue:(nullable NSOperationQueue *)handlerQueue;

#pragma mark - Add Upload-style handlers

///
/// Enqueues a handler to be executed upon completion of the supplied `NSURLSessionTask` task for the corresponding
/// Upload-style request.
///
/// @param task The `NSURLSessionTask` task associated with the API request.
/// @param session The `NSURLSession` session associated with the API request.
/// @param handler The handler block to be executed in the event of a successful or unsuccessful network request.
/// @param handlerQueue The operation queue on which to execute response handler code. If nil, then the response queue
/// is the queue with which the delegate object was instantiated.
///
- (void)addUploadResponseHandler:(NSURLSessionTask *)task
                         session:(NSURLSession *)session
                 responseHandler:(DBUploadResponseBlockStorage)handler
            responseHandlerQueue:(nullable NSOperationQueue *)handlerQueue;

#pragma mark - Add Download-style handlers

///
/// Enqueues a handler to be executed upon completion of the supplied `NSURLSessionTask` task for the corresponding
/// Download-style request.
///
/// @param task The `NSURLSessionTask` task associated with the API request.
/// @param session The `NSURLSession` session associated with the API request.
/// @param handler The handler block to be executed in the event of a successful or unsuccessful network request.
/// @param handlerQueue The operation queue on which to execute response handler code. If nil, then the response queue
/// is the queue with which the delegate object was instantiated.
///
- (void)addDownloadResponseHandler:(NSURLSessionTask *)task
                           session:(NSURLSession *)session
                   responseHandler:(DBDownloadResponseBlockStorage)handler
              responseHandlerQueue:(nullable NSOperationQueue *)handlerQueue;

@end

NS_ASSUME_NONNULL_END
