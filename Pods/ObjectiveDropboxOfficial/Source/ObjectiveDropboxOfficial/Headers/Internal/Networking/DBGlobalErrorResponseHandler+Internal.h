///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBGlobalErrorResponseHandler.h"

@class DBTask;

NS_ASSUME_NONNULL_BEGIN

@interface DBGlobalErrorResponseHandler (Internal)

+ (void)executeRegisteredResponseBlocksWithRouteError:(id _Nullable)routeError
                                         networkError:(nullable DBRequestError *)networkError
                                          restartTask:(DBTask *)restartTask;

@end

NS_ASSUME_NONNULL_END
