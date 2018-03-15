///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBSessionData.h"

#pragma mark - Progress data

@implementation DBProgressData

- (instancetype)initWithProgressData:(int64_t)committed
                      totalCommitted:(int64_t)totalCommitted
                    expectedToCommit:(int64_t)expectedToCommit {
  self = [super init];
  if (self) {
    _committed = committed;
    _totalCommitted = totalCommitted;
    _expectedToCommit = expectedToCommit;
  }
  return self;
}

@end

#pragma mark - Completion data

@implementation DBCompletionData

- (instancetype)initWithCompletionData:(NSData *)responseBody
                      responseMetadata:(NSURLResponse *)responseMetadata
                         responseError:(NSError *)responseError
                             urlOutput:(NSURL *)urlOutput {
  self = [super init];
  if (self) {
    _responseBody = responseBody;
    _responseMetadata = responseMetadata;
    _responseError = responseError;
    _urlOutput = urlOutput;
  }
  return self;
}

@end

#pragma mark - Session data

@implementation DBSessionData

- (instancetype)initWithSessionId:(NSString *)sessionId {
  self = [super init];
  if (self) {
    _sessionId = sessionId;
    _responsesData = [NSMutableDictionary new];
    _progressHandlers = [NSMutableDictionary new];
    _rpcHandlers = [NSMutableDictionary new];
    _uploadHandlers = [NSMutableDictionary new];
    _downloadHandlers = [NSMutableDictionary new];
    _progressData = [NSMutableDictionary new];
    _completionData = [NSMutableDictionary new];
    _progressHandlerQueues = [NSMutableDictionary new];
    _responseHandlerQueues = [NSMutableDictionary new];
  }
  return self;
}

@end
