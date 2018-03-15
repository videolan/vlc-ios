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
//  GTLDriveChange.h
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
//   GTLDriveChange (0 custom class methods, 5 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLDriveFile;

// ----------------------------------------------------------------------------
//
//   GTLDriveChange
//

// A change to a file.

@interface GTLDriveChange : GTLObject

// The updated state of the file. Present if the file has not been removed.
@property (nonatomic, retain) GTLDriveFile *file;

// The ID of the file which has changed.
@property (nonatomic, copy) NSString *fileId;

// This is always drive#change.
@property (nonatomic, copy) NSString *kind;

// Whether the file has been removed from the view of the changes list, for
// example by deletion or lost access.
@property (nonatomic, retain) NSNumber *removed;  // boolValue

// The time of this change (RFC 3339 date-time).
@property (nonatomic, retain) GTLDateTime *time;

@end
