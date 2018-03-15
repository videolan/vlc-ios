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
//  GTLDriveAbout.h
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
//   GTLDriveAbout (0 custom class methods, 9 custom properties)
//   GTLDriveAboutExportFormats (0 custom class methods, 0 custom properties)
//   GTLDriveAboutImportFormats (0 custom class methods, 0 custom properties)
//   GTLDriveAboutMaxImportSizes (0 custom class methods, 0 custom properties)
//   GTLDriveAboutStorageQuota (0 custom class methods, 4 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLDriveAboutExportFormats;
@class GTLDriveAboutImportFormats;
@class GTLDriveAboutMaxImportSizes;
@class GTLDriveAboutStorageQuota;
@class GTLDriveUser;

// ----------------------------------------------------------------------------
//
//   GTLDriveAbout
//

// Information about the user, the user's Drive, and system capabilities.

@interface GTLDriveAbout : GTLObject

// Whether the user has installed the requesting app.
@property (nonatomic, retain) NSNumber *appInstalled;  // boolValue

// A map of source MIME type to possible targets for all supported exports.
@property (nonatomic, retain) GTLDriveAboutExportFormats *exportFormats;

// The currently supported folder colors as RGB hex strings.
@property (nonatomic, retain) NSArray *folderColorPalette;  // of NSString

// A map of source MIME type to possible targets for all supported imports.
@property (nonatomic, retain) GTLDriveAboutImportFormats *importFormats;

// This is always drive#about.
@property (nonatomic, copy) NSString *kind;

// A map of maximum import sizes by MIME type, in bytes.
@property (nonatomic, retain) GTLDriveAboutMaxImportSizes *maxImportSizes;

// The maximum upload size in bytes.
@property (nonatomic, retain) NSNumber *maxUploadSize;  // longLongValue

// The user's storage quota limits and usage. All fields are measured in bytes.
@property (nonatomic, retain) GTLDriveAboutStorageQuota *storageQuota;

// The authenticated user.
@property (nonatomic, retain) GTLDriveUser *user;

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveAboutExportFormats
//

@interface GTLDriveAboutExportFormats : GTLObject
// This object is documented as having more properties that are NSArrays of
// NSString. Use -additionalJSONKeys and -additionalPropertyForName: to get the
// list of properties and then fetch them; or -additionalProperties to fetch
// them all at once.
@end


// ----------------------------------------------------------------------------
//
//   GTLDriveAboutImportFormats
//

@interface GTLDriveAboutImportFormats : GTLObject
// This object is documented as having more properties that are NSArrays of
// NSString. Use -additionalJSONKeys and -additionalPropertyForName: to get the
// list of properties and then fetch them; or -additionalProperties to fetch
// them all at once.
@end


// ----------------------------------------------------------------------------
//
//   GTLDriveAboutMaxImportSizes
//

@interface GTLDriveAboutMaxImportSizes : GTLObject
// This object is documented as having more properties that are NSNumber
// (longLongValue). Use -additionalJSONKeys and -additionalPropertyForName: to
// get the list of properties and then fetch them; or -additionalProperties to
// fetch them all at once.
@end


// ----------------------------------------------------------------------------
//
//   GTLDriveAboutStorageQuota
//

@interface GTLDriveAboutStorageQuota : GTLObject

// The usage limit, if applicable. This will not be present if the user has
// unlimited storage.
@property (nonatomic, retain) NSNumber *limit;  // longLongValue

// The total usage across all services.
@property (nonatomic, retain) NSNumber *usage;  // longLongValue

// The usage by all files in Google Drive.
@property (nonatomic, retain) NSNumber *usageInDrive;  // longLongValue

// The usage by trashed files in Google Drive.
@property (nonatomic, retain) NSNumber *usageInDriveTrash;  // longLongValue

@end
