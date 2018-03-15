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
//  GTLDriveChangeList.h
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
//   GTLDriveChangeList (0 custom class methods, 4 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLDriveChange;

// ----------------------------------------------------------------------------
//
//   GTLDriveChangeList
//

// A list of changes for a user.

@interface GTLDriveChangeList : GTLObject

// The page of changes.
@property (nonatomic, retain) NSArray *changes;  // of GTLDriveChange

// This is always drive#changeList.
@property (nonatomic, copy) NSString *kind;

// The starting page token for future changes. This will be present only if the
// end of the current changes list has been reached.
@property (nonatomic, copy) NSString *newStartPageToken NS_RETURNS_NOT_RETAINED;

// The page token for the next page of changes. This will be absent if the end
// of the current changes list has been reached.
@property (nonatomic, copy) NSString *nextPageToken;

@end
