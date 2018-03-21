///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBUserClient.h"
#import "DBTransportDefaultClient.h"
#import "DBTransportDefaultConfig.h"

@implementation DBUserClient

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
                                                                                           tokenUid:_tokenUid
                                                                                    transportConfig:transportConfig];
  if (self = [super initWithTransportClient:transportClient]) {
    _tokenUid = tokenUid;
  }
  return self;
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
