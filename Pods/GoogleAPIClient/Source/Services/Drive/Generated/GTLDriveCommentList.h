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
//  GTLDriveCommentList.h
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
//   GTLDriveCommentList (0 custom class methods, 3 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLDriveComment;

// ----------------------------------------------------------------------------
//
//   GTLDriveCommentList
//

// A list of comments on a file.

@interface GTLDriveCommentList : GTLObject

// The page of comments.
@property (nonatomic, retain) NSArray *comments;  // of GTLDriveComment

// This is always drive#commentList.
@property (nonatomic, copy) NSString *kind;

// The page token for the next page of comments. This will be absent if the end
// of the comments list has been reached.
@property (nonatomic, copy) NSString *nextPageToken;

@end
