///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBAppClient.h"
#import "DBTransportDefaultClient.h"
#import "DBTransportDefaultConfig.h"

@implementation DBAppClient

- (instancetype)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret {
  DBTransportDefaultConfig *transportConfig =
      [[DBTransportDefaultConfig alloc] initWithAppKey:appKey appSecret:appSecret];
  return [self initWithTransportConfig:transportConfig];
}

- (instancetype)initWithTransportConfig:(DBTransportDefaultConfig *)transportConfig {
  DBTransportDefaultClient *transportClient =
      [[DBTransportDefaultClient alloc] initWithAccessToken:nil tokenUid:nil transportConfig:transportConfig];
  return [super initWithTransportClient:transportClient];
}

@end
