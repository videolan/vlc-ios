///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBOAuthResult.h"
#import "DBOAuthManager.h"

@implementation DBOAuthResult

@synthesize accessToken = _accessToken;
@synthesize errorType = _errorType;
@synthesize errorDescription = _errorDescription;

static NSDictionary<NSString *, NSNumber *> *errorTypeLookup;

#pragma mark - Constructors

+ (DBOAuthErrorType)getErrorType:(NSString *)errorDescription {
  if (!errorTypeLookup) {
    errorTypeLookup = @{
      @"unauthorized_client" : [NSNumber numberWithInt:DBAuthUnauthorizedClient],
      @"access_denied" : [NSNumber numberWithInt:DBAuthAccessDenied],
      @"unsupported_response_type" : [NSNumber numberWithInt:DBAuthUnsupportedResponseType],
      @"invalid_scope" : [NSNumber numberWithInt:DBAuthInvalidScope],
      @"server_error" : [NSNumber numberWithInt:DBAuthServerError],
      @"temporarily_unavailable" : [NSNumber numberWithInt:DBAuthTemporarilyUnavailable],
      @"" : [NSNumber numberWithInt:DBAuthUnknown],
    };
  }
  return (DBOAuthErrorType)[errorTypeLookup[errorDescription] intValue] ?: DBAuthUnknown;
}

- (instancetype)initWithSuccess:(DBAccessToken *)accessToken {
  self = [super init];
  if (self) {
    _tag = DBAuthSuccess;
    _accessToken = accessToken;
  }
  return self;
}

- (instancetype)initWithError:(NSString *)errorType errorDescription:(NSString *)errorDescription {
  self = [super init];
  if (self) {
    _tag = DBAuthError;
    _errorType = [[self class] getErrorType:errorType];
    _errorDescription = errorDescription;
  }
  return self;
}

- (instancetype)initWithCancel {
  self = [super init];
  if (self) {
    _tag = DBAuthCancel;
  }
  return self;
}

#pragma mark - Tag state methods

- (BOOL)isSuccess {
  return _tag == DBAuthSuccess;
}

- (BOOL)isError {
  return _tag == DBAuthError;
}

- (BOOL)isCancel {
  return _tag == DBAuthCancel;
}

#pragma mark - Tag name method

- (NSString *)tagName {
  switch (_tag) {
  case DBAuthSuccess:
    return @"DBAuthSuccess";
  case DBAuthError:
    return @"DBAuthError";
  case DBAuthCancel:
    return @"DBAuthCancel";
  }

  @throw([NSException exceptionWithName:@"InvalidTagEnum" reason:@"Tag has an invalid value." userInfo:nil]);
}

#pragma mark - Instance variable accessors

- (DBAccessToken *)accessToken {
  if (_tag != DBAuthSuccess) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBAuthSuccess`, but was %@.", [self tagName]];
  }
  return _accessToken;
}

- (DBOAuthErrorType)errorType {
  if (_tag != DBAuthError) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBAuthError`, but was %@.", [self tagName]];
  }
  return _errorType;
}

- (NSString *)errorDescription {
  if (_tag != DBAuthError) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBAuthError`, but was %@.", [self tagName]];
  }
  return _errorDescription;
}

#pragma mark - Description method

- (NSString *)description {
  switch (_tag) {
  case DBAuthSuccess:
    return [NSString stringWithFormat:@"Success:[Token: %@]", _accessToken.accessToken];
  case DBAuthError:
    return
        [NSString stringWithFormat:@"Error:[ErrorType: %ld ErrorDescription: %@]", (long)_errorType, _errorDescription];
  case DBAuthCancel:
    return [NSString stringWithFormat:@"Cancel:[]"];
  }

  @throw([NSException exceptionWithName:@"InvalidTagEnum" reason:@"Tag has an invalid value." userInfo:nil]);
}

@end
