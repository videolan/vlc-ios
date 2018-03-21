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
//  GTLDriveAbout.m
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

#import "GTLDriveAbout.h"

#import "GTLDriveUser.h"

// ----------------------------------------------------------------------------
//
//   GTLDriveAbout
//

@implementation GTLDriveAbout
@dynamic appInstalled, exportFormats, folderColorPalette, importFormats, kind,
         maxImportSizes, maxUploadSize, storageQuota, user;

+ (NSDictionary *)arrayPropertyToClassMap {
  NSDictionary *map = @{
    @"folderColorPalette" : [NSString class]
  };
  return map;
}

+ (void)load {
  [self registerObjectClassForKind:@"drive#about"];
}

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveAboutExportFormats
//

@implementation GTLDriveAboutExportFormats

+ (Class)classForAdditionalProperties {
  return [NSString class];
}

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveAboutImportFormats
//

@implementation GTLDriveAboutImportFormats

+ (Class)classForAdditionalProperties {
  return [NSString class];
}

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveAboutMaxImportSizes
//

@implementation GTLDriveAboutMaxImportSizes

+ (Class)classForAdditionalProperties {
  return [NSNumber class];
}

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveAboutStorageQuota
//

@implementation GTLDriveAboutStorageQuota
@dynamic limit, usage, usageInDrive, usageInDriveTrash;
@end
