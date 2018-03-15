///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBClientsManager.h"

@class DBOAuthManager;
@class DBTransportDefaultConfig;

NS_ASSUME_NONNULL_BEGIN

@interface DBClientsManager (Protected)

+ (void)setupWithOAuthManager:(DBOAuthManager *)oAuthManager
              transportConfig:(DBTransportDefaultConfig *)transportConfig;

+ (void)setupWithOAuthManagerTeam:(DBOAuthManager *)oAuthManager
                  transportConfig:(DBTransportDefaultConfig *)transportConfig;

+ (void)setTransportConfig:(DBTransportDefaultConfig *)transportConfig;

+ (DBTransportDefaultConfig *)transportConfig;

+ (void)setAppKey:(NSString *)appKey;

@end

NS_ASSUME_NONNULL_END
