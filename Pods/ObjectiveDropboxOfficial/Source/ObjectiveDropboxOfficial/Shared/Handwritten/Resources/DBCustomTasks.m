///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBCustomTasks.h"
#import "DBCustomDatatypes.h"
#import "DBTasksStorage.h"

@implementation DBBatchUploadTask {
  DBBatchUploadData *_uploadData;
}

- (instancetype)initWithUploadData:(DBBatchUploadData *)uploadData {
  self = [super init];
  if (self) {
    _uploadData = uploadData;
  }
  return self;
}

- (void)cancel {
  _uploadData.cancel = YES;
  [_uploadData.taskStorage cancelAllTasks];
}

- (BOOL)uploadsInProgress {
  return [_uploadData.taskStorage tasksInProgress];
}

@end
