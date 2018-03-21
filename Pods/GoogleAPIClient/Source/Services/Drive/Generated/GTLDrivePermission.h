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
//  GTLDrivePermission.h
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
//   GTLDrivePermission (0 custom class methods, 9 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

// ----------------------------------------------------------------------------
//
//   GTLDrivePermission
//

// A permission for a file. A permission grants a user, group, domain or the
// world access to a file or a folder hierarchy.

@interface GTLDrivePermission : GTLObject

// Whether the permission allows the file to be discovered through search. This
// is only applicable for permissions of type domain or anyone.
@property (nonatomic, retain) NSNumber *allowFileDiscovery;  // boolValue

// A displayable name for users, groups or domains.
@property (nonatomic, copy) NSString *displayName;

// The domain to which this permission refers.
@property (nonatomic, copy) NSString *domain;

// The email address of the user or group to which this permission refers.
@property (nonatomic, copy) NSString *emailAddress;

// The ID of this permission. This is a unique identifier for the grantee, and
// is published in User resources as permissionId.
// identifier property maps to 'id' in JSON (to avoid Objective C's 'id').
@property (nonatomic, copy) NSString *identifier;

// This is always drive#permission.
@property (nonatomic, copy) NSString *kind;

// A link to the user's profile photo, if available.
@property (nonatomic, copy) NSString *photoLink;

// The role granted by this permission. Valid values are:
// - owner
// - writer
// - commenter
// - reader
@property (nonatomic, copy) NSString *role;

// The type of the grantee. Valid values are:
// - user
// - group
// - domain
// - anyone
@property (nonatomic, copy) NSString *type;

@end
