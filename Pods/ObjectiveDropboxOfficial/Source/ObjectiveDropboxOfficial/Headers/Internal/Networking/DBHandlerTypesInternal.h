///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// For internal use inside the SDK.
///

#import <Foundation/Foundation.h>

@class DBRequestError;

// Storage blocks

typedef BOOL (^DBRpcResponseBlockStorage)(NSData *_Nullable, NSURLResponse *_Nullable, NSError *_Nullable);

typedef BOOL (^DBUploadResponseBlockStorage)(NSData *_Nullable, NSURLResponse *_Nullable, NSError *_Nullable);

typedef BOOL (^DBDownloadResponseBlockStorage)(NSURL *_Nullable, NSURLResponse *_Nullable, NSError *_Nullable);

// Internal implementation response blocks

typedef void (^DBRpcResponseBlockImpl)(id _Nullable, id _Nullable, DBRequestError *_Nullable);

typedef void (^DBUploadResponseBlockImpl)(id _Nullable, id _Nullable, DBRequestError *_Nullable);

typedef void (^DBDownloadUrlResponseBlockImpl)(id _Nullable, id _Nullable, DBRequestError *_Nullable, NSURL *_Nullable);

typedef void (^DBDownloadDataResponseBlockImpl)(id _Nullable, id _Nullable, DBRequestError *_Nullable,
                                                NSData *_Nullable);
typedef void (^DBCleanupBlock)(void);
