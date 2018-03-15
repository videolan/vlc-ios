///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBDelegate.h"
#import "DBSDKConstants.h"
#import "DBSessionData.h"

#pragma mark - Initializers

@implementation DBDelegate {
  NSOperationQueue *_delegateQueue;
  NSMutableDictionary<NSString *, DBSessionData *> *_sessionData;
}

- (instancetype)initWithQueue:(NSOperationQueue *)delegateQueue {
  self = [super init];
  if (self) {
    _delegateQueue = delegateQueue ?: [NSOperationQueue new];
    [_delegateQueue setMaxConcurrentOperationCount:1];
    _sessionData = [NSMutableDictionary new];
  }
  return self;
}

#pragma mark - Delegate protocol methods

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
  DBSessionData *sessionData = [self sessionDataWithSession:session];
  NSNumber *taskId = @(dataTask.taskIdentifier);

  if (sessionData.responsesData[taskId]) {
    [sessionData.responsesData[taskId] appendData:data];
  } else {
    sessionData.responsesData[taskId] = [NSMutableData dataWithData:data];
  }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
  DBSessionData *sessionData = [self sessionDataWithSession:session];
  NSNumber *taskId = @(task.taskIdentifier);

  if (error && [task isKindOfClass:[NSURLSessionDownloadTask class]]) {
    DBDownloadResponseBlockStorage responseHandler = sessionData.downloadHandlers[taskId];
    if (responseHandler) {
      NSOperationQueue *queueToUse = sessionData.responseHandlerQueues[taskId] ?: [NSOperationQueue mainQueue];
      [queueToUse addOperationWithBlock:^{
        responseHandler(nil, task.response, error);
      }];

      [sessionData.downloadHandlers removeObjectForKey:taskId];
      [sessionData.progressHandlers removeObjectForKey:taskId];
      [sessionData.progressData removeObjectForKey:taskId];
      [sessionData.responsesData removeObjectForKey:taskId];
      [sessionData.responseHandlerQueues removeObjectForKey:taskId];
      [sessionData.progressHandlerQueues removeObjectForKey:taskId];
    } else {
      sessionData.completionData[taskId] = [[DBCompletionData alloc] initWithCompletionData:nil
                                                                           responseMetadata:task.response
                                                                              responseError:error
                                                                                  urlOutput:nil];
    }
  } else if ([task isKindOfClass:[NSURLSessionUploadTask class]]) {
    NSMutableData *responseData = sessionData.responsesData[taskId];
    DBUploadResponseBlockStorage responseHandler = sessionData.uploadHandlers[taskId];
    if (responseHandler) {
      NSOperationQueue *queueToUse = sessionData.responseHandlerQueues[taskId] ?: [NSOperationQueue mainQueue];
      [queueToUse addOperationWithBlock:^{
        responseHandler(responseData, task.response, error);
      }];

      [sessionData.uploadHandlers removeObjectForKey:taskId];
      [sessionData.progressHandlers removeObjectForKey:taskId];
      [sessionData.progressData removeObjectForKey:taskId];
      [sessionData.responsesData removeObjectForKey:taskId];
      [sessionData.responseHandlerQueues removeObjectForKey:taskId];
      [sessionData.progressHandlerQueues removeObjectForKey:taskId];
    } else {
      sessionData.completionData[taskId] = [[DBCompletionData alloc] initWithCompletionData:responseData
                                                                           responseMetadata:task.response
                                                                              responseError:error
                                                                                  urlOutput:nil];
    }
  } else if ([task isKindOfClass:[NSURLSessionDataTask class]]) {
    NSMutableData *responseData = sessionData.responsesData[taskId];
    DBRpcResponseBlockStorage responseHandler = sessionData.rpcHandlers[taskId];
    if (responseHandler) {
      NSOperationQueue *queueToUse = sessionData.responseHandlerQueues[taskId] ?: [NSOperationQueue mainQueue];
      [queueToUse addOperationWithBlock:^{
        responseHandler(responseData, task.response, error);
      }];

      [sessionData.rpcHandlers removeObjectForKey:taskId];
      [sessionData.progressHandlers removeObjectForKey:taskId];
      [sessionData.progressData removeObjectForKey:taskId];
      [sessionData.responsesData removeObjectForKey:taskId];
      [sessionData.responseHandlerQueues removeObjectForKey:taskId];
      [sessionData.progressHandlerQueues removeObjectForKey:taskId];
    } else {
      sessionData.completionData[taskId] = [[DBCompletionData alloc] initWithCompletionData:responseData
                                                                           responseMetadata:task.response
                                                                              responseError:error
                                                                                  urlOutput:nil];
    }
  }
}

- (void)URLSession:(NSURLSession *)session
                        task:(NSURLSessionTask *)task
             didSendBodyData:(int64_t)bytesSent
              totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
  DBSessionData *sessionData = [self sessionDataWithSession:session];
  NSNumber *taskId = @(task.taskIdentifier);

  if ([task isKindOfClass:[NSURLSessionDataTask class]]) {
    DBProgressBlock progressHandler = sessionData.progressHandlers[taskId];
    if (progressHandler) {
      NSOperationQueue *queueToUse = sessionData.progressHandlerQueues[taskId] ?: [NSOperationQueue mainQueue];
      [queueToUse addOperationWithBlock:^{
        progressHandler(bytesSent, totalBytesSent, totalBytesExpectedToSend);
      }];
    } else {
      sessionData.progressData[taskId] = [[DBProgressData alloc] initWithProgressData:bytesSent
                                                                       totalCommitted:totalBytesSent
                                                                     expectedToCommit:totalBytesExpectedToSend];
    }
  }
}

- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
                 didWriteData:(int64_t)bytesWritten
            totalBytesWritten:(int64_t)totalBytesWritten
    totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
  DBSessionData *sessionData = [self sessionDataWithSession:session];
  NSNumber *taskId = @(downloadTask.taskIdentifier);

  DBProgressBlock progressHandler = sessionData.progressHandlers[taskId];
  if (progressHandler) {
    NSOperationQueue *queueToUse = sessionData.progressHandlerQueues[taskId] ?: [NSOperationQueue mainQueue];
    [queueToUse addOperationWithBlock:^{
      progressHandler(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }];
  } else {
    sessionData.progressData[taskId] = [[DBProgressData alloc] initWithProgressData:bytesWritten
                                                                     totalCommitted:totalBytesWritten
                                                                   expectedToCommit:totalBytesExpectedToWrite];
  }
}

- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
    didFinishDownloadingToURL:(NSURL *)location {
  DBSessionData *sessionData = [self sessionDataWithSession:session];
  NSNumber *taskId = @(downloadTask.taskIdentifier);

  DBDownloadResponseBlockStorage responseHandler = sessionData.downloadHandlers[taskId];

  NSError *fileError = nil;
  NSString *tmpOutputPath = [self moveFileToTempStorage:location fileError:&fileError];
  NSURL *tmpOutputUrl = fileError == nil ? [NSURL URLWithString:tmpOutputPath] : nil;

  if (responseHandler) {
    NSOperationQueue *queueToUse = sessionData.responseHandlerQueues[taskId] ?: [NSOperationQueue mainQueue];
    [queueToUse addOperationWithBlock:^{
      responseHandler(tmpOutputUrl, downloadTask.response, fileError);
    }];

    [sessionData.downloadHandlers removeObjectForKey:taskId];
    [sessionData.progressHandlers removeObjectForKey:taskId];
    [sessionData.progressData removeObjectForKey:taskId];
    [sessionData.responsesData removeObjectForKey:taskId];
    [sessionData.responseHandlerQueues removeObjectForKey:taskId];
    [sessionData.progressHandlerQueues removeObjectForKey:taskId];
  } else {
    sessionData.completionData[taskId] = [[DBCompletionData alloc] initWithCompletionData:nil
                                                                         responseMetadata:downloadTask.response
                                                                            responseError:fileError
                                                                                urlOutput:tmpOutputUrl];
  }
}

- (NSString *)moveFileToTempStorage:(NSURL *)startingLocation fileError:(NSError **)fileError {
  NSString *tmpOutputPath = nil;

  NSFileManager *fileManager = [NSFileManager defaultManager];

  NSString *tmpDirPath = NSTemporaryDirectory();
  BOOL isDir = NO;
  BOOL success = YES;

  if (![fileManager fileExistsAtPath:tmpDirPath isDirectory:&isDir]) {
    success =
        [fileManager createDirectoryAtPath:tmpDirPath withIntermediateDirectories:YES attributes:nil error:fileError];
  }

  if (success) {
    tmpOutputPath = [tmpDirPath stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
    [fileManager moveItemAtPath:[startingLocation path] toPath:tmpOutputPath error:fileError];
  }

  return tmpOutputPath;
}

- (void)addProgressHandler:(NSURLSessionTask *)task
                   session:(NSURLSession *)session
           progressHandler:(void (^)(int64_t, int64_t, int64_t))handler
      progressHandlerQueue:(NSOperationQueue *)handlerQueue {
  [_delegateQueue addOperationWithBlock:^{
    NSNumber *taskId = @(task.taskIdentifier);

    DBSessionData *sessionData = [self sessionDataWithSession:session];
    DBProgressData *progressData = sessionData.progressData[taskId];
    if (progressData) {
      NSOperationQueue *queueToUse = handlerQueue ?: [NSOperationQueue mainQueue];
      [queueToUse addOperationWithBlock:^{
        handler(progressData.committed, progressData.totalCommitted, progressData.expectedToCommit);
      }];

      [sessionData.progressData removeObjectForKey:taskId];
    } else {
      sessionData.progressHandlers[taskId] = handler;
      if (handlerQueue) {
        sessionData.progressHandlerQueues[taskId] = handlerQueue;
      }
    }
  }];
}

#pragma mark - Add RPC-style handler

- (void)addRpcResponseHandler:(NSURLSessionTask *)task
                      session:(NSURLSession *)session
              responseHandler:(DBRpcResponseBlockStorage)handler
         responseHandlerQueue:(NSOperationQueue *)handlerQueue {
  [_delegateQueue addOperationWithBlock:^{
    NSNumber *taskId = @(task.taskIdentifier);
    DBSessionData *sessionData = [self sessionDataWithSession:session];

    DBCompletionData *completionData = sessionData.completionData[taskId];
    if (completionData) {
      NSOperationQueue *queueToUse = handlerQueue ?: [NSOperationQueue mainQueue];
      [queueToUse addOperationWithBlock:^{
        handler(completionData.responseBody, completionData.responseMetadata, completionData.responseError);
      }];

      [sessionData.progressData removeObjectForKey:taskId];
      [sessionData.completionData removeObjectForKey:taskId];
      [sessionData.rpcHandlers removeObjectForKey:taskId];
      [sessionData.progressHandlers removeObjectForKey:taskId];
      [sessionData.responseHandlerQueues removeObjectForKey:taskId];
      [sessionData.progressHandlerQueues removeObjectForKey:taskId];
    } else {
      sessionData.rpcHandlers[taskId] = handler;
      if (handlerQueue) {
        sessionData.responseHandlerQueues[taskId] = handlerQueue;
      }
    }
  }];
}

#pragma mark - Add Upload-style handler

- (void)addUploadResponseHandler:(NSURLSessionTask *)task
                         session:(NSURLSession *)session
                 responseHandler:(DBUploadResponseBlockStorage)handler
            responseHandlerQueue:(NSOperationQueue *)handlerQueue {
  [_delegateQueue addOperationWithBlock:^{
    NSNumber *taskId = @(task.taskIdentifier);
    DBSessionData *sessionData = [self sessionDataWithSession:session];

    DBCompletionData *completionData = sessionData.completionData[taskId];
    if (completionData) {
      NSOperationQueue *queueToUse = handlerQueue ?: [NSOperationQueue mainQueue];
      [queueToUse addOperationWithBlock:^{
        handler(completionData.responseBody, completionData.responseMetadata, completionData.responseError);
      }];

      [sessionData.progressData removeObjectForKey:taskId];
      [sessionData.completionData removeObjectForKey:taskId];
      [sessionData.uploadHandlers removeObjectForKey:taskId];
      [sessionData.progressHandlers removeObjectForKey:taskId];
      [sessionData.responseHandlerQueues removeObjectForKey:taskId];
      [sessionData.progressHandlerQueues removeObjectForKey:taskId];
    } else {
      sessionData.uploadHandlers[taskId] = handler;
      if (handlerQueue) {
        sessionData.responseHandlerQueues[taskId] = handlerQueue;
      }
    }
  }];
}

#pragma mark - Add Download-style handler

- (void)addDownloadResponseHandler:(NSURLSessionTask *)task
                           session:(NSURLSession *)session
                   responseHandler:(DBDownloadResponseBlockStorage)handler
              responseHandlerQueue:(NSOperationQueue *)handlerQueue {
  [_delegateQueue addOperationWithBlock:^{
    NSNumber *taskId = @(task.taskIdentifier);
    DBSessionData *sessionData = [self sessionDataWithSession:session];

    DBCompletionData *completionData = sessionData.completionData[taskId];
    if (completionData) {
      NSOperationQueue *queueToUse = handlerQueue ?: [NSOperationQueue mainQueue];
      [queueToUse addOperationWithBlock:^{
        handler(completionData.urlOutput, completionData.responseMetadata, completionData.responseError);
      }];

      [sessionData.progressData removeObjectForKey:taskId];
      [sessionData.completionData removeObjectForKey:taskId];
      [sessionData.downloadHandlers removeObjectForKey:taskId];
      [sessionData.progressHandlers removeObjectForKey:taskId];
      [sessionData.responseHandlerQueues removeObjectForKey:taskId];
      [sessionData.progressHandlerQueues removeObjectForKey:taskId];
    } else {
      sessionData.downloadHandlers[taskId] = handler;
      if (handlerQueue) {
        sessionData.responseHandlerQueues[taskId] = handlerQueue;
      }
    }
  }];
}

- (NSString *)sessionIdWithSession:(NSURLSession *)session {
  return session.configuration.identifier ?: kForegroundSessionId;
}

- (DBSessionData *)sessionDataWithSession:(NSURLSession *)session {
  NSString *sessionId = [self sessionIdWithSession:session];
  if (!_sessionData[sessionId]) {
    _sessionData[sessionId] = [[DBSessionData alloc] initWithSessionId:sessionId];
  }
  return _sessionData[sessionId];
}

@end
