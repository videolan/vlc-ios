///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBGlobalErrorResponseHandler.h"
#import "DBRequestErrors.h"
#import "DBTasks.h"
#import "DBTransportBaseClient+Internal.h"
#import <objc/runtime.h>

static DBNetworkErrorResponseBlock s_networkErrorResponseBlock = nil;
static NSOperationQueue *s_networkErrorQueue;

static NSMutableDictionary<Class, DBRouteErrorResponseBlock> *_Nullable s_routeErrorToResponseBlock;
static NSMutableDictionary<Class, NSOperationQueue *> *_Nullable s_routeErrorToQueue;

@implementation DBGlobalErrorResponseHandler

+ (void)initialize {
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    s_networkErrorQueue = [NSOperationQueue mainQueue];

    s_routeErrorToResponseBlock = [NSMutableDictionary new];
    s_routeErrorToQueue = [NSMutableDictionary new];
  });
}

+ (void)registerRouteErrorResponseBlock:(DBRouteErrorResponseBlock)routeResponseBlock
                         routeErrorType:(id)routeErrorType {
  [self registerRouteErrorResponseBlock:routeResponseBlock routeErrorType:routeErrorType queue:nil];
}

+ (void)registerRouteErrorResponseBlock:(DBRouteErrorResponseBlock)routeResponseBlock
                         routeErrorType:(id)routeErrorType
                                  queue:(NSOperationQueue *)queue {
  NSOperationQueue *queueToUse = queue ?: [NSOperationQueue mainQueue];

  @synchronized([DBGlobalErrorResponseHandler class]) {
    s_routeErrorToResponseBlock[routeErrorType] = routeResponseBlock;
    s_routeErrorToQueue[routeErrorType] = queueToUse;
  }
}

+ (void)removeRouteErrorResponseBlockWithRouteErrorType:(id)routeErrorType {
  @synchronized([DBGlobalErrorResponseHandler class]) {
    [s_routeErrorToResponseBlock removeObjectForKey:routeErrorType];
    [s_routeErrorToQueue removeObjectForKey:routeErrorType];
  }
}

+ (void)registerNetworkErrorResponseBlock:(DBNetworkErrorResponseBlock)networkErrorResponseBlock {
  [self registerNetworkErrorResponseBlock:networkErrorResponseBlock queue:nil];
}

+ (void)registerNetworkErrorResponseBlock:(DBNetworkErrorResponseBlock)networkErrorResponseBlock
                                    queue:(nullable NSOperationQueue *)queue {
  NSOperationQueue *queueToUse = queue ?: [NSOperationQueue mainQueue];

  @synchronized([DBGlobalErrorResponseHandler class]) {
    s_networkErrorResponseBlock = networkErrorResponseBlock;
    if (queueToUse) {
      s_networkErrorQueue = queueToUse;
    }
  }
}

+ (void)removeNetworkErrorResponseBlock {
  @synchronized([DBGlobalErrorResponseHandler class]) {
    s_networkErrorResponseBlock = nil;
    s_networkErrorQueue = [NSOperationQueue mainQueue];
  }
}

+ (void)executeRegisteredResponseBlocksWithRouteError:(id)routeError
                                         networkError:(DBRequestError *)networkError
                                          restartTask:(DBTask *)restartTask {
  if (routeError && [s_routeErrorToResponseBlock count] > 0) {
    // execute route error block
    Class errorClass = [routeError class];
    NSDictionary<Class, id> *fieldClassToValue = [self fieldDataFromRouteError:routeError];

    @synchronized([DBGlobalErrorResponseHandler class]) {
      NSOperationQueue *queueToUse = s_routeErrorToQueue[errorClass];

      DBRouteErrorResponseBlock routeErrorBlock = s_routeErrorToResponseBlock[errorClass];

      if (routeErrorBlock) {
        [queueToUse addOperationWithBlock:^{
          routeErrorBlock(routeError, networkError, restartTask);
        }];
      }

      for (Class fieldClass in fieldClassToValue) {
        DBRouteErrorResponseBlock routeErrorBlockForField = s_routeErrorToResponseBlock[fieldClass];
        id fieldValue = fieldClassToValue[fieldClass];

        if (routeErrorBlockForField) {
          [queueToUse addOperationWithBlock:^{
            routeErrorBlockForField(fieldValue, networkError, restartTask);
          }];
        }
      }
    }
  }

  // execute network error block
  if (networkError) {
    if ([networkError isHttpError]) {
      DBRequestHttpError *httpError = [networkError asHttpError];
      // for normal route errors, we don't want to execute the catch-all network block
      if ([DBTransportBaseClient statusCodeIsRouteError:[httpError.statusCode intValue]]) {
        return;
      }
    }

    @synchronized([DBGlobalErrorResponseHandler class]) {
      DBNetworkErrorResponseBlock networkErrorBlock = s_networkErrorResponseBlock;

      if (networkErrorBlock) {
        NSOperationQueue *queueToUse = s_networkErrorQueue;

        [queueToUse addOperationWithBlock:^{
          networkErrorBlock(networkError, restartTask);
        }];
      }
    }
  }
}

+ (NSDictionary<Class, id> *)fieldDataFromRouteError:(DBRequestError *)routeError {
  Class errorClass = [routeError class];

  NSMutableDictionary<Class, id> *result = [NSMutableDictionary new];

  // from http://stackoverflow.com/questions/16861204/property-type-or-class-using-reflection
  unsigned int count;
  objc_property_t *props = class_copyPropertyList([errorClass class], &count);

  NSString *tagValue = nil;

  for (unsigned int i = 0; i < count; i++) {
    objc_property_t property = props[i];
    const char *name = property_getName(property);
    NSString *propertyName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
    if ([propertyName isEqualToString:@"tag"]) {
      tagValue = [routeError tagName];
      break;
    }
  }

  for (unsigned int i = 0; i < count; i++) {
    objc_property_t property = props[i];
    const char *name = property_getName(property);
    NSString *propertyName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];

    const char *type = property_getAttributes(property);
    NSString *typeString = [NSString stringWithCString:type encoding:NSUTF8StringEncoding];
    NSArray *attributes = [typeString componentsSeparatedByString:@","];
    NSString *typeAttribute = [attributes objectAtIndex:0];

    if ([typeAttribute hasPrefix:@"T@"]) {
      NSString *typeClassName =
          [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length] - 4)]; // turns T@"NSDate" into NSDate
      Class typeClass = NSClassFromString(typeClassName);
      if (typeClass != nil && typeClass != [NSString class]) {
        @try {
          // We want to make sure that we only access fields that correspond to the
          // correct Union tag state. This check should filter most cases, but because
          // of the imprecision of reflection, we still want the try catch block. We use
          // a string contains comparison because of the structure of property name and
          // the tag value.
          //
          // For example, for a `/files/list_folder` error, for the `path` tag, we have an SDK tag
          // type of `DBFILESListFolderErrorPath`, whose corresponding value is accessible via
          // the error's instance field called `path`. For this reason, we want to compare
          // `DBFILESListFolderErrorPath` and `path` with an insensitive string contains call.
          // Because the instance field name `path` is not tightly linked to the tag type
          // `DBFILESListFolderErrorPath`, we still want the try catch block.
          if (tagValue &&
              [tagValue rangeOfString:propertyName options:NSCaseInsensitiveSearch].location == NSNotFound) {
            continue;
          }
          id object = [routeError valueForKey:propertyName];
          result[(id)typeClass] = object;
          // recursively retrieve instance data
          NSDictionary<Class, id> *additionalData = [self fieldDataFromRouteError:object];
          [result addEntriesFromDictionary:additionalData];
        } @catch (NSException *) {
        }
      }
    }
  }
  return result;
}

@end
