///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBHandlerTypes.h"

NS_ASSUME_NONNULL_BEGIN

///
/// Keychain class for storing OAuth tokens.
///
@interface DBSDKKeychain : NSObject

/// Stores a key / value pair in the keychain.
+ (BOOL)storeValueWithKey:(NSString *)key value:(NSString *)value;

/// Retrieves a value from the corresponding key from the keychain.
+ (nullable NSString *)retrieveTokenWithKey:(NSString *)key;

/// Retrieves all token uids from the keychain.
+ (NSArray<NSString *> *)retrieveAllTokenIds;

/// Deletes a key / value pair in the keychain.
+ (BOOL)deleteTokenWithKey:(NSString *)key;

/// Deletes all key / value pairs in the keychain.
+ (BOOL)clearAllTokens;

/// Checks if performing a v1 token migration is necessary, and if so, performs it.
+ (BOOL)checkAndPerformV1TokenMigration:(DBTokenMigrationResponseBlock)responseBlock
                                  queue:(nullable NSOperationQueue *)queue
                                 appKey:(NSString *)appKey
                              appSecret:(NSString *)appSecret;

@end

NS_ASSUME_NONNULL_END
