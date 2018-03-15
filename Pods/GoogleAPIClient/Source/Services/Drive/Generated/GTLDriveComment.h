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
//  GTLDriveComment.h
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
//   GTLDriveComment (0 custom class methods, 12 custom properties)
//   GTLDriveCommentQuotedFileContent (0 custom class methods, 2 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLDriveCommentQuotedFileContent;
@class GTLDriveReply;
@class GTLDriveUser;

// ----------------------------------------------------------------------------
//
//   GTLDriveComment
//

// A comment on a file.

@interface GTLDriveComment : GTLObject

// A region of the document represented as a JSON string. See anchor
// documentation for details on how to define and interpret anchor properties.
@property (nonatomic, copy) NSString *anchor;

// The user who created the comment.
@property (nonatomic, retain) GTLDriveUser *author;

// The plain text content of the comment. This field is used for setting the
// content, while htmlContent should be displayed.
@property (nonatomic, copy) NSString *content;

// The time at which the comment was created (RFC 3339 date-time).
@property (nonatomic, retain) GTLDateTime *createdTime;

// Whether the comment has been deleted. A deleted comment has no content.
@property (nonatomic, retain) NSNumber *deleted;  // boolValue

// The content of the comment with HTML formatting.
@property (nonatomic, copy) NSString *htmlContent;

// The ID of the comment.
// identifier property maps to 'id' in JSON (to avoid Objective C's 'id').
@property (nonatomic, copy) NSString *identifier;

// This is always drive#comment.
@property (nonatomic, copy) NSString *kind;

// The last time the comment or any of its replies was modified (RFC 3339
// date-time).
@property (nonatomic, retain) GTLDateTime *modifiedTime;

// The file content to which the comment refers, typically within the anchor
// region. For a text file, for example, this would be the text at the location
// of the comment.
@property (nonatomic, retain) GTLDriveCommentQuotedFileContent *quotedFileContent;

// The full list of replies to the comment in chronological order.
@property (nonatomic, retain) NSArray *replies;  // of GTLDriveReply

// Whether the comment has been resolved by one of its replies.
@property (nonatomic, retain) NSNumber *resolved;  // boolValue

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveCommentQuotedFileContent
//

@interface GTLDriveCommentQuotedFileContent : GTLObject

// The MIME type of the quoted content.
@property (nonatomic, copy) NSString *mimeType;

// The quoted content itself. This is interpreted as plain text if set through
// the API.
@property (nonatomic, copy) NSString *value;

@end
