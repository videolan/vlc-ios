/* Copyright (c) 2016 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
//  GTLQueryDrive.m
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   Drive API (drive/v3)
// Description:
//   Manages files in Drive including uploading, downloading, searching,
//   detecting changes, and updating sharing permissions.
// Documentation:
//   https://developers.google.com/drive/
// Classes:
//   GTLQueryDrive (34 custom class methods, 29 custom properties)

#import "GTLQueryDrive.h"

#import "GTLDriveAbout.h"
#import "GTLDriveChangeList.h"
#import "GTLDriveChannel.h"
#import "GTLDriveComment.h"
#import "GTLDriveCommentList.h"
#import "GTLDriveFile.h"
#import "GTLDriveFileList.h"
#import "GTLDriveGeneratedIds.h"
#import "GTLDrivePermission.h"
#import "GTLDrivePermissionList.h"
#import "GTLDriveReply.h"
#import "GTLDriveReplyList.h"
#import "GTLDriveRevision.h"
#import "GTLDriveRevisionList.h"
#import "GTLDriveStartPageToken.h"

@implementation GTLQueryDrive

@dynamic acknowledgeAbuse, addParents, commentId, corpus, count, emailMessage,
         fields, fileId, ignoreDefaultVisibility, includeDeleted,
         includeRemoved, keepRevisionForever, mimeType, ocrLanguage, orderBy,
         pageSize, pageToken, permissionId, q, removeParents, replyId,
         restrictToMyDrive, revisionId, sendNotificationEmail, space, spaces,
         startModifiedTime, transferOwnership, useContentAsIndexableText;

#pragma mark - "about" methods
// These create a GTLQueryDrive object.

+ (instancetype)queryForAboutGet {
  NSString *methodName = @"drive.about.get";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.expectedObjectClass = [GTLDriveAbout class];
  return query;
}

#pragma mark - "changes" methods
// These create a GTLQueryDrive object.

+ (instancetype)queryForChangesGetStartPageToken {
  NSString *methodName = @"drive.changes.getStartPageToken";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.expectedObjectClass = [GTLDriveStartPageToken class];
  return query;
}

+ (instancetype)queryForChangesListWithPageToken:(NSString *)pageToken {
  NSString *methodName = @"drive.changes.list";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.pageToken = pageToken;
  query.expectedObjectClass = [GTLDriveChangeList class];
  return query;
}

+ (instancetype)queryForChangesWatchWithObject:(GTLDriveChannel *)object
                                     pageToken:(NSString *)pageToken {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.changes.watch";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  query.pageToken = pageToken;
  query.expectedObjectClass = [GTLDriveChannel class];
  return query;
}

#pragma mark - "channels" methods
// These create a GTLQueryDrive object.

+ (instancetype)queryForChannelsStopWithObject:(GTLDriveChannel *)object {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.channels.stop";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  return query;
}

#pragma mark - "comments" methods
// These create a GTLQueryDrive object.

+ (instancetype)queryForCommentsCreateWithObject:(GTLDriveComment *)object
                                          fileId:(NSString *)fileId {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.comments.create";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  query.fileId = fileId;
  query.expectedObjectClass = [GTLDriveComment class];
  return query;
}

+ (instancetype)queryForCommentsDeleteWithFileId:(NSString *)fileId
                                       commentId:(NSString *)commentId {
  NSString *methodName = @"drive.comments.delete";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.commentId = commentId;
  return query;
}

+ (instancetype)queryForCommentsGetWithFileId:(NSString *)fileId
                                    commentId:(NSString *)commentId {
  NSString *methodName = @"drive.comments.get";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.commentId = commentId;
  query.expectedObjectClass = [GTLDriveComment class];
  return query;
}

+ (instancetype)queryForCommentsListWithFileId:(NSString *)fileId {
  NSString *methodName = @"drive.comments.list";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.expectedObjectClass = [GTLDriveCommentList class];
  return query;
}

+ (instancetype)queryForCommentsUpdateWithObject:(GTLDriveComment *)object
                                          fileId:(NSString *)fileId
                                       commentId:(NSString *)commentId {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.comments.update";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  query.fileId = fileId;
  query.commentId = commentId;
  query.expectedObjectClass = [GTLDriveComment class];
  return query;
}

#pragma mark - "files" methods
// These create a GTLQueryDrive object.

+ (instancetype)queryForFilesCopyWithObject:(GTLDriveFile *)object
                                     fileId:(NSString *)fileId {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.files.copy";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  query.fileId = fileId;
  query.expectedObjectClass = [GTLDriveFile class];
  return query;
}

+ (instancetype)queryForFilesCreateWithObject:(GTLDriveFile *)object
                             uploadParameters:(GTLUploadParameters *)uploadParametersOrNil {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.files.create";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  query.uploadParameters = uploadParametersOrNil;
  query.expectedObjectClass = [GTLDriveFile class];
  return query;
}

+ (instancetype)queryForFilesDeleteWithFileId:(NSString *)fileId {
  NSString *methodName = @"drive.files.delete";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  return query;
}

+ (instancetype)queryForFilesEmptyTrash {
  NSString *methodName = @"drive.files.emptyTrash";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  return query;
}

+ (instancetype)queryForFilesExportWithFileId:(NSString *)fileId
                                     mimeType:(NSString *)mimeType {
  NSString *methodName = @"drive.files.export";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.mimeType = mimeType;
  return query;
}

+ (instancetype)queryForFilesGenerateIds {
  NSString *methodName = @"drive.files.generateIds";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.expectedObjectClass = [GTLDriveGeneratedIds class];
  return query;
}

+ (instancetype)queryForFilesGetWithFileId:(NSString *)fileId {
  NSString *methodName = @"drive.files.get";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.expectedObjectClass = [GTLDriveFile class];
  return query;
}

+ (instancetype)queryForFilesList {
  NSString *methodName = @"drive.files.list";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.expectedObjectClass = [GTLDriveFileList class];
  return query;
}

+ (instancetype)queryForFilesUpdateWithObject:(GTLDriveFile *)object
                                       fileId:(NSString *)fileId
                             uploadParameters:(GTLUploadParameters *)uploadParametersOrNil {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.files.update";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  query.fileId = fileId;
  query.uploadParameters = uploadParametersOrNil;
  query.expectedObjectClass = [GTLDriveFile class];
  return query;
}

+ (instancetype)queryForFilesWatchWithObject:(GTLDriveChannel *)object
                                      fileId:(NSString *)fileId {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.files.watch";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  query.fileId = fileId;
  query.expectedObjectClass = [GTLDriveChannel class];
  return query;
}

#pragma mark - "permissions" methods
// These create a GTLQueryDrive object.

+ (instancetype)queryForPermissionsCreateWithObject:(GTLDrivePermission *)object
                                             fileId:(NSString *)fileId {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.permissions.create";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  query.fileId = fileId;
  query.expectedObjectClass = [GTLDrivePermission class];
  return query;
}

+ (instancetype)queryForPermissionsDeleteWithFileId:(NSString *)fileId
                                       permissionId:(NSString *)permissionId {
  NSString *methodName = @"drive.permissions.delete";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.permissionId = permissionId;
  return query;
}

+ (instancetype)queryForPermissionsGetWithFileId:(NSString *)fileId
                                    permissionId:(NSString *)permissionId {
  NSString *methodName = @"drive.permissions.get";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.permissionId = permissionId;
  query.expectedObjectClass = [GTLDrivePermission class];
  return query;
}

+ (instancetype)queryForPermissionsListWithFileId:(NSString *)fileId {
  NSString *methodName = @"drive.permissions.list";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.expectedObjectClass = [GTLDrivePermissionList class];
  return query;
}

+ (instancetype)queryForPermissionsUpdateWithObject:(GTLDrivePermission *)object
                                             fileId:(NSString *)fileId
                                       permissionId:(NSString *)permissionId {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.permissions.update";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  query.fileId = fileId;
  query.permissionId = permissionId;
  query.expectedObjectClass = [GTLDrivePermission class];
  return query;
}

#pragma mark - "replies" methods
// These create a GTLQueryDrive object.

+ (instancetype)queryForRepliesCreateWithObject:(GTLDriveReply *)object
                                         fileId:(NSString *)fileId
                                      commentId:(NSString *)commentId {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.replies.create";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  query.fileId = fileId;
  query.commentId = commentId;
  query.expectedObjectClass = [GTLDriveReply class];
  return query;
}

+ (instancetype)queryForRepliesDeleteWithFileId:(NSString *)fileId
                                      commentId:(NSString *)commentId
                                        replyId:(NSString *)replyId {
  NSString *methodName = @"drive.replies.delete";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.commentId = commentId;
  query.replyId = replyId;
  return query;
}

+ (instancetype)queryForRepliesGetWithFileId:(NSString *)fileId
                                   commentId:(NSString *)commentId
                                     replyId:(NSString *)replyId {
  NSString *methodName = @"drive.replies.get";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.commentId = commentId;
  query.replyId = replyId;
  query.expectedObjectClass = [GTLDriveReply class];
  return query;
}

+ (instancetype)queryForRepliesListWithFileId:(NSString *)fileId
                                    commentId:(NSString *)commentId {
  NSString *methodName = @"drive.replies.list";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.commentId = commentId;
  query.expectedObjectClass = [GTLDriveReplyList class];
  return query;
}

+ (instancetype)queryForRepliesUpdateWithObject:(GTLDriveReply *)object
                                         fileId:(NSString *)fileId
                                      commentId:(NSString *)commentId
                                        replyId:(NSString *)replyId {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.replies.update";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  query.fileId = fileId;
  query.commentId = commentId;
  query.replyId = replyId;
  query.expectedObjectClass = [GTLDriveReply class];
  return query;
}

#pragma mark - "revisions" methods
// These create a GTLQueryDrive object.

+ (instancetype)queryForRevisionsDeleteWithFileId:(NSString *)fileId
                                       revisionId:(NSString *)revisionId {
  NSString *methodName = @"drive.revisions.delete";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.revisionId = revisionId;
  return query;
}

+ (instancetype)queryForRevisionsGetWithFileId:(NSString *)fileId
                                    revisionId:(NSString *)revisionId {
  NSString *methodName = @"drive.revisions.get";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.revisionId = revisionId;
  query.expectedObjectClass = [GTLDriveRevision class];
  return query;
}

+ (instancetype)queryForRevisionsListWithFileId:(NSString *)fileId {
  NSString *methodName = @"drive.revisions.list";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.fileId = fileId;
  query.expectedObjectClass = [GTLDriveRevisionList class];
  return query;
}

+ (instancetype)queryForRevisionsUpdateWithObject:(GTLDriveRevision *)object
                                           fileId:(NSString *)fileId
                                       revisionId:(NSString *)revisionId {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"drive.revisions.update";
  GTLQueryDrive *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  query.fileId = fileId;
  query.revisionId = revisionId;
  query.expectedObjectClass = [GTLDriveRevision class];
  return query;
}

@end
