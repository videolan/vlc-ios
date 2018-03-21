///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBTasks.h"

///
/// Task storage for upload and download tasks.
///
/// Offers a convenient, thread-safe storage option for upload and download tasks so that they can be cancelled later.
///
@interface DBTasksStorage : NSObject

///
/// Cancels all tasks stored in the object.
///
- (void)cancelAllTasks;

///
/// Adds the upload task in a thread-safe manner.
///
/// @note If `cancelAllTasks` has already been called, the task is not only not added, but it is cancelled as well.
///
/// @param task The task to add.
///
- (void)addUploadTask:(DBUploadTask *)task;

///
/// Removes the upload task in a thread-safe manner.
///
/// @param task The task to remove.
///
- (void)removeUploadTask:(DBUploadTask *)task;

///
/// Adds the download to url task in a thread-safe manner.
///
/// @note If `cancelAllTasks` has already been called, the task is not only not added, but it is cancelled as well.
///
/// @param task The task to add.
///
- (void)addDownloadUrlTask:(DBDownloadUrlTask *)task;

///
/// Removes the download to url task in a thread-safe manner.
///
/// @param task The task to remove.
///
- (void)removeDownloadUrlTask:(DBDownloadUrlTask *)task;

///
/// Adds the download to data task in a thread-safe manner.
///
/// @note If `cancelAllTasks` has already been called, the task is not only not added, but it is cancelled as well.
///
/// @param task The task to add.
///
- (void)addDownloadDataTask:(DBDownloadDataTask *)task;

///
/// Removes the download to data task in a thread-safe manner.
///
/// @param task The task to remove.
///
- (void)removeDownloadDataTask:(DBDownloadDataTask *)task;

///
/// Determine whether there are tasks in progress.
///
/// @return Whether there are tasks in progress.
///
- (BOOL)tasksInProgress;

@end
