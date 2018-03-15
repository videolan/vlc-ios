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
//  GTLQueryDrive.h
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

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLQuery.h"
#else
  #import "GTLQuery.h"
#endif

@class GTLDriveChannel;
@class GTLDriveComment;
@class GTLDriveFile;
@class GTLDrivePermission;
@class GTLDriveReply;
@class GTLDriveRevision;

@interface GTLQueryDrive : GTLQuery

//
// Parameters valid on all methods.
//

// Selector specifying which fields to include in a partial response.
@property (nonatomic, copy) NSString *fields;

//
// Method-specific parameters; see the comments below for more information.
//
@property (nonatomic, assign) BOOL acknowledgeAbuse;
@property (nonatomic, copy) NSString *addParents;
@property (nonatomic, copy) NSString *commentId;
@property (nonatomic, copy) NSString *corpus;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, copy) NSString *emailMessage;
@property (nonatomic, copy) NSString *fileId;
@property (nonatomic, assign) BOOL ignoreDefaultVisibility;
@property (nonatomic, assign) BOOL includeDeleted;
@property (nonatomic, assign) BOOL includeRemoved;
@property (nonatomic, assign) BOOL keepRevisionForever;
@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic, copy) NSString *ocrLanguage;
@property (nonatomic, copy) NSString *orderBy;
@property (nonatomic, assign) NSInteger pageSize;
@property (nonatomic, copy) NSString *pageToken;
@property (nonatomic, copy) NSString *permissionId;
@property (nonatomic, copy) NSString *q;
@property (nonatomic, copy) NSString *removeParents;
@property (nonatomic, copy) NSString *replyId;
@property (nonatomic, assign) BOOL restrictToMyDrive;
@property (nonatomic, copy) NSString *revisionId;
@property (nonatomic, assign) BOOL sendNotificationEmail;
@property (nonatomic, copy) NSString *space;
@property (nonatomic, copy) NSString *spaces;
@property (nonatomic, copy) NSString *startModifiedTime;
@property (nonatomic, assign) BOOL transferOwnership;
@property (nonatomic, assign) BOOL useContentAsIndexableText;

#pragma mark - "about" methods
// These create a GTLQueryDrive object.

// Method: drive.about.get
// Gets information about the user, the user's Drive, and system capabilities.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveMetadataReadonly
//   kGTLAuthScopeDrivePhotosReadonly
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveAbout.
+ (instancetype)queryForAboutGet;

#pragma mark - "changes" methods
// These create a GTLQueryDrive object.

// Method: drive.changes.getStartPageToken
// Gets the starting pageToken for listing future changes.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveMetadataReadonly
//   kGTLAuthScopeDrivePhotosReadonly
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveStartPageToken.
+ (instancetype)queryForChangesGetStartPageToken;

// Method: drive.changes.list
// Lists changes for a user.
//  Required:
//   pageToken: The token for continuing a previous list request on the next
//     page. This should be set to the value of 'nextPageToken' from the
//     previous response or to the response from the getStartPageToken method.
//  Optional:
//   includeRemoved: Whether to include changes indicating that items have left
//     the view of the changes list, for example by deletion or lost access.
//     (Default true)
//   pageSize: The maximum number of changes to return per page. (1..1000,
//     default 100)
//   restrictToMyDrive: Whether to restrict the results to changes inside the My
//     Drive hierarchy. This omits changes to files such as those in the
//     Application Data folder or shared files which have not been added to My
//     Drive. (Default false)
//   spaces: A comma-separated list of spaces to query within the user corpus.
//     Supported values are 'drive', 'appDataFolder' and 'photos'. (Default
//     drive)
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveMetadataReadonly
//   kGTLAuthScopeDrivePhotosReadonly
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveChangeList.
+ (instancetype)queryForChangesListWithPageToken:(NSString *)pageToken;

// Method: drive.changes.watch
// Subscribes to changes for a user.
//  Required:
//   pageToken: The token for continuing a previous list request on the next
//     page. This should be set to the value of 'nextPageToken' from the
//     previous response or to the response from the getStartPageToken method.
//  Optional:
//   includeRemoved: Whether to include changes indicating that items have left
//     the view of the changes list, for example by deletion or lost access.
//     (Default true)
//   pageSize: The maximum number of changes to return per page. (1..1000,
//     default 100)
//   restrictToMyDrive: Whether to restrict the results to changes inside the My
//     Drive hierarchy. This omits changes to files such as those in the
//     Application Data folder or shared files which have not been added to My
//     Drive. (Default false)
//   spaces: A comma-separated list of spaces to query within the user corpus.
//     Supported values are 'drive', 'appDataFolder' and 'photos'. (Default
//     drive)
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveMetadataReadonly
//   kGTLAuthScopeDrivePhotosReadonly
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveChannel.
+ (instancetype)queryForChangesWatchWithObject:(GTLDriveChannel *)object
                                     pageToken:(NSString *)pageToken;

#pragma mark - "channels" methods
// These create a GTLQueryDrive object.

// Method: drive.channels.stop
// Stop watching resources through this channel
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveMetadataReadonly
//   kGTLAuthScopeDrivePhotosReadonly
//   kGTLAuthScopeDriveReadonly
+ (instancetype)queryForChannelsStopWithObject:(GTLDriveChannel *)object;

#pragma mark - "comments" methods
// These create a GTLQueryDrive object.

// Method: drive.comments.create
// Creates a new comment on a file.
//  Required:
//   fileId: The ID of the file.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
// Fetches a GTLDriveComment.
+ (instancetype)queryForCommentsCreateWithObject:(GTLDriveComment *)object
                                          fileId:(NSString *)fileId;

// Method: drive.comments.delete
// Deletes a comment.
//  Required:
//   fileId: The ID of the file.
//   commentId: The ID of the comment.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
+ (instancetype)queryForCommentsDeleteWithFileId:(NSString *)fileId
                                       commentId:(NSString *)commentId;

// Method: drive.comments.get
// Gets a comment by ID.
//  Required:
//   fileId: The ID of the file.
//   commentId: The ID of the comment.
//  Optional:
//   includeDeleted: Whether to return deleted comments. Deleted comments will
//     not include their original content. (Default false)
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveComment.
+ (instancetype)queryForCommentsGetWithFileId:(NSString *)fileId
                                    commentId:(NSString *)commentId;

// Method: drive.comments.list
// Lists a file's comments.
//  Required:
//   fileId: The ID of the file.
//  Optional:
//   includeDeleted: Whether to include deleted comments. Deleted comments will
//     not include their original content. (Default false)
//   pageSize: The maximum number of comments to return per page. (1..100,
//     default 20)
//   pageToken: The token for continuing a previous list request on the next
//     page. This should be set to the value of 'nextPageToken' from the
//     previous response.
//   startModifiedTime: The minimum value of 'modifiedTime' for the result
//     comments (RFC 3339 date-time).
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveCommentList.
+ (instancetype)queryForCommentsListWithFileId:(NSString *)fileId;

// Method: drive.comments.update
// Updates a comment with patch semantics.
//  Required:
//   fileId: The ID of the file.
//   commentId: The ID of the comment.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
// Fetches a GTLDriveComment.
+ (instancetype)queryForCommentsUpdateWithObject:(GTLDriveComment *)object
                                          fileId:(NSString *)fileId
                                       commentId:(NSString *)commentId;

#pragma mark - "files" methods
// These create a GTLQueryDrive object.

// Method: drive.files.copy
// Creates a copy of a file and applies any requested updates with patch
// semantics.
//  Required:
//   fileId: The ID of the file.
//  Optional:
//   ignoreDefaultVisibility: Whether to ignore the domain's default visibility
//     settings for the created file. Domain administrators can choose to make
//     all uploaded files visible to the domain by default; this parameter
//     bypasses that behavior for the request. Permissions are still inherited
//     from parent folders. (Default false)
//   keepRevisionForever: Whether to set the 'keepForever' field in the new head
//     revision. This is only applicable to files with binary content in Drive.
//     (Default false)
//   ocrLanguage: A language hint for OCR processing during image import (ISO
//     639-1 code).
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDrivePhotosReadonly
// Fetches a GTLDriveFile.
+ (instancetype)queryForFilesCopyWithObject:(GTLDriveFile *)object
                                     fileId:(NSString *)fileId;

// Method: drive.files.create
// Creates a new file.
//  Optional:
//   ignoreDefaultVisibility: Whether to ignore the domain's default visibility
//     settings for the created file. Domain administrators can choose to make
//     all uploaded files visible to the domain by default; this parameter
//     bypasses that behavior for the request. Permissions are still inherited
//     from parent folders. (Default false)
//   keepRevisionForever: Whether to set the 'keepForever' field in the new head
//     revision. This is only applicable to files with binary content in Drive.
//     (Default false)
//   ocrLanguage: A language hint for OCR processing during image import (ISO
//     639-1 code).
//   useContentAsIndexableText: Whether to use the uploaded content as indexable
//     text. (Default false)
//  Upload Parameters:
//   Maximum size: 5120GB
//   Accepted MIME type(s): */*
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
// Fetches a GTLDriveFile.
+ (instancetype)queryForFilesCreateWithObject:(GTLDriveFile *)object
                             uploadParameters:(GTLUploadParameters *)uploadParametersOrNil;

// Method: drive.files.delete
// Permanently deletes a file owned by the user without moving it to the trash.
// If the target is a folder, all descendants owned by the user are also
// deleted.
//  Required:
//   fileId: The ID of the file.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
+ (instancetype)queryForFilesDeleteWithFileId:(NSString *)fileId;

// Method: drive.files.emptyTrash
// Permanently deletes all of the user's trashed files.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
+ (instancetype)queryForFilesEmptyTrash;

// Method: drive.files.export
// Exports a Google Doc to the requested MIME type and returns the exported
// content.
//  Required:
//   fileId: The ID of the file.
//   mimeType: The MIME type of the format requested for this export.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveReadonly
+ (instancetype)queryForFilesExportWithFileId:(NSString *)fileId
                                     mimeType:(NSString *)mimeType;

// Method: drive.files.generateIds
// Generates a set of file IDs which can be provided in create requests.
//  Optional:
//   count: The number of IDs to return. (1..1000, default 10)
//   space: The space in which the IDs can be used to create new files.
//     Supported values are 'drive' and 'appDataFolder'. (Default drive)
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
// Fetches a GTLDriveGeneratedIds.
+ (instancetype)queryForFilesGenerateIds;

// Method: drive.files.get
// Gets a file's metadata or content by ID.
//  Required:
//   fileId: The ID of the file.
//  Optional:
//   acknowledgeAbuse: Whether the user is acknowledging the risk of downloading
//     known malware or other abusive files. This is only applicable when
//     alt=media. (Default false)
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveMetadataReadonly
//   kGTLAuthScopeDrivePhotosReadonly
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveFile.
+ (instancetype)queryForFilesGetWithFileId:(NSString *)fileId;

// Method: drive.files.list
// Lists or searches files.
//  Optional:
//   corpus: The source of files to list. (Default kGTLDriveCorpusUser)
//      kGTLDriveCorpusDomain: Files shared to the user's domain.
//      kGTLDriveCorpusUser: Files owned by or shared to the user.
//   orderBy: A comma-separated list of sort keys. Valid keys are 'createdTime',
//     'folder', 'modifiedByMeTime', 'modifiedTime', 'name', 'quotaBytesUsed',
//     'recency', 'sharedWithMeTime', 'starred', and 'viewedByMeTime'. Each key
//     sorts ascending by default, but may be reversed with the 'desc' modifier.
//     Example usage: ?orderBy=folder,modifiedTime desc,name. Please note that
//     there is a current limitation for users with approximately one million
//     files in which the requested sort order is ignored.
//   pageSize: The maximum number of files to return per page. (1..1000, default
//     100)
//   pageToken: The token for continuing a previous list request on the next
//     page. This should be set to the value of 'nextPageToken' from the
//     previous response.
//   q: A query for filtering the file results. See the "Search for Files" guide
//     for supported syntax.
//   spaces: A comma-separated list of spaces to query within the corpus.
//     Supported values are 'drive', 'appDataFolder' and 'photos'. (Default
//     drive)
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveMetadataReadonly
//   kGTLAuthScopeDrivePhotosReadonly
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveFileList.
+ (instancetype)queryForFilesList;

// Method: drive.files.update
// Updates a file's metadata and/or content with patch semantics.
//  Required:
//   fileId: The ID of the file.
//  Optional:
//   addParents: A comma-separated list of parent IDs to add.
//   keepRevisionForever: Whether to set the 'keepForever' field in the new head
//     revision. This is only applicable to files with binary content in Drive.
//     (Default false)
//   ocrLanguage: A language hint for OCR processing during image import (ISO
//     639-1 code).
//   removeParents: A comma-separated list of parent IDs to remove.
//   useContentAsIndexableText: Whether to use the uploaded content as indexable
//     text. (Default false)
//  Upload Parameters:
//   Maximum size: 5120GB
//   Accepted MIME type(s): */*
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveScripts
// Fetches a GTLDriveFile.
+ (instancetype)queryForFilesUpdateWithObject:(GTLDriveFile *)object
                                       fileId:(NSString *)fileId
                             uploadParameters:(GTLUploadParameters *)uploadParametersOrNil;

// Method: drive.files.watch
// Subscribes to changes to a file
//  Required:
//   fileId: The ID of the file.
//  Optional:
//   acknowledgeAbuse: Whether the user is acknowledging the risk of downloading
//     known malware or other abusive files. This is only applicable when
//     alt=media. (Default false)
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveMetadataReadonly
//   kGTLAuthScopeDrivePhotosReadonly
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveChannel.
+ (instancetype)queryForFilesWatchWithObject:(GTLDriveChannel *)object
                                      fileId:(NSString *)fileId;

#pragma mark - "permissions" methods
// These create a GTLQueryDrive object.

// Method: drive.permissions.create
// Creates a permission for a file.
//  Required:
//   fileId: The ID of the file.
//  Optional:
//   emailMessage: A custom message to include in the notification email.
//   sendNotificationEmail: Whether to send a notification email when sharing to
//     users or groups. This defaults to true for users and groups, and is not
//     allowed for other requests. It must not be disabled for ownership
//     transfers.
//   transferOwnership: Whether to transfer ownership to the specified user and
//     downgrade the current owner to a writer. This parameter is required as an
//     acknowledgement of the side effect. (Default false)
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
// Fetches a GTLDrivePermission.
+ (instancetype)queryForPermissionsCreateWithObject:(GTLDrivePermission *)object
                                             fileId:(NSString *)fileId;

// Method: drive.permissions.delete
// Deletes a permission.
//  Required:
//   fileId: The ID of the file.
//   permissionId: The ID of the permission.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
+ (instancetype)queryForPermissionsDeleteWithFileId:(NSString *)fileId
                                       permissionId:(NSString *)permissionId;

// Method: drive.permissions.get
// Gets a permission by ID.
//  Required:
//   fileId: The ID of the file.
//   permissionId: The ID of the permission.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveMetadataReadonly
//   kGTLAuthScopeDrivePhotosReadonly
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDrivePermission.
+ (instancetype)queryForPermissionsGetWithFileId:(NSString *)fileId
                                    permissionId:(NSString *)permissionId;

// Method: drive.permissions.list
// Lists a file's permissions.
//  Required:
//   fileId: The ID of the file.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveMetadataReadonly
//   kGTLAuthScopeDrivePhotosReadonly
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDrivePermissionList.
+ (instancetype)queryForPermissionsListWithFileId:(NSString *)fileId;

// Method: drive.permissions.update
// Updates a permission with patch semantics.
//  Required:
//   fileId: The ID of the file.
//   permissionId: The ID of the permission.
//  Optional:
//   transferOwnership: Whether to transfer ownership to the specified user and
//     downgrade the current owner to a writer. This parameter is required as an
//     acknowledgement of the side effect. (Default false)
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
// Fetches a GTLDrivePermission.
+ (instancetype)queryForPermissionsUpdateWithObject:(GTLDrivePermission *)object
                                             fileId:(NSString *)fileId
                                       permissionId:(NSString *)permissionId;

#pragma mark - "replies" methods
// These create a GTLQueryDrive object.

// Method: drive.replies.create
// Creates a new reply to a comment.
//  Required:
//   fileId: The ID of the file.
//   commentId: The ID of the comment.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
// Fetches a GTLDriveReply.
+ (instancetype)queryForRepliesCreateWithObject:(GTLDriveReply *)object
                                         fileId:(NSString *)fileId
                                      commentId:(NSString *)commentId;

// Method: drive.replies.delete
// Deletes a reply.
//  Required:
//   fileId: The ID of the file.
//   commentId: The ID of the comment.
//   replyId: The ID of the reply.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
+ (instancetype)queryForRepliesDeleteWithFileId:(NSString *)fileId
                                      commentId:(NSString *)commentId
                                        replyId:(NSString *)replyId;

// Method: drive.replies.get
// Gets a reply by ID.
//  Required:
//   fileId: The ID of the file.
//   commentId: The ID of the comment.
//   replyId: The ID of the reply.
//  Optional:
//   includeDeleted: Whether to return deleted replies. Deleted replies will not
//     include their original content. (Default false)
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveReply.
+ (instancetype)queryForRepliesGetWithFileId:(NSString *)fileId
                                   commentId:(NSString *)commentId
                                     replyId:(NSString *)replyId;

// Method: drive.replies.list
// Lists a comment's replies.
//  Required:
//   fileId: The ID of the file.
//   commentId: The ID of the comment.
//  Optional:
//   includeDeleted: Whether to include deleted replies. Deleted replies will
//     not include their original content. (Default false)
//   pageSize: The maximum number of replies to return per page. (1..100,
//     default 20)
//   pageToken: The token for continuing a previous list request on the next
//     page. This should be set to the value of 'nextPageToken' from the
//     previous response.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveReplyList.
+ (instancetype)queryForRepliesListWithFileId:(NSString *)fileId
                                    commentId:(NSString *)commentId;

// Method: drive.replies.update
// Updates a reply with patch semantics.
//  Required:
//   fileId: The ID of the file.
//   commentId: The ID of the comment.
//   replyId: The ID of the reply.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveFile
// Fetches a GTLDriveReply.
+ (instancetype)queryForRepliesUpdateWithObject:(GTLDriveReply *)object
                                         fileId:(NSString *)fileId
                                      commentId:(NSString *)commentId
                                        replyId:(NSString *)replyId;

#pragma mark - "revisions" methods
// These create a GTLQueryDrive object.

// Method: drive.revisions.delete
// Permanently deletes a revision. This method is only applicable to files with
// binary content in Drive.
//  Required:
//   fileId: The ID of the file.
//   revisionId: The ID of the revision.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
+ (instancetype)queryForRevisionsDeleteWithFileId:(NSString *)fileId
                                       revisionId:(NSString *)revisionId;

// Method: drive.revisions.get
// Gets a revision's metadata or content by ID.
//  Required:
//   fileId: The ID of the file.
//   revisionId: The ID of the revision.
//  Optional:
//   acknowledgeAbuse: Whether the user is acknowledging the risk of downloading
//     known malware or other abusive files. This is only applicable when
//     alt=media. (Default false)
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveMetadataReadonly
//   kGTLAuthScopeDrivePhotosReadonly
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveRevision.
+ (instancetype)queryForRevisionsGetWithFileId:(NSString *)fileId
                                    revisionId:(NSString *)revisionId;

// Method: drive.revisions.list
// Lists a file's revisions.
//  Required:
//   fileId: The ID of the file.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
//   kGTLAuthScopeDriveMetadata
//   kGTLAuthScopeDriveMetadataReadonly
//   kGTLAuthScopeDrivePhotosReadonly
//   kGTLAuthScopeDriveReadonly
// Fetches a GTLDriveRevisionList.
+ (instancetype)queryForRevisionsListWithFileId:(NSString *)fileId;

// Method: drive.revisions.update
// Updates a revision with patch semantics.
//  Required:
//   fileId: The ID of the file.
//   revisionId: The ID of the revision.
//  Authorization scope(s):
//   kGTLAuthScopeDrive
//   kGTLAuthScopeDriveAppdata
//   kGTLAuthScopeDriveFile
// Fetches a GTLDriveRevision.
+ (instancetype)queryForRevisionsUpdateWithObject:(GTLDriveRevision *)object
                                           fileId:(NSString *)fileId
                                       revisionId:(NSString *)revisionId;

@end
