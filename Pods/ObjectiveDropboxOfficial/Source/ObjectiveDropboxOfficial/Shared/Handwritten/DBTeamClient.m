///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTeamClient.h"

#import "DBTransportDefaultClient.h"
#import "DBTransportDefaultConfig.h"
#import "DBUserClient.h"

@implementation DBTeamClient

- (instancetype)initWithAccessToken:(NSString *)accessToken {
  return [self initWithAccessToken:accessToken transportConfig:nil];
}

- (instancetype)initWithAccessToken:(NSString *)accessToken
                    transportConfig:(DBTransportDefaultConfig *)transportConfig {
  return [self initWithAccessToken:accessToken tokenUid:nil transportConfig:transportConfig];
}

- (instancetype)initWithAccessToken:(NSString *)accessToken
                           tokenUid:(NSString *)tokenUid
                    transportConfig:(DBTransportDefaultConfig *)transportConfig {
  DBTransportDefaultClient *transportClient = [[DBTransportDefaultClient alloc] initWithAccessToken:accessToken
                                                                                           tokenUid:tokenUid
                                                                                    transportConfig:transportConfig];
  return [super initWithTransportClient:transportClient];
}

- (DBUserClient *)userClientWithMemberId:(NSString *)memberId {
  return [[DBUserClient alloc] initWithAccessToken:_transportClient.accessToken
                                   transportConfig:[(DBTransportDefaultClient *)_transportClient
                                                       duplicateTransportConfigWithAsMemberId:memberId]];
}

- (void)updateAccessToken:(NSString *)accessToken {
  _transportClient.accessToken = accessToken;
}

- (NSString *)accessToken {
  return _transportClient.accessToken;
}

- (BOOL)isAuthorized {
  return _transportClient.accessToken != nil;
}

@end
