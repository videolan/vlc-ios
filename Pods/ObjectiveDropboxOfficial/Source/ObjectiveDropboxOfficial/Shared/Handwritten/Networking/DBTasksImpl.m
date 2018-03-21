///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTasksImpl.h"
#import "DBDelegate.h"
#import "DBHandlerTypes.h"
#import "DBRequestErrors.h"
#import "DBStoneBase.h"
#import "DBTasks+Protected.h"
#import "DBTransportBaseClient.h"

#pragma mark - RPC-style network task

@implementation DBRpcTaskImpl {
  DBRpcTaskImpl *_selfRetained;
  DBRpcResponseBlockImpl _responseBlock;
}

- (instancetype)initWithTask:(NSURLSessionDataTask *)task
                    tokenUid:(NSString *)tokenUid
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route {
  self = [super initWithRoute:route tokenUid:tokenUid];
  if (self) {
    _dataTask = task;
    _session = session;
    _delegate = delegate;
    _selfRetained = self;
  }
  return self;
}

- (void)cancel {
  [_dataTask cancel];
}

- (void)suspend {
  [_dataTask suspend];
}

- (void)resume {
  [_dataTask resume];
}

- (void)start {
  [_dataTask resume];
}

- (void)cleanup {
  _selfRetained = nil;

  NSOperationQueue *queueToUse = _queue ?: [NSOperationQueue mainQueue];
  [queueToUse addOperationWithBlock:^{
    self->_responseBlock = nil;
  }];
}

- (DBTask *)restart {
  NSURLRequest *request = [_dataTask.originalRequest copy];
  NSURLSessionDataTask *task = [_session dataTaskWithRequest:request];
  DBRpcTaskImpl *sdkTask =
      [[DBRpcTaskImpl alloc] initWithTask:task tokenUid:self.tokenUid session:_session delegate:_delegate route:_route];
  sdkTask.retryCount += 1;
  [sdkTask setResponseBlock:_responseBlock queue:_queue];
  [task resume];

  return sdkTask;
}

- (DBRpcTask *)setResponseBlock:(DBRpcResponseBlockImpl)responseBlock {
  return [self setResponseBlock:responseBlock queue:nil];
}

- (DBRpcTask *)setResponseBlock:(DBRpcResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
  _responseBlock = responseBlock;
  DBRpcResponseBlockStorage storageBlock = [self storageBlockWithResponseBlock:responseBlock
                                                                  cleanupBlock:^{
                                                                    [self cleanup];
                                                                  }];
  [_delegate addRpcResponseHandler:_dataTask session:_session responseHandler:storageBlock responseHandlerQueue:queue];
  return self;
}

- (DBRpcTask *)setProgressBlock:(DBProgressBlock)progressBlock {
  return [self setProgressBlock:progressBlock queue:nil];
}

- (DBRpcTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  [_delegate addProgressHandler:_dataTask session:_session progressHandler:progressBlock progressHandlerQueue:queue];
  return self;
}

@end

#pragma mark - Upload-style network task

@implementation DBUploadTaskImpl {
  DBUploadTaskImpl *_selfRetained;
  DBUploadResponseBlockImpl _responseBlock;
}

- (instancetype)initWithTask:(NSURLSessionUploadTask *)task
                    tokenUid:(NSString *)tokenUid
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route
                    inputUrl:(NSURL *)inputUrl
                   inputData:(NSData *)inputData {
  self = [super initWithRoute:route tokenUid:tokenUid];
  if (self) {
    _uploadTask = task;
    _session = session;
    _delegate = delegate;
    _inputUrl = inputUrl;
    _inputData = inputData;
  }
  return self;
}

- (void)cancel {
  [_uploadTask cancel];
}

- (void)suspend {
  [_uploadTask suspend];
}

- (void)resume {
  [_uploadTask resume];
}

- (void)start {
  [_uploadTask resume];
}

- (void)cleanup {
  _selfRetained = nil;

  NSOperationQueue *queueToUse = _queue ?: [NSOperationQueue mainQueue];
  [queueToUse addOperationWithBlock:^{
    self->_responseBlock = nil;
  }];
}

- (DBTask *)restart {
  NSURLRequest *request = [_uploadTask.originalRequest copy];
  NSURLSessionUploadTask *task = nil;
  self.retryCount += 1;
  if (_inputUrl) {
    task = [_session uploadTaskWithRequest:request fromFile:self->_inputUrl];
  } else if (_inputData) {
    task = [_session uploadTaskWithRequest:request fromData:self->_inputData];
  } else {
    task = [_session uploadTaskWithStreamedRequest:request];
  }

  DBUploadTaskImpl *sdkTask = [[DBUploadTaskImpl alloc] initWithTask:task
                                                            tokenUid:self.tokenUid
                                                             session:_session
                                                            delegate:_delegate
                                                               route:_route
                                                            inputUrl:_inputUrl
                                                           inputData:_inputData];
  sdkTask.retryCount += 1;
  [sdkTask setResponseBlock:_responseBlock queue:_queue];
  [sdkTask resume];

  return sdkTask;
}

- (DBUploadTask *)setResponseBlock:(DBUploadResponseBlockImpl)responseBlock {
  return [self setResponseBlock:responseBlock queue:nil];
}

- (DBUploadTask *)setResponseBlock:(DBUploadResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
  _responseBlock = responseBlock;
  DBUploadResponseBlockStorage storageBlock = [self storageBlockWithResponseBlock:responseBlock
                                                                     cleanupBlock:^{
                                                                       [self cleanup];
                                                                     }];
  [_delegate addUploadResponseHandler:_uploadTask
                              session:_session
                      responseHandler:storageBlock
                 responseHandlerQueue:queue];

  return self;
}

- (DBUploadTask *)setProgressBlock:(DBProgressBlock)progressBlock {
  return [self setProgressBlock:progressBlock queue:nil];
}

- (DBUploadTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  [_delegate addProgressHandler:_uploadTask session:_session progressHandler:progressBlock progressHandlerQueue:queue];
  return self;
}

@end

#pragma mark - Download-style network task (NSURL)

@implementation DBDownloadUrlTaskImpl {
  DBDownloadUrlTaskImpl *_selfRetained;
  DBDownloadUrlResponseBlockImpl _responseBlock;
}

- (instancetype)initWithTask:(NSURLSessionDownloadTask *)task
                    tokenUid:(NSString *)tokenUid
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route
                   overwrite:(BOOL)overwrite
                 destination:(NSURL *)destination {
  self = [super initWithRoute:route tokenUid:tokenUid];
  if (self) {
    _downloadUrlTask = task;
    _session = session;
    _delegate = delegate;
    _overwrite = overwrite;
    _destination = destination;
  }
  return self;
}

- (void)cancel {
  [_downloadUrlTask cancel];
}

- (void)suspend {
  [_downloadUrlTask suspend];
}

- (void)resume {
  [_downloadUrlTask resume];
}

- (void)start {
  [_downloadUrlTask resume];
}

- (void)cleanup {
  _selfRetained = nil;

  NSOperationQueue *queueToUse = _queue ?: [NSOperationQueue mainQueue];
  [queueToUse addOperationWithBlock:^{
    self->_responseBlock = nil;
  }];
}

- (DBTask *)restart {
  NSURLRequest *request = [_downloadUrlTask.originalRequest copy];
  NSURLSessionDownloadTask *task = [_session downloadTaskWithRequest:request];
  DBDownloadUrlTaskImpl *sdkTask = [[DBDownloadUrlTaskImpl alloc] initWithTask:task
                                                                      tokenUid:self.tokenUid
                                                                       session:_session
                                                                      delegate:_delegate
                                                                         route:_route
                                                                     overwrite:_overwrite
                                                                   destination:_destination];
  sdkTask.retryCount += 1;
  [sdkTask setResponseBlock:_responseBlock queue:_queue];
  [task resume];

  return sdkTask;
}

- (DBDownloadUrlTask *)setResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock {
  return [self setResponseBlock:responseBlock queue:nil];
}

- (DBDownloadUrlTask *)setResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
  _responseBlock = responseBlock;
  DBDownloadResponseBlockStorage storageBlock = [self storageBlockWithResponseBlock:responseBlock
                                                                       cleanupBlock:^{
                                                                         [self cleanup];
                                                                       }];
  [_delegate addDownloadResponseHandler:_downloadUrlTask
                                session:_session
                        responseHandler:storageBlock
                   responseHandlerQueue:queue];

  return self;
}

- (DBDownloadUrlTask *)setProgressBlock:(DBProgressBlock)progressBlock {
  return [self setProgressBlock:progressBlock queue:nil];
}

- (DBDownloadUrlTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  [_delegate addProgressHandler:_downloadUrlTask
                        session:_session
                progressHandler:progressBlock
           progressHandlerQueue:queue];
  return self;
}

@end

#pragma mark - Download-style network task (NSData)

@implementation DBDownloadDataTaskImpl {
  DBDownloadDataTaskImpl *_selfRetained;
  DBDownloadDataResponseBlockImpl _responseBlock;
}

- (instancetype)initWithTask:(NSURLSessionDownloadTask *)task
                    tokenUid:(NSString *)tokenUid
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route {
  self = [super initWithRoute:route tokenUid:tokenUid];
  if (self) {
    _downloadDataTask = task;
    _session = session;
    _delegate = delegate;
  }
  return self;
}

- (void)cancel {
  [_downloadDataTask cancel];
}

- (void)suspend {
  [_downloadDataTask suspend];
}

- (void)resume {
  [_downloadDataTask resume];
}

- (void)start {
  [_downloadDataTask resume];
}

- (void)cleanup {
  _selfRetained = nil;

  NSOperationQueue *queueToUse = _queue ?: [NSOperationQueue mainQueue];
  [queueToUse addOperationWithBlock:^{
    self->_responseBlock = nil;
  }];
}

- (DBTask *)restart {
  NSURLRequest *request = [_downloadDataTask.originalRequest copy];
  NSURLSessionDownloadTask *task = [_session downloadTaskWithRequest:request];
  DBDownloadDataTaskImpl *sdkTask = [[DBDownloadDataTaskImpl alloc] initWithTask:task
                                                                        tokenUid:self.tokenUid
                                                                         session:_session
                                                                        delegate:_delegate
                                                                           route:_route];
  sdkTask.retryCount += 1;
  [sdkTask setResponseBlock:_responseBlock queue:_queue];
  [task resume];

  return sdkTask;
}

- (DBDownloadDataTask *)setResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock {
  return [self setResponseBlock:responseBlock queue:nil];
}

- (DBDownloadDataTask *)setResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock
                                   queue:(NSOperationQueue *)queue {
  _responseBlock = responseBlock;
  DBDownloadResponseBlockStorage storageBlock = [self storageBlockWithResponseBlock:responseBlock
                                                                       cleanupBlock:^{
                                                                         [self cleanup];
                                                                       }];
  [_delegate addDownloadResponseHandler:_downloadDataTask
                                session:_session
                        responseHandler:storageBlock
                   responseHandlerQueue:queue];

  return self;
}

- (DBDownloadDataTask *)setProgressBlock:(DBProgressBlock)progressBlock {
  return [self setProgressBlock:progressBlock queue:nil];
}

- (DBDownloadDataTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  [_delegate addProgressHandler:_downloadDataTask
                        session:_session
                progressHandler:progressBlock
           progressHandlerQueue:queue];
  return self;
}

@end
