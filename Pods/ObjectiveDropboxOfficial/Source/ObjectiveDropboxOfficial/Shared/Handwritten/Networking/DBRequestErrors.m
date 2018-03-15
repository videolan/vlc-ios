///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBRequestErrors.h"
#import "DBAUTHAccessError.h"
#import "DBAUTHAuthError.h"
#import "DBAUTHRateLimitError.h"
#import "DBCOMMONPathRootError.h"
#import "DBOAuthManager.h"

#pragma mark - HTTP error

@implementation DBRequestHttpError

- (instancetype)init:(NSString *)requestId
          statusCode:(NSNumber *)statusCode
        errorContent:(NSString *)errorContent
         userMessage:(NSString *)userMessage {
  self = [super init];
  if (self) {
    _requestId = requestId;
    _statusCode = statusCode;
    _errorContent = errorContent;
    _userMessage = userMessage;
  }
  return self;
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : _requestId ?: @"nil",
    @"StatusCode" : _statusCode ?: @"nil",
    @"ErrorContent" : _errorContent ?: @"nil",
    @"UserMessage" : _userMessage ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxHttpError[%@];", values];
}

@end

#pragma mark - Bad Input error

@implementation DBRequestBadInputError

- (instancetype)init:(NSString *)requestId
          statusCode:(NSNumber *)statusCode
        errorContent:(NSString *)errorContent
         userMessage:(NSString *)userMessage {
  return [super init:requestId statusCode:statusCode errorContent:errorContent userMessage:userMessage];
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : self.requestId ?: @"nil",
    @"StatusCode" : self.statusCode ?: @"nil",
    @"ErrorContent" : self.errorContent ?: @"nil",
    @"UserMessage" : self.userMessage ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxBadInputError[%@];", values];
}

@end

#pragma mark - Auth error

@implementation DBRequestAuthError

- (instancetype)init:(NSString *)requestId
             statusCode:(NSNumber *)statusCode
           errorContent:(NSString *)errorContent
            userMessage:(NSString *)userMessage
    structuredAuthError:(DBAUTHAuthError *)structuredAuthError {
  self = [super init:requestId statusCode:statusCode errorContent:errorContent userMessage:userMessage];
  if (self) {
    _structuredAuthError = structuredAuthError;
  }
  return self;
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : self.requestId ?: @"nil",
    @"StatusCode" : self.statusCode ?: @"nil",
    @"ErrorContent" : self.errorContent ?: @"nil",
    @"UserMessage" : self.userMessage ?: @"nil",
    @"StructuredAuthError" : [NSString stringWithFormat:@"%@", _structuredAuthError] ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxAuthError[%@];", values];
}

@end

#pragma mark - Access error

@implementation DBRequestAccessError

- (instancetype)init:(NSString *)requestId
               statusCode:(NSNumber *)statusCode
             errorContent:(NSString *)errorContent
              userMessage:(NSString *)userMessage
    structuredAccessError:(DBAUTHAccessError *)structuredAccessError {
  self = [super init:requestId statusCode:statusCode errorContent:errorContent userMessage:userMessage];
  if (self) {
    _structuredAccessError = structuredAccessError;
  }
  return self;
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : self.requestId ?: @"nil",
    @"StatusCode" : self.statusCode ?: @"nil",
    @"ErrorContent" : self.errorContent ?: @"nil",
    @"UserMessage" : self.userMessage ?: @"nil",
    @"StructuredAccessError" : [NSString stringWithFormat:@"%@", _structuredAccessError] ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxAccessError[%@];", values];
}

@end

#pragma mark - Path Root error

@implementation DBRequestPathRootError

- (instancetype)init:(NSString *)requestId
                 statusCode:(NSNumber *)statusCode
               errorContent:(NSString *)errorContent
                userMessage:(NSString *)userMessage
    structuredPathRootError:(DBCOMMONPathRootError *)structuredPathRootError {
  self = [super init:requestId statusCode:statusCode errorContent:errorContent userMessage:userMessage];
  if (self) {
    _structuredPathRootError = structuredPathRootError;
  }
  return self;
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : self.requestId ?: @"nil",
    @"StatusCode" : self.statusCode ?: @"nil",
    @"ErrorContent" : self.errorContent ?: @"nil",
    @"UserMessage" : self.userMessage ?: @"nil",
    @"StructuredPathRootError" : [NSString stringWithFormat:@"%@", _structuredPathRootError] ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxPathRootError[%@];", values];
}

@end

#pragma mark - Rate Limit error

@implementation DBRequestRateLimitError

- (instancetype)init:(NSString *)requestId
                  statusCode:(NSNumber *)statusCode
                errorContent:(NSString *)errorContent
                 userMessage:(NSString *)userMessage
    structuredRateLimitError:(DBAUTHRateLimitError *)structuredRateLimitError
                     backoff:(NSNumber *)backoff {
  self = [super init:requestId statusCode:statusCode errorContent:errorContent userMessage:userMessage];
  if (self) {
    _structuredRateLimitError = structuredRateLimitError;
    _backoff = backoff;
  }
  return self;
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : self.requestId ?: @"nil",
    @"StatusCode" : self.statusCode ?: @"nil",
    @"ErrorContent" : self.errorContent ?: @"nil",
    @"UserMessage" : self.userMessage ?: @"nil",
    @"StructuredRateLimitError" : _structuredRateLimitError ?: @"nil",
    @"BackOff" : _backoff ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxRateLimitError[%@];", values];
}

@end

#pragma mark - Internal Server error

@implementation DBRequestInternalServerError

- (instancetype)init:(NSString *)requestId
          statusCode:(NSNumber *)statusCode
        errorContent:(NSString *)errorContent
         userMessage:(NSString *)userMessage {
  return [super init:requestId statusCode:statusCode errorContent:errorContent userMessage:userMessage];
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : self.requestId ?: @"nil",
    @"StatusCode" : self.statusCode ?: @"nil",
    @"ErrorContent" : self.errorContent ?: @"nil",
    @"UserMessage" : self.userMessage ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxInternalServerError[%@];", values];
}

@end

#pragma mark - Client error

@implementation DBRequestClientError

- (instancetype)init:(NSError *)nsError {
  self = [super init];
  if (self) {
    _nsError = nsError;
  }
  return self;
}

- (NSString *)description {
  NSDictionary *values = @{ @"NSError" : _nsError ?: @"nil" };
  return [NSString stringWithFormat:@"DropboxClientError[%@];", values];
}

@end

#pragma mark - DBRequestError generic error

@implementation DBRequestError

#pragma mark - Constructors

- (instancetype)initAsHttpError:(NSString *)requestId
                     statusCode:(NSNumber *)statusCode
                   errorContent:(NSString *)errorContent
                    userMessage:(NSString *)userMessage {
  return [self init:DBRequestErrorHttp
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
                   userMessage:userMessage
           structuredAuthError:nil
         structuredAccessError:nil
       structuredPathRootError:nil
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nil];
}

- (instancetype)initAsBadInputError:(NSString *)requestId
                         statusCode:(NSNumber *)statusCode
                       errorContent:(NSString *)errorContent
                        userMessage:(NSString *)userMessage {
  return [self init:DBRequestErrorBadInput
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
                   userMessage:userMessage
           structuredAuthError:nil
         structuredAccessError:nil
       structuredPathRootError:nil
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nil];
}

- (instancetype)initAsAuthError:(NSString *)requestId
                     statusCode:(NSNumber *)statusCode
                   errorContent:(NSString *)errorContent
                    userMessage:(NSString *)userMessage
            structuredAuthError:(DBAUTHAuthError *)structuredAuthError {
  return [self init:DBRequestErrorAuth
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
                   userMessage:userMessage
           structuredAuthError:structuredAuthError
         structuredAccessError:nil
       structuredPathRootError:nil
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nil];
}

- (instancetype)initAsAccessError:(NSString *)requestId
                       statusCode:(NSNumber *)statusCode
                     errorContent:(NSString *)errorContent
                      userMessage:(NSString *)userMessage
            structuredAccessError:(DBAUTHAccessError *)structuredAccessError {
  return [self init:DBRequestErrorAuth
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
                   userMessage:userMessage
           structuredAuthError:nil
         structuredAccessError:structuredAccessError
       structuredPathRootError:nil
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nil];
}

- (instancetype)initAsPathRootError:(NSString *)requestId
                         statusCode:(NSNumber *)statusCode
                       errorContent:(NSString *)errorContent
                        userMessage:(NSString *)userMessage
            structuredPathRootError:(DBCOMMONPathRootError *)structuredPathRootError {
  return [self init:DBRequestErrorPathRoot
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
                   userMessage:userMessage
           structuredAuthError:nil
         structuredAccessError:nil
       structuredPathRootError:structuredPathRootError
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nil];
}

- (instancetype)initAsRateLimitError:(NSString *)requestId
                          statusCode:(NSNumber *)statusCode
                        errorContent:(NSString *)errorContent
                         userMessage:(NSString *)userMessage
            structuredRateLimitError:(DBAUTHRateLimitError *)structuredRateLimitError
                             backoff:(NSNumber *)backoff {
  return [self init:DBRequestErrorRateLimit
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
                   userMessage:userMessage
           structuredAuthError:nil
         structuredAccessError:nil
       structuredPathRootError:nil
      structuredRateLimitError:structuredRateLimitError
                       backoff:backoff
                       nsError:nil];
}

- (instancetype)initAsInternalServerError:(NSString *)requestId
                               statusCode:(NSNumber *)statusCode
                             errorContent:(NSString *)errorContent
                              userMessage:(NSString *)userMessage {
  return [self init:DBRequestErrorInternalServer
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
                   userMessage:userMessage
           structuredAuthError:nil
         structuredAccessError:nil
       structuredPathRootError:nil
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nil];
}

- (instancetype)initAsClientError:(NSError *)nsError {
  return [self init:DBRequestErrorClient
                     requestId:nil
                    statusCode:nil
                  errorContent:nil
                   userMessage:nil
           structuredAuthError:nil
         structuredAccessError:nil
       structuredPathRootError:nil
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nsError];
}

- (instancetype)init:(DBRequestErrorTag)tag
                   requestId:(NSString *)requestId
                  statusCode:(NSNumber *)statusCode
                errorContent:(NSString *)errorContent
                 userMessage:(NSString *)userMessage
         structuredAuthError:(DBAUTHAuthError *)structuredAuthError
       structuredAccessError:(DBAUTHAccessError *)structuredAccessError
     structuredPathRootError:(DBCOMMONPathRootError *)structuredPathRootError
    structuredRateLimitError:(DBAUTHRateLimitError *)structuredRateLimitError
                     backoff:(NSNumber *)backoff
                     nsError:(NSError *)nsError {
  self = [super init];
  if (self) {
    _tag = tag;
    _requestId = requestId;
    _statusCode = statusCode;
    _errorContent = errorContent;
    _userMessage = userMessage;
    _structuredAuthError = structuredAuthError;
    _structuredAccessError = structuredAccessError;
    _structuredPathRootError = structuredPathRootError;
    _structuredRateLimitError = structuredRateLimitError;
    _backoff = backoff;
    _nsError = nsError;
  }
  return self;
}

#pragma mark - Tag state methods

- (BOOL)isHttpError {
  return _tag == DBRequestErrorHttp;
}

- (BOOL)isBadInputError {
  return _tag == DBRequestErrorBadInput;
}

- (BOOL)isAuthError {
  return _tag == DBRequestErrorAuth;
}

- (BOOL)isAccessError {
  return _tag == DBRequestErrorAccess;
}

- (BOOL)isPathRootError {
  return _tag == DBRequestErrorPathRoot;
}

- (BOOL)isRateLimitError {
  return _tag == DBRequestErrorRateLimit;
}

- (BOOL)isInternalServerError {
  return _tag == DBRequestErrorInternalServer;
}

- (BOOL)isClientError {
  return _tag == DBRequestErrorClient;
}

#pragma mark - Error subtype retrieval methods

- (DBRequestHttpError *)asHttpError {
  if (![self isHttpError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorHttp`, but was %@.", [self tagName]];
  }
  return [[DBRequestHttpError alloc] init:_requestId
                               statusCode:_statusCode
                             errorContent:_errorContent
                              userMessage:_userMessage];
}

- (DBRequestBadInputError *)asBadInputError {
  if (![self isBadInputError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorBadInput`, but was %@.", [self tagName]];
  }
  return [[DBRequestBadInputError alloc] init:_requestId
                                   statusCode:_statusCode
                                 errorContent:_errorContent
                                  userMessage:_userMessage];
}

- (DBRequestAuthError *)asAuthError {
  if (![self isAuthError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorAuth`, but was %@.", [self tagName]];
  }
  return [[DBRequestAuthError alloc] init:_requestId
                               statusCode:_statusCode
                             errorContent:_errorContent
                              userMessage:_userMessage
                      structuredAuthError:_structuredAuthError];
}

- (DBRequestAccessError *)asAccessError {
  if (![self isAccessError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorAccess`, but was %@.", [self tagName]];
  }
  return [[DBRequestAccessError alloc] init:_requestId
                                 statusCode:_statusCode
                               errorContent:_errorContent
                                userMessage:_userMessage
                      structuredAccessError:_structuredAccessError];
}

- (DBRequestPathRootError *)asPathRootError {
  if (![self isPathRootError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorPathRoot`, but was %@.", [self tagName]];
  }
  return [[DBRequestPathRootError alloc] init:_requestId
                                   statusCode:_statusCode
                                 errorContent:_errorContent
                                  userMessage:_userMessage
                      structuredPathRootError:_structuredPathRootError];
}

- (DBRequestRateLimitError *)asRateLimitError {
  if (![self isRateLimitError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorRateLimit`, but was %@.", [self tagName]];
  }
  return [[DBRequestRateLimitError alloc] init:_requestId
                                    statusCode:_statusCode
                                  errorContent:_errorContent
                                   userMessage:_userMessage
                      structuredRateLimitError:_structuredRateLimitError
                                       backoff:_backoff];
}

- (DBRequestInternalServerError *)asInternalServerError {
  if (![self isInternalServerError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorInternalServer`, but was %@.", [self tagName]];
  }
  return [[DBRequestInternalServerError alloc] init:_requestId
                                         statusCode:_statusCode
                                       errorContent:_errorContent
                                        userMessage:_userMessage];
}

- (DBRequestClientError *)asClientError {
  if (![self isClientError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorClient`, but was %@.", [self tagName]];
  }
  return [[DBRequestClientError alloc] init:_nsError];
}

#pragma mark - Tag name method

- (NSString *)tagName {
  switch (_tag) {
  case DBRequestErrorHttp:
    return @"DBRequestErrorHttp";
  case DBRequestErrorBadInput:
    return @"DBRequestErrorBadInput";
  case DBRequestErrorAuth:
    return @"DBRequestErrorAuth";
  case DBRequestErrorPathRoot:
    return @"DBRequestPathRoot";
  case DBRequestErrorAccess:
    return @"DBRequestErrorAccess";
  case DBRequestErrorRateLimit:
    return @"DBRequestErrorRateLimit";
  case DBRequestErrorInternalServer:
    return @"DBRequestErrorInternalServer";
  case DBRequestErrorClient:
    return @"DBRequestErrorClient";
  }

  @throw([NSException exceptionWithName:@"InvalidTagEnum" reason:@"Tag has an invalid value." userInfo:nil]);
}

#pragma mark - Description method

- (NSString *)description {
  switch (_tag) {
  case DBRequestErrorHttp:
    return [NSString stringWithFormat:@"%@", [self asHttpError]];
  case DBRequestErrorBadInput:
    return [NSString stringWithFormat:@"%@", [self asBadInputError]];
  case DBRequestErrorAuth:
    return [NSString stringWithFormat:@"%@", [self asAuthError]];
  case DBRequestErrorAccess:
    return [NSString stringWithFormat:@"%@", [self asAccessError]];
  case DBRequestErrorPathRoot:
    return [NSString stringWithFormat:@"%@", [self asPathRootError]];
  case DBRequestErrorRateLimit:
    return [NSString stringWithFormat:@"%@", [self asRateLimitError]];
  case DBRequestErrorInternalServer:
    return [NSString stringWithFormat:@"%@", [self asInternalServerError]];
  case DBRequestErrorClient:
    return [NSString stringWithFormat:@"%@", [self asClientError]];
  }

  return [NSString stringWithFormat:@"GenericDropboxError[%@];", [self tagName]];
}

@end
