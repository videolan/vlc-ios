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
//  GTLDriveReply.h
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
//   GTLDriveReply (0 custom class methods, 9 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLDriveUser;

// ----------------------------------------------------------------------------
//
//   GTLDriveReply
//

// A reply to a comment on a file.

@interface GTLDriveReply : GTLObject

// The action the reply performed to the parent comment. Valid values are:
// - resolve
// - reopen
@property (nonatomic, copy) NSString *action;

// The user who created the reply.
@property (nonatomic, retain) GTLDriveUser *author;

// The plain text content of the reply. This field is used for setting the
// content, while htmlContent should be displayed. This is required on creates
// if no action is specified.
@property (nonatomic, copy) NSString *content;

// The time at which the reply was created (RFC 3339 date-time).
@property (nonatomic, retain) GTLDateTime *createdTime;

// Whether the reply has been deleted. A deleted reply has no content.
@property (nonatomic, retain) NSNumber *deleted;  // boolValue

// The content of the reply with HTML formatting.
@property (nonatomic, copy) NSString *htmlContent;

// The ID of the reply.
// identifier property maps to 'id' in JSON (to avoid Objective C's 'id').
@property (nonatomic, copy) NSString *identifier;

// This is always drive#reply.
@property (nonatomic, copy) NSString *kind;

// The last time the reply was modified (RFC 3339 date-time).
@property (nonatomic, retain) GTLDateTime *modifiedTime;

@end
