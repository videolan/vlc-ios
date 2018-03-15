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
//  GTLDriveReplyList.h
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
//   GTLDriveReplyList (0 custom class methods, 3 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLDriveReply;

// ----------------------------------------------------------------------------
//
//   GTLDriveReplyList
//

// A list of replies to a comment on a file.

@interface GTLDriveReplyList : GTLObject

// This is always drive#replyList.
@property (nonatomic, copy) NSString *kind;

// The page token for the next page of replies. This will be absent if the end
// of the replies list has been reached.
@property (nonatomic, copy) NSString *nextPageToken;

// The page of replies.
@property (nonatomic, retain) NSArray *replies;  // of GTLDriveReply

@end
