///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBCustomDatatypes.h"
#import "DBTasksStorage.h"

@implementation DBBatchUploadData

- (instancetype)initWithFileCommitInfo:(NSDictionary<NSURL *, DBFILESCommitInfo *> *)fileUrlsToCommitInfo
                         progressBlock:(DBProgressBlock)progressBlock
                         responseBlock:(DBBatchUploadResponseBlock)responseBlock
                                 queue:(NSOperationQueue *)queue {
  self = [super init];
  if (self) {
    // we specifiy a custom queue so that the main thread is not blocked
    _queue = queue;
    [_queue setMaxConcurrentOperationCount:1];

    // we want to make sure all of our file data has been uploaded
    // before we make our final batch commit call to `/upload_session/finish_batch`,
    // but we also don't want to wait for each response before making a
    // succeeding upload call, so we used dispatch groups to wait for all upload
    // calls to return before making our final batch commit call
    _uploadGroup = dispatch_group_create();

    _fileUrlsToCommitInfo = fileUrlsToCommitInfo;
    _fileUrlsToRequestErrors = [NSMutableDictionary new];
    _finishArgs = [NSMutableArray new];

    _progressBlock = progressBlock;
    _responseBlock = responseBlock;

    _cancel = NO;

    _taskStorage = [DBTasksStorage new];
  }
  return self;
}

@end
