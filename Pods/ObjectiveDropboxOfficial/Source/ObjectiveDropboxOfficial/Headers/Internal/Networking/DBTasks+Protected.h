///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBHandlerTypesInternal.h"
#import "DBTasks.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DBRoute;

@interface DBRpcTask (Protected)

- (DBRpcResponseBlockStorage)storageBlockWithResponseBlock:(DBRpcResponseBlockImpl)responseBlock
                                              cleanupBlock:(DBCleanupBlock)cleanupBlock;

@end

@interface DBUploadTask (Protected)

- (DBUploadResponseBlockStorage)storageBlockWithResponseBlock:(DBUploadResponseBlockImpl)responseBlock
                                                 cleanupBlock:(DBCleanupBlock)cleanupBlock;

@end

@interface DBDownloadUrlTask (Protected)

- (DBDownloadResponseBlockStorage)storageBlockWithResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock
                                                   cleanupBlock:(DBCleanupBlock)cleanupBlock;

@end

@interface DBDownloadDataTask (Protected)

- (DBDownloadResponseBlockStorage)storageBlockWithResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock
                                                   cleanupBlock:(DBCleanupBlock)cleanupBlock;

@end

NS_ASSUME_NONNULL_END
