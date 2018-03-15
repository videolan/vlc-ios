///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTasks.h"
#import "DBDelegate.h"
#import "DBGlobalErrorResponseHandler+Internal.h"
#import "DBHandlerTypes.h"
#import "DBRequestErrors.h"
#import "DBStoneBase.h"
#import "DBTransportBaseClient+Internal.h"
#import "DBTransportBaseClient.h"

#pragma mark - Base network task

@implementation DBTask : NSObject

- (instancetype)initWithRoute:(DBRoute *)route tokenUid:(NSString *)tokenUid {
  self = [super init];
  if (self) {
    _route = route;
    _queue = nil;
    _tokenUid = [tokenUid copy];
  }
  return self;
}

- (void)cancel {
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (void)suspend {
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
  ;
}

- (void)resume {
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (void)start {
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBTask *)restart {
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

@end

#pragma mark - RPC-style network task

@implementation DBRpcTask

- (DBRpcTask *)setResponseBlock:(DBRpcResponseBlockImpl)responseBlock {
#pragma unused(responseBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBRpcTask *)setResponseBlock:(DBRpcResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
#pragma unused(responseBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBRpcTask *)setProgressBlock:(DBProgressBlock)progressBlock {
#pragma unused(progressBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBRpcTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
#pragma unused(progressBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBRpcResponseBlockStorage)storageBlockWithResponseBlock:(DBRpcResponseBlockImpl)responseBlock
                                              cleanupBlock:(DBCleanupBlock)cleanupBlock {
  __weak DBRpcTask *weakSelf = self;
  DBRpcResponseBlockStorage storageBlock = ^BOOL(NSData *data, NSURLResponse *response, NSError *clientError) {
    DBRpcTask *strongSelf = weakSelf;

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)httpResponse.statusCode;
    NSDictionary *httpHeaders = httpResponse.allHeaderFields;

    DBRoute *route = strongSelf->_route;

    BOOL successful = NO;

    id result = nil;
    id routeError = nil;
    DBRequestError *networkError = [DBTransportBaseClient dBRequestErrorWithErrorData:data
                                                                          clientError:clientError
                                                                           statusCode:statusCode
                                                                          httpHeaders:httpHeaders];
    if (networkError) {
      routeError = [DBTransportBaseClient statusCodeIsRouteError:statusCode]
                       ? [DBTransportBaseClient routeErrorWithRoute:route data:data statusCode:statusCode]
                       : nil;
      [DBGlobalErrorResponseHandler executeRegisteredResponseBlocksWithRouteError:routeError
                                                                     networkError:networkError
                                                                      restartTask:strongSelf];
    } else {
      NSError *serializationError;
      result = [DBTransportBaseClient routeResultWithRoute:route data:data serializationError:&serializationError];
      if (serializationError) {
        networkError = [[DBRequestError alloc] initAsClientError:serializationError];
      } else {
        result = !route.resultType ? [DBNilObject new] : result;
        successful = YES;
      }
    }

    responseBlock(result, routeError, networkError);
    cleanupBlock();

    return successful;
  };

  return storageBlock;
}

@end

#pragma mark - Upload-style network task

@implementation DBUploadTask

- (DBUploadTask *)setResponseBlock:(DBUploadResponseBlockImpl)responseBlock {
#pragma unused(responseBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBUploadTask *)setResponseBlock:(DBUploadResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
#pragma unused(responseBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBUploadTask *)setProgressBlock:(DBProgressBlock)progressBlock {
#pragma unused(progressBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBUploadTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
#pragma unused(progressBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBUploadResponseBlockStorage)storageBlockWithResponseBlock:(DBUploadResponseBlockImpl)responseBlock
                                                 cleanupBlock:(DBCleanupBlock)cleanupBlock {
  __weak DBUploadTask *weakSelf = self;
  DBUploadResponseBlockStorage storageBlock = ^BOOL(NSData *data, NSURLResponse *response, NSError *clientError) {
    DBUploadTask *strongSelf = weakSelf;

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)httpResponse.statusCode;
    NSDictionary *httpHeaders = httpResponse.allHeaderFields;

    DBRoute *route = strongSelf->_route;

    BOOL successful = NO;

    id result = nil;
    id routeError = nil;
    DBRequestError *networkError = [DBTransportBaseClient dBRequestErrorWithErrorData:data
                                                                          clientError:clientError
                                                                           statusCode:statusCode
                                                                          httpHeaders:httpHeaders];
    if (networkError) {
      routeError = [DBTransportBaseClient statusCodeIsRouteError:statusCode]
                       ? [DBTransportBaseClient routeErrorWithRoute:route data:data statusCode:statusCode]
                       : nil;
      [DBGlobalErrorResponseHandler executeRegisteredResponseBlocksWithRouteError:routeError
                                                                     networkError:networkError
                                                                      restartTask:strongSelf];
    } else {
      NSError *serializationError;
      result = [DBTransportBaseClient routeResultWithRoute:route data:data serializationError:&serializationError];
      if (serializationError) {
        networkError = [[DBRequestError alloc] initAsClientError:serializationError];
      } else {
        result = !route.resultType ? [DBNilObject new] : result;
        successful = YES;
      }
    }

    responseBlock(result, routeError, networkError);
    cleanupBlock();

    return successful;
  };

  return storageBlock;
}

@end

#pragma mark - Download-style network task (NSURL)

@implementation DBDownloadUrlTask

- (DBDownloadUrlTask *)setResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock {
#pragma unused(responseBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadUrlTask *)setResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
#pragma unused(responseBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadUrlTask *)setProgressBlock:(DBProgressBlock)progressBlock {
#pragma unused(progressBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadUrlTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
#pragma unused(progressBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadResponseBlockStorage)storageBlockWithResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock
                                                   cleanupBlock:(DBCleanupBlock)cleanupBlock {
  __weak DBDownloadUrlTask *weakSelf = self;
  DBDownloadResponseBlockStorage storageBlock = ^BOOL(NSURL *location, NSURLResponse *response, NSError *clientError) {
    DBDownloadUrlTask *strongSelf = weakSelf;

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)httpResponse.statusCode;
    NSDictionary *httpHeaders = httpResponse.allHeaderFields;
    NSString *headerString =
        [DBTransportBaseClient caseInsensitiveLookupWithKey:@"Dropbox-API-Result" dictionary:httpHeaders];
    NSData *resultData = headerString ? [headerString dataUsingEncoding:NSUTF8StringEncoding] : nil;

    DBRoute *route = strongSelf->_route;

    BOOL successful = NO;

    id result = nil;
    id routeError = nil;
    DBRequestError *networkError = nil;
    NSURL *destination = strongSelf->_destination;

    if (clientError || !resultData || !location || !destination) {
      // error data is in response body (downloaded to output tmp file)
      NSData *errorData = location ? [NSData dataWithContentsOfFile:[location path]] : nil;
      networkError = [DBTransportBaseClient dBRequestErrorWithErrorData:errorData
                                                            clientError:clientError
                                                             statusCode:statusCode
                                                            httpHeaders:httpHeaders];
      routeError = [DBTransportBaseClient statusCodeIsRouteError:statusCode]
                       ? [DBTransportBaseClient routeErrorWithRoute:route data:errorData statusCode:statusCode]
                       : nil;
      [DBGlobalErrorResponseHandler executeRegisteredResponseBlocksWithRouteError:routeError
                                                                     networkError:networkError
                                                                      restartTask:strongSelf];
    } else {
      NSFileManager *fileManager = [NSFileManager defaultManager];
      NSString *destinationPath = [destination path];

      NSError *fileMoveErrorOverwrite;

      if (strongSelf->_overwrite && [fileManager fileExistsAtPath:destinationPath]) {
        [fileManager removeItemAtPath:destinationPath error:&fileMoveErrorOverwrite];
      }

      if (fileMoveErrorOverwrite) {
        networkError = [[DBRequestError alloc] initAsClientError:fileMoveErrorOverwrite];
      } else {
        NSError *fileMoveErrorToDestination;

        [fileManager moveItemAtPath:[location path] toPath:destinationPath error:&fileMoveErrorToDestination];

        if (fileMoveErrorToDestination) {
          networkError = [[DBRequestError alloc] initAsClientError:fileMoveErrorToDestination];
        } else {
          NSError *serializationError;
          result =
              [DBTransportBaseClient routeResultWithRoute:route data:resultData serializationError:&serializationError];
          if (serializationError) {
            networkError = [[DBRequestError alloc] initAsClientError:serializationError];
          } else {
            result = !route.resultType ? [DBNilObject new] : result;
            successful = YES;
          }
        }
      }
    }

    responseBlock(result, routeError, networkError, destination);
    cleanupBlock();

    return successful;
  };

  return storageBlock;
}

@end

#pragma mark - Download-style network task (NSData)

@implementation DBDownloadDataTask

- (DBDownloadDataTask *)setResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock {
#pragma unused(responseBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadDataTask *)setResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock
                                   queue:(NSOperationQueue *)queue {
#pragma unused(responseBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadDataTask *)setProgressBlock:(DBProgressBlock)progressBlock {
#pragma unused(progressBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadDataTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
#pragma unused(progressBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadResponseBlockStorage)storageBlockWithResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock
                                                   cleanupBlock:(DBCleanupBlock)cleanupBlock {
  __weak DBDownloadDataTask *weakSelf = self;
  DBDownloadResponseBlockStorage storageBlock = ^BOOL(NSURL *location, NSURLResponse *response, NSError *clientError) {
    DBDownloadDataTask *strongSelf = weakSelf;

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)httpResponse.statusCode;
    NSDictionary *httpHeaders = httpResponse.allHeaderFields;
    NSString *headerString =
        [DBTransportBaseClient caseInsensitiveLookupWithKey:@"Dropbox-API-Result" dictionary:httpHeaders];
    NSData *resultData = headerString ? [headerString dataUsingEncoding:NSUTF8StringEncoding] : nil;

    DBRoute *route = strongSelf->_route;

    BOOL successful = NO;

    id result = nil;
    id routeError = nil;
    DBRequestError *networkError = nil;
    NSData *downloadContent = nil;

    if (clientError || !resultData) {
      // error data is in response body (downloaded to output tmp file)
      NSData *errorData = location ? [NSData dataWithContentsOfFile:[location path]] : nil;
      networkError = [DBTransportBaseClient dBRequestErrorWithErrorData:errorData
                                                            clientError:clientError
                                                             statusCode:statusCode
                                                            httpHeaders:httpHeaders];
      routeError = [DBTransportBaseClient statusCodeIsRouteError:statusCode]
                       ? [DBTransportBaseClient routeErrorWithRoute:route data:errorData statusCode:statusCode]
                       : nil;
      [DBGlobalErrorResponseHandler executeRegisteredResponseBlocksWithRouteError:routeError
                                                                     networkError:networkError
                                                                      restartTask:strongSelf];
    } else {
      NSError *serializationError;
      result =
          [DBTransportBaseClient routeResultWithRoute:route data:resultData serializationError:&serializationError];
      if (serializationError) {
        networkError = [[DBRequestError alloc] initAsClientError:serializationError];
      } else {
        result = !route.resultType ? [DBNilObject new] : result;
        downloadContent = [NSData dataWithContentsOfFile:[location path]];
        successful = YES;
      }
    }

    responseBlock(result, routeError, networkError, downloadContent);
    cleanupBlock();

    return successful;
  };

  return storageBlock;
}

@end
