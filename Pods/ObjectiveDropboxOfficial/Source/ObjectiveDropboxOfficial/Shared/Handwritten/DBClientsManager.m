///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBClientsManager.h"
#import "DBOAuthManager.h"
#import "DBOAuthResult.h"
#import "DBSDKKeychain.h"
#import "DBTeamClient.h"
#import "DBTransportDefaultClient.h"
#import "DBTransportDefaultConfig.h"
#import "DBUserClient.h"

@implementation DBClientsManager

static DBTransportDefaultConfig *s_currentTransportConfig;

static NSString *s_appKey;

/// An authorized client. This will be set to `nil` if unlinked.
static DBUserClient *s_authorizedClient;

static NSMutableDictionary<NSString *, DBUserClient *> *s_tokenUidToAuthorizedClients;

/// An authorized team client. This will be set to `nil` if unlinked.
static DBTeamClient *s_authorizedTeamClient;

static NSMutableDictionary<NSString *, DBTeamClient *> *s_tokenUidToAuthorizedTeamClients;

+ (void)initialize {
  if (self != [DBClientsManager class])
    return;

  s_tokenUidToAuthorizedClients = [NSMutableDictionary new];
  s_tokenUidToAuthorizedTeamClients = [NSMutableDictionary new];
}

+ (NSString *)appKey {
  return s_appKey;
}

+ (void)setAppKey:(NSString *)appKey {
  s_appKey = appKey;
}

+ (DBTransportDefaultConfig *)transportConfig {
  return s_currentTransportConfig;
}

+ (void)setTransportConfig:(DBTransportDefaultConfig *)transportConfig {
  s_currentTransportConfig = transportConfig;
}

+ (DBUserClient *)authorizedClient {
  @synchronized(self) {
    return s_authorizedClient;
  }
}

+ (void)setAuthorizedClient:(DBUserClient *)client tokenUid:(NSString *)tokenUid {
  @synchronized(self) {
    s_authorizedClient = client;
    if (client && tokenUid) {
      [[self class] addAuthorizedClient:client tokenUid:tokenUid];
    }
  }
}

+ (NSDictionary<NSString *, DBUserClient *> *)authorizedClients {
  @synchronized(self) {
    // return shallow copy
    return [NSMutableDictionary dictionaryWithDictionary:s_tokenUidToAuthorizedClients];
  }
}

+ (DBTeamClient *)authorizedTeamClient {
  @synchronized(self) {
    return s_authorizedTeamClient;
  }
}

+ (void)setAuthorizedTeamClient:(DBTeamClient *)client tokenUid:(NSString *)tokenUid {
  @synchronized(self) {
    s_authorizedTeamClient = client;
    if (client && tokenUid) {
      [[self class] addAuthorizedTeamClient:client tokenUid:tokenUid];
    }
  }
}

+ (NSDictionary<NSString *, DBTeamClient *> *)authorizedTeamClients {
  @synchronized(self) {
    // return shallow copy
    return [NSMutableDictionary dictionaryWithDictionary:s_tokenUidToAuthorizedTeamClients];
  }
}

+ (void)addAuthorizedClient:(DBUserClient *)client tokenUid:(NSString *)tokenUid {
  @synchronized(self) {
    s_tokenUidToAuthorizedClients[tokenUid] = client;
  }
}

+ (void)addAuthorizedTeamClient:(DBTeamClient *)client tokenUid:(NSString *)tokenUid {
  @synchronized(self) {
    s_tokenUidToAuthorizedTeamClients[tokenUid] = client;
  }
}

+ (void)removeAuthorizedClient:(NSString *)tokenUid {
  @synchronized(self) {
    [s_tokenUidToAuthorizedClients removeObjectForKey:tokenUid];
  }
}

+ (void)removeAuthorizedTeamClient:(NSString *)tokenUid {
  @synchronized(self) {
    [s_tokenUidToAuthorizedTeamClients removeObjectForKey:tokenUid];
  }
}

+ (void)removeAllAuthorizedClients {
  @synchronized(self) {
    [s_tokenUidToAuthorizedClients removeAllObjects];
  }
}

+ (void)removeAllAuthorizedTeamClients {
  @synchronized(self) {
    [s_tokenUidToAuthorizedTeamClients removeAllObjects];
  }
}

+ (BOOL)authorizeClientFromKeychain:(NSString *)tokenUid {
  NSAssert([DBOAuthManager sharedOAuthManager],
           @"Call the appropriate `[DBClientsManager setupWith...]` before calling this method");

  DBAccessToken *accessToken = [[DBOAuthManager sharedOAuthManager] retrieveAccessToken:tokenUid];
  if (accessToken) {
    DBUserClient *userClient = [[DBUserClient alloc] initWithAccessToken:accessToken.accessToken
                                                         transportConfig:[DBClientsManager transportConfig]];
    [DBClientsManager setAuthorizedClient:userClient tokenUid:accessToken.uid];
    return YES;
  }
  return NO;
}

+ (BOOL)authorizeTeamClientFromKeychain:(NSString *)tokenUid {
  NSAssert([DBOAuthManager sharedOAuthManager],
           @"Call the appropriate `[DBClientsManager setupWith...]` before calling this method");

  DBAccessToken *accessToken = [[DBOAuthManager sharedOAuthManager] retrieveAccessToken:tokenUid];
  if (accessToken) {
    DBTeamClient *teamClient = [[DBTeamClient alloc] initWithAccessToken:accessToken.accessToken
                                                         transportConfig:[DBClientsManager transportConfig]];
    [DBClientsManager setAuthorizedTeamClient:teamClient tokenUid:accessToken.uid];
    return YES;
  }
  return NO;
}

+ (void)setupWithOAuthManager:(DBOAuthManager *)oAuthManager
              transportConfig:(DBTransportDefaultConfig *)transportConfig {
  NSAssert(![DBOAuthManager sharedOAuthManager], @"Only call `[DBClientsManager setupWith...]` once");

  [[self class] setupHelperWithOAuthManager:oAuthManager transportConfig:transportConfig];
  [[self class] setupAuthorizedClients];
}

+ (void)setupWithOAuthManagerTeam:(DBOAuthManager *)oAuthManager
                  transportConfig:(DBTransportDefaultConfig *)transportConfig {
  NSAssert(![DBOAuthManager sharedOAuthManager], @"Only call `[DBClientsManager setupWith...]` once");

  [[self class] setupHelperWithOAuthManager:oAuthManager transportConfig:transportConfig];
  [[self class] setupAuthorizedTeamClients];
}

+ (void)setupHelperWithOAuthManager:(DBOAuthManager *)oAuthManager
                    transportConfig:(DBTransportDefaultConfig *)transportConfig {
  [DBOAuthManager setSharedOAuthManager:oAuthManager];
  [[self class] setTransportConfig:transportConfig];
  [[self class] setAppKey:transportConfig.appKey];
}

+ (void)setupAuthorizedClients {
  NSDictionary<NSString *, DBAccessToken *> *accessTokens =
      [[DBOAuthManager sharedOAuthManager] retrieveAllAccessTokens];

  if ([accessTokens count] > 0) {
    DBAccessToken *firstToken = [[accessTokens allValues] objectAtIndex:0];

    NSString *firstTokenUid = firstToken.uid;
    NSString *firstAccessToken = firstToken.accessToken;

    DBUserClient *userClient =
        [[DBUserClient alloc] initWithAccessToken:firstAccessToken transportConfig:[DBClientsManager transportConfig]];
    [DBClientsManager setAuthorizedClient:userClient tokenUid:firstTokenUid];

    for (NSString *tokenUid in accessTokens) {
      NSString *token = accessTokens[tokenUid].accessToken;
      DBUserClient *client =
          [[DBUserClient alloc] initWithAccessToken:token transportConfig:[DBClientsManager transportConfig]];
      [self addAuthorizedClient:client tokenUid:tokenUid];
    }
  }
}

+ (void)setupAuthorizedTeamClients {
  NSDictionary<NSString *, DBAccessToken *> *accessTokens =
      [[DBOAuthManager sharedOAuthManager] retrieveAllAccessTokens];

  if ([accessTokens count] > 0) {
    DBAccessToken *firstToken = [[accessTokens allValues] objectAtIndex:0];

    NSString *firstTokenUid = firstToken.uid;
    NSString *firstAccessToken = firstToken.accessToken;

    DBTeamClient *teamClient =
        [[DBTeamClient alloc] initWithAccessToken:firstAccessToken transportConfig:[DBClientsManager transportConfig]];
    [DBClientsManager setAuthorizedTeamClient:teamClient tokenUid:firstTokenUid];

    for (NSString *tokenUid in accessTokens) {
      NSString *token = accessTokens[tokenUid].accessToken;
      DBTeamClient *client =
          [[DBTeamClient alloc] initWithAccessToken:token transportConfig:[DBClientsManager transportConfig]];
      [self addAuthorizedTeamClient:client tokenUid:tokenUid];
    }
  }
}

+ (DBOAuthResult *)handleRedirectURL:(NSURL *)url {
  NSAssert([DBOAuthManager sharedOAuthManager],
           @"Call the appropriate `[DBClientsManager setupWith...]` before calling this method");

  DBOAuthResult *result = [[DBOAuthManager sharedOAuthManager] handleRedirectURL:url];

  if ([result isSuccess]) {
    NSString *accessToken = result.accessToken.accessToken;
    DBUserClient *userClient =
        [[DBUserClient alloc] initWithAccessToken:accessToken transportConfig:[DBClientsManager transportConfig]];
    [DBClientsManager setAuthorizedClient:userClient tokenUid:result.accessToken.uid];
  }

  return result;
}

+ (DBOAuthResult *)handleRedirectURLTeam:(NSURL *)url {
  NSAssert([DBOAuthManager sharedOAuthManager],
           @"Call the appropriate `[DBClientsManager setupWith...]` before calling this method");

  DBOAuthResult *result = [[DBOAuthManager sharedOAuthManager] handleRedirectURL:url];

  if ([result isSuccess]) {
    NSString *accessToken = result.accessToken.accessToken;
    DBTeamClient *teamClient =
        [[DBTeamClient alloc] initWithAccessToken:accessToken transportConfig:[DBClientsManager transportConfig]];
    [DBClientsManager setAuthorizedTeamClient:teamClient tokenUid:result.accessToken.uid];
  }

  return result;
}

+ (void)unlinkAndResetClient:(NSString *)tokenUid {
  if ([DBOAuthManager sharedOAuthManager]) {
    [[DBOAuthManager sharedOAuthManager] clearStoredAccessToken:tokenUid];
    [[self class] resetClient:tokenUid];
  }
}

+ (void)unlinkAndResetClients {
  if ([DBOAuthManager sharedOAuthManager]) {
    [[DBOAuthManager sharedOAuthManager] clearStoredAccessTokens];
    [[self class] resetClients];
  }
}

+ (void)resetClient:(NSString *)tokenUid {
  [DBClientsManager removeAuthorizedClient:tokenUid];
  [DBClientsManager removeAuthorizedTeamClient:tokenUid];

  DBAccessToken *token = [[DBOAuthManager sharedOAuthManager] retrieveAccessToken:tokenUid];
  if (token.accessToken == [DBClientsManager authorizedClient].accessToken) {
    [DBClientsManager setAuthorizedClient:nil tokenUid:nil];

    NSDictionary<NSString *, DBUserClient *> *authorizedClientsCopy = [DBClientsManager authorizedClients];

    if ([authorizedClientsCopy count] > 0) {
      NSString *firstUid = [authorizedClientsCopy allKeys][0];
      [DBClientsManager setAuthorizedClient:authorizedClientsCopy[firstUid] tokenUid:tokenUid];
    }
  }

  if (token.accessToken == [DBClientsManager authorizedTeamClient].accessToken) {
    [DBClientsManager setAuthorizedTeamClient:nil tokenUid:nil];

    NSDictionary<NSString *, DBTeamClient *> *authorizedTeamClientsCopy = [DBClientsManager authorizedTeamClients];

    if ([authorizedTeamClientsCopy count] > 0) {
      NSString *firstUid = [authorizedTeamClientsCopy allKeys][0];
      [DBClientsManager setAuthorizedTeamClient:authorizedTeamClientsCopy[firstUid] tokenUid:tokenUid];
    }
  }
}

+ (void)resetClients {
  [DBClientsManager setAuthorizedClient:nil tokenUid:nil];
  [DBClientsManager setAuthorizedTeamClient:nil tokenUid:nil];

  [DBClientsManager removeAllAuthorizedClients];
  [DBClientsManager removeAllAuthorizedTeamClients];
}

+ (BOOL)checkAndPerformV1TokenMigration:(DBTokenMigrationResponseBlock)responseBlock
                                  queue:(NSOperationQueue *)queue
                                 appKey:(NSString *)appKey
                              appSecret:(NSString *)appSecret {
  return [DBSDKKeychain checkAndPerformV1TokenMigration:responseBlock queue:queue appKey:appKey appSecret:appSecret];
}

@end
