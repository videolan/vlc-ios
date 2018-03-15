///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBHandlerTypes.h"
#import "DBTasks.h"
#import "DBTasksImpl.h"

@class DBBatchUploadData;
@class DBDelegate;
@class DBRequestError;
@class DBRoute;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - RPC-style network task

@interface DBRpcTaskImpl : DBRpcTask

/// The `NSURLSessionTask` that was used to make the request.
@property (nonatomic, readonly) NSURLSessionDataTask *dataTask;

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession *session;

/// The delegate used manage handler code.
@property (nonatomic, readonly) DBDelegate *delegate;

///
/// `DBRpcTaskImpl` full constructor.
///
/// @param task The `NSURLSessionDataTask` task that initialized the network request.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param session The `NSURLSession` used to make the network request.
/// @param delegate The delegate that manages and executes response code.
/// @param route The static `DBRoute` instance associated with the route to which the request was made. Contains
/// information like route host, response type, etc.). This is used in the deserialization process.
///
/// @return An initialized instance.
///
- (instancetype)initWithTask:(NSURLSessionDataTask *)task
                    tokenUid:(nullable NSString *)tokenUid
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route;
@end

#pragma mark - Upload-style network task

@interface DBUploadTaskImpl : DBUploadTask

/// The `NSURLSessionTask` that was used to make the request.
@property (nonatomic, readonly) NSURLSessionUploadTask *uploadTask;

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession *session;

/// The delegate used manage handler code.
@property (nonatomic, readonly) DBDelegate *delegate;

/// The url to upload.
@property (nonatomic, readonly, nullable) NSURL *inputUrl;

/// The data to upload.
@property (nonatomic, readonly, nullable) NSData *inputData;

///
/// `DBUploadTask` full constructor.
///
/// @param task The `NSURLSessionDataTask` task that initialized the network request.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param session The `NSURLSession` used to make the network request.
/// @param delegate The delegate that manages and executes response code.
/// @param route The static `DBRoute` instance associated with the route to which the request was made. Contains
/// information like route host, response type, etc.). This is used in the deserialization process.
/// @param inputUrl The url to upload.
/// @param inputData The data to upload.
///
/// @return An initialized instance.
///
- (instancetype)initWithTask:(NSURLSessionUploadTask *)task
                    tokenUid:(nullable NSString *)tokenUid
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route
                    inputUrl:(nullable NSURL *)inputUrl
                   inputData:(nullable NSData *)inputData;
@end

#pragma mark - Download-style network task (NSURL)

@interface DBDownloadUrlTaskImpl : DBDownloadUrlTask

/// The `NSURLSessionTask` that was used to make the request.
@property (nonatomic, readonly) NSURLSessionDownloadTask *downloadUrlTask;

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession *session;

/// The delegate used manage handler code.
@property (nonatomic, readonly) DBDelegate *delegate;

///
/// `DBDownloadUrlTask` full constructor.
///
/// @param task The `NSURLSessionDataTask` task that initialized the network request.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param session The `NSURLSession` used to make the network request.
/// @param delegate The delegate that manages and executes response code.
/// @param route The static `DBRoute` instance associated with the route to which the request was made. Contains
/// information like route host, response type, etc.). This is used in the deserialization process.
/// @param overwrite Whether the outputted file should overwrite in the event of a name collision.
/// @param destination Location to which output content should be downloaded.
///
/// @return An initialized instance.
///
- (instancetype)initWithTask:(NSURLSessionDownloadTask *)task
                    tokenUid:(nullable NSString *)tokenUid
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route
                   overwrite:(BOOL)overwrite
                 destination:(NSURL *)destination;
@end

#pragma mark - Download-style network task (NSData)

@interface DBDownloadDataTaskImpl : DBDownloadDataTask

/// The `NSURLSessionTask` that was used to make the request.
@property (nonatomic, readonly) NSURLSessionDownloadTask *downloadDataTask;

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession *session;

/// The delegate used manage handler code.
@property (nonatomic, readonly) DBDelegate *delegate;

///
/// DBDownloadDataTask full constructor.
///
/// @param task The `NSURLSessionDataTask` task that initialized the network request.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param session The `NSURLSession` used to make the network request.
/// @param delegate The delegate that manages and executes response code.
/// @param route The static `DBRoute` instance associated with the route to which the request was made. Contains
/// information like route host, response type, etc.). This is used in the deserialization process.
///
/// @return An initialized instance.
///
- (instancetype)initWithTask:(NSURLSessionDownloadTask *)task
                    tokenUid:(nullable NSString *)tokenUid
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route;
@end

NS_ASSUME_NONNULL_END
