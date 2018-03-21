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
//  GTLDriveRevision.h
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
//   GTLDriveRevision (0 custom class methods, 12 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLDriveUser;

// ----------------------------------------------------------------------------
//
//   GTLDriveRevision
//

// The metadata for a revision to a file.

@interface GTLDriveRevision : GTLObject

// The ID of the revision.
// identifier property maps to 'id' in JSON (to avoid Objective C's 'id').
@property (nonatomic, copy) NSString *identifier;

// Whether to keep this revision forever, even if it is no longer the head
// revision. If not set, the revision will be automatically purged 30 days after
// newer content is uploaded. This can be set on a maximum of 200 revisions for
// a file.
// This field is only applicable to files with binary content in Drive.
@property (nonatomic, retain) NSNumber *keepForever;  // boolValue

// This is always drive#revision.
@property (nonatomic, copy) NSString *kind;

// The last user to modify this revision.
@property (nonatomic, retain) GTLDriveUser *lastModifyingUser;

// The MD5 checksum of the revision's content. This is only applicable to files
// with binary content in Drive.
@property (nonatomic, copy) NSString *md5Checksum;

// The MIME type of the revision.
@property (nonatomic, copy) NSString *mimeType;

// The last time the revision was modified (RFC 3339 date-time).
@property (nonatomic, retain) GTLDateTime *modifiedTime;

// The original filename used to create this revision. This is only applicable
// to files with binary content in Drive.
@property (nonatomic, copy) NSString *originalFilename;

// Whether subsequent revisions will be automatically republished. This is only
// applicable to Google Docs.
@property (nonatomic, retain) NSNumber *publishAuto;  // boolValue

// Whether this revision is published. This is only applicable to Google Docs.
@property (nonatomic, retain) NSNumber *published;  // boolValue

// Whether this revision is published outside the domain. This is only
// applicable to Google Docs.
@property (nonatomic, retain) NSNumber *publishedOutsideDomain;  // boolValue

// The size of the revision's content in bytes. This is only applicable to files
// with binary content in Drive.
@property (nonatomic, retain) NSNumber *size;  // longLongValue

@end
