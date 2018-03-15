///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTasksStorage.h"
#import "DBSDKConstants.h"
#import "DBTasksImpl.h"

@interface DBTasksStorage ()

@property (nonatomic) NSMutableDictionary<NSString *, DBUploadTaskImpl *> *uploadTasks;
@property (nonatomic) NSMutableDictionary<NSString *, DBDownloadUrlTaskImpl *> *downloadUrlTasks;
@property (nonatomic) NSMutableDictionary<NSString *, DBDownloadDataTaskImpl *> *downloadDataTasks;

@property (nonatomic) BOOL cancel;

@end

@implementation DBTasksStorage

- (instancetype)init {
  self = [super init];
  if (self) {
    _uploadTasks = [NSMutableDictionary new];
    _downloadUrlTasks = [NSMutableDictionary new];
    _downloadDataTasks = [NSMutableDictionary new];
  }
  return self;
}

- (void)cancelAllTasks {
  @synchronized(self) {
    _cancel = YES;

    for (NSString *key in _uploadTasks) {
      DBUploadTaskImpl *task = _uploadTasks[key];
      [task cancel];
    }
    for (NSString *key in _downloadUrlTasks) {
      DBDownloadUrlTaskImpl *task = _downloadUrlTasks[key];
      [task cancel];
    }
    for (NSString *key in _downloadDataTasks) {
      DBDownloadDataTaskImpl *task = _downloadDataTasks[key];
      [task cancel];
    }

    [_uploadTasks removeAllObjects];
    [_downloadUrlTasks removeAllObjects];
    [_downloadDataTasks removeAllObjects];
  }
}

- (void)addUploadTask:(DBUploadTaskImpl *)task {
  @synchronized(self) {
    if (!_cancel) {
      NSString *sessionId = task.session.configuration.identifier ?: kForegroundSessionId;
      NSString *key = [NSString stringWithFormat:@"%@/%lu", sessionId, (unsigned long)task.uploadTask.taskIdentifier];
      [_uploadTasks setObject:task forKey:key];
    } else {
      [task cancel];
    }
  }
}

- (void)removeUploadTask:(DBUploadTaskImpl *)task {
  @synchronized(self) {
    NSString *sessionId = task.session.configuration.identifier ?: kForegroundSessionId;
    NSString *key = [NSString stringWithFormat:@"%@/%lu", sessionId, (unsigned long)task.uploadTask.taskIdentifier];
    [_uploadTasks removeObjectForKey:key];
  }
}

- (void)addDownloadUrlTask:(DBDownloadUrlTaskImpl *)task {
  @synchronized(self) {
    if (!_cancel) {
      NSString *sessionId = task.session.configuration.identifier ?: kForegroundSessionId;
      NSString *key =
          [NSString stringWithFormat:@"%@/%lu", sessionId, (unsigned long)task.downloadUrlTask.taskIdentifier];
      [_downloadUrlTasks setObject:task forKey:key];
    } else {
      [task cancel];
    }
  }
}

- (void)removeDownloadUrlTask:(DBDownloadUrlTaskImpl *)task {
  @synchronized(self) {
    NSString *sessionId = task.session.configuration.identifier ?: kForegroundSessionId;
    NSString *key =
        [NSString stringWithFormat:@"%@/%lu", sessionId, (unsigned long)task.downloadUrlTask.taskIdentifier];
    [_downloadUrlTasks removeObjectForKey:key];
  }
}

- (void)addDownloadDataTask:(DBDownloadDataTaskImpl *)task {
  @synchronized(self) {
    if (!_cancel) {
      NSString *sessionId = task.session.configuration.identifier ?: kForegroundSessionId;
      NSString *key =
          [NSString stringWithFormat:@"%@/%lu", sessionId, (unsigned long)task.downloadDataTask.taskIdentifier];
      [_downloadDataTasks setObject:task forKey:key];
    } else {
      [task cancel];
    }
  }
}

- (void)removeDownloadDataTask:(DBDownloadDataTaskImpl *)task {
  @synchronized(self) {
    NSString *sessionId = task.session.configuration.identifier ?: kForegroundSessionId;
    NSString *key =
        [NSString stringWithFormat:@"%@/%lu", sessionId, (unsigned long)task.downloadDataTask.taskIdentifier];
    [_downloadDataTasks removeObjectForKey:key];
  }
}

- (BOOL)tasksInProgress {
  @synchronized(self) {
    return [_uploadTasks count] > 0 || [_downloadUrlTasks count] > 0 || [_downloadDataTasks count] > 0;
  }
}

@end
