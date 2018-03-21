///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBCustomRoutes.h"
#import "DBASYNCLaunchEmptyResult.h"
#import "DBChunkInputStream.h"
#import "DBCustomDatatypes.h"
#import "DBCustomTasks.h"
#import "DBFILESCommitInfo.h"
#import "DBFILESUploadSessionCursor.h"
#import "DBFILESUploadSessionFinishArg.h"
#import "DBFILESUploadSessionFinishBatchJobStatus.h"
#import "DBFILESUploadSessionFinishBatchLaunch.h"
#import "DBFILESUploadSessionFinishBatchResult.h"
#import "DBFILESUploadSessionFinishBatchResultEntry.h"
#import "DBFILESUploadSessionLookupError.h"
#import "DBFILESUploadSessionOffsetError.h"
#import "DBFILESUploadSessionStartResult.h"
#import "DBHandlerTypes.h"
#import "DBRequestErrors.h"
#import "DBTasksImpl.h"
#import "DBTasksStorage.h"

// 10 MB file chunk size
static const NSUInteger fileChunkSize = 10 * 1024 * 1024;
static const int timeoutInSec = 200;

@implementation DBFILESUserAuthRoutes (DBCustomRoutes)

- (DBBatchUploadTask *)batchUploadFiles:(NSDictionary<NSURL *, DBFILESCommitInfo *> *)fileUrlsToCommitInfo
                                  queue:(NSOperationQueue *)queue
                          progressBlock:(DBProgressBlock)progressBlock
                          responseBlock:(DBBatchUploadResponseBlock)responseBlock {
  DBBatchUploadData *uploadData =
      [[DBBatchUploadData alloc] initWithFileCommitInfo:fileUrlsToCommitInfo
                                          progressBlock:progressBlock
                                          responseBlock:responseBlock
                                                  queue:queue ?: [NSOperationQueue mainQueue]];
  DBBatchUploadTask *uploadTask = [[DBBatchUploadTask alloc] initWithUploadData:uploadData];

  NSArray<NSURL *> *fileUrls = [fileUrlsToCommitInfo allKeys];
  NSMutableDictionary<NSURL *, NSNumber *> *fileUrlsToFileSize = [NSMutableDictionary new];

  NSUInteger totalUploadSize = 0;

  // determine total upload size for progress handler
  for (NSURL *fileUrl in fileUrls) {
    NSNumber *fileSizeObj;
    NSError *fileSizeError;
    [fileUrl getResourceValue:&fileSizeObj forKey:NSURLFileSizeKey error:&fileSizeError];

    if (fileSizeError) {
      [uploadData.queue addOperationWithBlock:^{
        uploadData.responseBlock(nil, nil, nil, @{fileUrl : [[DBRequestError alloc] initAsClientError:fileSizeError]});
      }];
      return uploadTask;
    }
    NSUInteger fileSize = [fileSizeObj unsignedIntegerValue];

    totalUploadSize += fileSize;
    fileUrlsToFileSize[fileUrl] = @(fileSize);
  }

  uploadData.totalUploadSize = totalUploadSize;

  NSOperationQueue *limitRequestsQueue = [NSOperationQueue new];
  limitRequestsQueue.maxConcurrentOperationCount = 5;

  for (NSURL *fileUrl in fileUrls) {
    NSUInteger fileSize = [fileUrlsToFileSize[fileUrl] unsignedIntegerValue];

    if (!uploadData.cancel) {
      dispatch_group_enter(uploadData.uploadGroup);

      // queue to `limitRequestsQueue` then back to main queue to make request
      [limitRequestsQueue addOperationWithBlock:^{
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        if (fileSize < fileChunkSize) {
          // file is small, so we won't chunk upload it.
          [self startUploadSmallFile:uploadData fileUrl:fileUrl fileSize:fileSize blockingSemaphore:semaphore];
        } else {
          // file is somewhat large, so we will chunk upload it, repeatedly querying
          // `/upload_session/append_v2` until the file is uploaded
          [self startUploadLargeFile:uploadData fileUrl:fileUrl fileSize:fileSize blockingSemaphore:semaphore];
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
      }];
    } else {
      break;
    }
  }

  // small or large, we query `upload_session/finish_batch` to batch commit
  // uploaded files.
  [self batchFinishUponCompletion:uploadData];

  return uploadTask;
}

- (void)startUploadSmallFile:(DBBatchUploadData *)uploadData
                     fileUrl:(NSURL *)fileUrl
                    fileSize:(NSUInteger)fileSize
           blockingSemaphore:(dispatch_semaphore_t)blockingSemaphore {
  // immediately close session after first API call
  // because file can be uploaded in one request
  __block DBUploadTask *task =
      [[[self uploadSessionStartStream:@(YES) inputStream:[NSInputStream inputStreamWithURL:fileUrl]]
          setResponseBlock:^(DBFILESUploadSessionStartResult *result, DBNilObject *routeError, DBRequestError *error) {
            if (result && !routeError) {
              NSString *sessionId = result.sessionId;
              NSNumber *offset = @(fileSize);
              DBFILESUploadSessionCursor *cursor =
                  [[DBFILESUploadSessionCursor alloc] initWithSessionId:sessionId offset:offset];
              DBFILESCommitInfo *commitInfo = uploadData.fileUrlsToCommitInfo[fileUrl];
              DBFILESUploadSessionFinishArg *finishArg =
                  [[DBFILESUploadSessionFinishArg alloc] initWithCursor:cursor commit:commitInfo];

              // store commit info for this file
              [uploadData.finishArgs addObject:finishArg];
            } else {
              uploadData.fileUrlsToRequestErrors[fileUrl] = error;
            }

            [uploadData.taskStorage removeUploadTask:task];
            dispatch_semaphore_signal(blockingSemaphore);
            dispatch_group_leave(uploadData.uploadGroup);
          }
                     queue:uploadData.queue]
          setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
#pragma unused(totalBytesWritten)
#pragma unused(totalBytesExpectedToWrite)
            [self executeProgressHandler:uploadData amountUploaded:bytesWritten];
          }];

  [uploadData.taskStorage addUploadTask:task];
}

- (void)startUploadLargeFile:(DBBatchUploadData *)uploadData
                     fileUrl:(NSURL *)fileUrl
                    fileSize:(NSUInteger)fileSize
           blockingSemaphore:(dispatch_semaphore_t)blockingSemaphore {
  NSUInteger startBytes = 0;
  NSUInteger endBytes = fileChunkSize;
  DBChunkInputStream *fileChunkInputStream =
      [[DBChunkInputStream alloc] initWithFileUrl:fileUrl startBytes:startBytes endBytes:endBytes];

  // use seperate continue upload queue so we don't block other files from
  // commencing their upload
  NSOperationQueue *chunkUploadContinueQueue = [NSOperationQueue new];

  // do not immediately close session
  __block DBUploadTask *task = [[[self uploadSessionStartStream:fileChunkInputStream]
      setResponseBlock:^(DBFILESUploadSessionStartResult *result, DBNilObject *routeError, DBRequestError *error) {
        if (result && !routeError) {
          NSString *sessionId = result.sessionId;
          [self appendRemainingFileChunks:uploadData
                                  fileUrl:fileUrl
                                 fileSize:fileSize
                                sessionId:sessionId
                        blockingSemaphore:blockingSemaphore];

          DBFILESUploadSessionCursor *cursor =
              [[DBFILESUploadSessionCursor alloc] initWithSessionId:sessionId offset:@(fileSize)];
          DBFILESCommitInfo *commitInfo = uploadData.fileUrlsToCommitInfo[fileUrl];
          DBFILESUploadSessionFinishArg *finishArg =
              [[DBFILESUploadSessionFinishArg alloc] initWithCursor:cursor commit:commitInfo];

          // Store commit info for this file
          [uploadData.finishArgs addObject:finishArg];
        } else {
          uploadData.fileUrlsToRequestErrors[fileUrl] = error;
          dispatch_semaphore_signal(blockingSemaphore);
          dispatch_group_leave(uploadData.uploadGroup);
        }

        [uploadData.taskStorage removeUploadTask:task];
      }
                 queue:chunkUploadContinueQueue]
      setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
#pragma unused(totalBytesWritten)
#pragma unused(totalBytesExpectedToWrite)
        [self executeProgressHandler:uploadData amountUploaded:bytesWritten];
      }];

  [uploadData.taskStorage addUploadTask:task];
}

- (void)appendRemainingFileChunks:(DBBatchUploadData *)uploadData
                          fileUrl:(NSURL *)fileUrl
                         fileSize:(NSUInteger)fileSize
                        sessionId:(NSString *)sessionId
                blockingSemaphore:(dispatch_semaphore_t)blockingSemaphore {
  // use seperate response queue so we don't block response thread
  // with dispatch_semaphore_t
  NSOperationQueue *chunkUploadResponseQueue = [NSOperationQueue new];

  [chunkUploadResponseQueue addOperationWithBlock:^{
    NSUInteger startBytes = fileChunkSize;
    NSUInteger endBytes = [self endBytesWithFileSize:fileSize startBytes:startBytes];
    BOOL shouldClose = endBytes == fileSize;

    DBChunkInputStream *fileChunkInputStream =
        [[DBChunkInputStream alloc] initWithFileUrl:fileUrl startBytes:startBytes endBytes:endBytes];
    DBFILESUploadSessionCursor *cursor =
        [[DBFILESUploadSessionCursor alloc] initWithSessionId:sessionId offset:@(startBytes)];

    [self appendFileChunk:uploadData
                         fileUrl:fileUrl
                        fileSize:fileSize
                       sessionId:sessionId
        chunkUploadResponseQueue:chunkUploadResponseQueue
                      retryCount:0
            fileChunkInputStream:fileChunkInputStream
                          cursor:cursor
                      startBytes:startBytes
                     shouldClose:shouldClose
               blockingSemaphore:blockingSemaphore];
  }];
}

- (void)appendFileChunk:(DBBatchUploadData *)uploadData
                     fileUrl:(NSURL *)fileUrl
                    fileSize:(NSUInteger)fileSize
                   sessionId:(NSString *)sessionId
    chunkUploadResponseQueue:(NSOperationQueue *)chunkUploadResponseQueue
                  retryCount:(int)retryCount
        fileChunkInputStream:(NSInputStream *)fileChunkInputStream
                      cursor:(DBFILESUploadSessionCursor *)cursor
                  startBytes:(NSUInteger)startBytes
                 shouldClose:(BOOL)shouldClose
           blockingSemaphore:(dispatch_semaphore_t)blockingSemaphore {
  // close session on final append call
  __block DBUploadTask *task =
      [[[self uploadSessionAppendV2Stream:cursor close:@(shouldClose) inputStream:fileChunkInputStream]
          setResponseBlock:^(DBNilObject *result, DBFILESUploadSessionLookupError *routeError, DBRequestError *error) {
            if (!result && !routeError) {
              if ([error isRateLimitError]) {
                DBRequestRateLimitError *rateLimitError = [error asRateLimitError];
                double backoffInSeconds = [rateLimitError.backoff doubleValue];
                dispatch_time_t delayTime =
                    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(backoffInSeconds * NSEC_PER_SEC));

                // retry after backoff time
                dispatch_after(delayTime, dispatch_get_main_queue(), ^(void) {
                  if (retryCount <= 3) {
                    [self appendFileChunk:uploadData
                                         fileUrl:fileUrl
                                        fileSize:fileSize
                                       sessionId:sessionId
                        chunkUploadResponseQueue:chunkUploadResponseQueue
                                      retryCount:retryCount + 1
                            fileChunkInputStream:fileChunkInputStream
                                          cursor:cursor
                                      startBytes:startBytes
                                     shouldClose:shouldClose
                               blockingSemaphore:blockingSemaphore];
                  } else {
                    uploadData.fileUrlsToRequestErrors[fileUrl] = error;
                    dispatch_semaphore_signal(blockingSemaphore);
                    dispatch_group_leave(uploadData.uploadGroup);
                  }
                });
              } else {
                uploadData.fileUrlsToRequestErrors[fileUrl] = error;
                dispatch_semaphore_signal(blockingSemaphore);
                dispatch_group_leave(uploadData.uploadGroup);
              }
            } else if (!result) {
              // if we error here, there's almost certainly a bug with the SDK
              uploadData.fileUrlsToRequestErrors[fileUrl] = error;
              dispatch_semaphore_signal(blockingSemaphore);
              dispatch_group_leave(uploadData.uploadGroup);
            } else {
              if (shouldClose || uploadData.cancel) {
                dispatch_semaphore_signal(blockingSemaphore);
                dispatch_group_leave(uploadData.uploadGroup);
                return;
              }

              NSUInteger startBytesContinue = startBytes + fileChunkSize;
              NSUInteger endBytesContinue = [self endBytesWithFileSize:fileSize startBytes:startBytesContinue];
              BOOL shouldCloseContinue = endBytesContinue == fileSize;

              DBChunkInputStream *fileChunkInputStreamContinue =
                  [[DBChunkInputStream alloc] initWithFileUrl:fileUrl
                                                   startBytes:startBytesContinue
                                                     endBytes:endBytesContinue];
              DBFILESUploadSessionCursor *cursorContinue =
                  [[DBFILESUploadSessionCursor alloc] initWithSessionId:sessionId offset:@(startBytesContinue)];

              [self appendFileChunk:uploadData
                                   fileUrl:fileUrl
                                  fileSize:fileSize
                                 sessionId:sessionId
                  chunkUploadResponseQueue:chunkUploadResponseQueue
                                retryCount:retryCount
                      fileChunkInputStream:fileChunkInputStreamContinue
                                    cursor:cursorContinue
                                startBytes:startBytesContinue
                               shouldClose:shouldCloseContinue
                         blockingSemaphore:blockingSemaphore];
            }
            [uploadData.taskStorage removeUploadTask:task];
          }
                     queue:chunkUploadResponseQueue]
          setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
#pragma unused(totalBytesWritten)
#pragma unused(totalBytesExpectedToWrite)
            if (retryCount == 0) {
              [self executeProgressHandler:uploadData amountUploaded:bytesWritten];
            }
          }];

  [uploadData.taskStorage addUploadTask:task];
}

- (void)queryJobStatus:(DBBatchUploadData *)uploadData asyncJobId:(NSString *)asyncJobId retryCount:(int)retryCount {
  [[self uploadSessionFinishBatchCheck:asyncJobId]
      setResponseBlock:^(DBFILESUploadSessionFinishBatchJobStatus *result, DBASYNCPollError *routeError,
                         DBRequestError *error) {
        if (result) {
          if ([result isInProgress]) {
            sleep(1);
            if (retryCount <= timeoutInSec) {
              [self queryJobStatus:uploadData asyncJobId:asyncJobId retryCount:retryCount + 1];
            } else {
              NSString *errorMessage =
                  [NSString stringWithFormat:@"Result polling took > %d seconds. Timing out.", timeoutInSec];
              NSMutableDictionary *userInfo = [NSMutableDictionary new];
              userInfo[NSUnderlyingErrorKey] = errorMessage;
              NSError *timeoutError =
                  [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:userInfo];
              [uploadData.queue addOperationWithBlock:^{
                uploadData.responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:timeoutError],
                                         uploadData.fileUrlsToRequestErrors);
              }];
            }
          } else if ([result isComplete]) {
            [uploadData.queue addOperationWithBlock:^{
              NSArray<DBFILESUploadSessionFinishBatchResultEntry *> *completeResult = result.complete.entries;

              // create reverse lookup
              NSMutableDictionary<NSString *, NSURL *> *dropboxFilePathToNSURL = [NSMutableDictionary new];
              for (NSURL *fileUrl in uploadData.fileUrlsToCommitInfo) {
                DBFILESCommitInfo *commitInfo = uploadData.fileUrlsToCommitInfo[fileUrl];
                dropboxFilePathToNSURL[commitInfo.path] = fileUrl;
              }

              NSMutableDictionary<NSURL *, DBFILESUploadSessionFinishBatchResultEntry *> *fileUrlsToBatchResultEntries =
                  [NSMutableDictionary new];

              int index = 0;
              for (DBFILESUploadSessionFinishArg *finishArg in uploadData.finishArgs) {
                NSString *path = finishArg.commit.path;
                DBFILESUploadSessionFinishBatchResultEntry *resultEntry = completeResult[index];
                fileUrlsToBatchResultEntries[dropboxFilePathToNSURL[path]] = resultEntry;
                index++;
              }

              uploadData.responseBlock(fileUrlsToBatchResultEntries, nil, nil, uploadData.fileUrlsToRequestErrors);
            }];
          }
        } else if (!routeError) {
          if ([error isRateLimitError]) {
            DBRequestRateLimitError *rateLimitError = [error asRateLimitError];
            double backoffInSeconds = [rateLimitError.backoff doubleValue];
            dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(backoffInSeconds * NSEC_PER_SEC));

            // retry after backoff time
            dispatch_after(delayTime, dispatch_get_main_queue(), ^(void) {
              [self queryJobStatus:uploadData asyncJobId:asyncJobId retryCount:retryCount];
            });
          } else {
            [uploadData.queue addOperationWithBlock:^{
              uploadData.responseBlock(nil, nil, error, uploadData.fileUrlsToRequestErrors);
            }];
          }
        } else {
          [uploadData.queue addOperationWithBlock:^{
            uploadData.responseBlock(nil, routeError, error, uploadData.fileUrlsToRequestErrors);
          }];
        }
      }];
}

- (NSUInteger)endBytesWithFileSize:(NSUInteger)fileSize startBytes:(NSUInteger)startBytes {
  if (startBytes + fileChunkSize < fileSize) {
    return startBytes + fileChunkSize;
  }

  return fileSize;
}

- (void)batchFinishUponCompletion:(DBBatchUploadData *)uploadData {
  // wait for all upload calls to complete and then batch "finish" all uploaded files
  // with one call to `upload_session/finish_batch`
  dispatch_group_notify(uploadData.uploadGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    if (uploadData.cancel) {
      uploadData.responseBlock(nil, nil, nil, uploadData.fileUrlsToRequestErrors);
      return;
    }

    NSMutableArray<DBFILESUploadSessionFinishArg *> *sortedFinishArgs =
        [[uploadData.finishArgs sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
          DBFILESUploadSessionFinishArg *first = (DBFILESUploadSessionFinishArg *)a;
          DBFILESUploadSessionFinishArg *second = (DBFILESUploadSessionFinishArg *)b;
          return [first.commit.path compare:second.commit.path];
        }] mutableCopy];

    uploadData.finishArgs = sortedFinishArgs;

    [[self uploadSessionFinishBatch:sortedFinishArgs]
        setResponseBlock:^(DBFILESUploadSessionFinishBatchLaunch *result, DBNilObject *routeError,
                           DBRequestError *error) {
          if (result && !routeError) {
            if ([result isAsyncJobId]) {
              sleep(1);
              [self queryJobStatus:uploadData asyncJobId:result.asyncJobId retryCount:2];
            }
          } else {
            [uploadData.queue addOperationWithBlock:^{
              uploadData.responseBlock(nil, nil, error, uploadData.fileUrlsToRequestErrors);
            }];
          }
        }];
  });
}

- (void)executeProgressHandler:(DBBatchUploadData *)uploadData amountUploaded:(int64_t)amountUploaded {
  if (!uploadData.progressBlock) {
    return;
  }

  [uploadData.queue addOperationWithBlock:^{
    uploadData.totalUploadedSoFar += (NSUInteger)amountUploaded;
    uploadData.progressBlock(amountUploaded, uploadData.totalUploadedSoFar, uploadData.totalUploadSize);
  }];
}

- (NSFileHandle *)fileHandle:(DBBatchUploadData *)uploadData fileUrl:(NSURL *)fileUrl {
  NSError *fileHandleError;
  NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:fileUrl error:&fileHandleError];

  if (fileHandleError) {
    [uploadData.queue addOperationWithBlock:^{
      uploadData.responseBlock(nil, nil, nil, @{fileUrl : [[DBRequestError alloc] initAsClientError:fileHandleError]});
    }];
    return nil;
  }

  return fileHandle;
}

@end
