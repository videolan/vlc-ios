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
//  GTLDriveFile.m
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
//   GTLDriveFile (0 custom class methods, 44 custom properties)
//   GTLDriveFileAppProperties (0 custom class methods, 0 custom properties)
//   GTLDriveFileCapabilities (0 custom class methods, 5 custom properties)
//   GTLDriveFileContentHints (0 custom class methods, 2 custom properties)
//   GTLDriveFileImageMediaMetadata (0 custom class methods, 21 custom properties)
//   GTLDriveFileProperties (0 custom class methods, 0 custom properties)
//   GTLDriveFileVideoMediaMetadata (0 custom class methods, 3 custom properties)
//   GTLDriveFileContentHintsThumbnail (0 custom class methods, 2 custom properties)
//   GTLDriveFileImageMediaMetadataLocation (0 custom class methods, 3 custom properties)

#import "GTLDriveFile.h"

#import "GTLDrivePermission.h"
#import "GTLDriveUser.h"

// ----------------------------------------------------------------------------
//
//   GTLDriveFile
//

@implementation GTLDriveFile
@dynamic appProperties, capabilities, contentHints, createdTime,
         descriptionProperty, explicitlyTrashed, fileExtension, folderColorRgb,
         fullFileExtension, headRevisionId, iconLink, identifier,
         imageMediaMetadata, isAppAuthorized, kind, lastModifyingUser,
         md5Checksum, mimeType, modifiedByMeTime, modifiedTime, name,
         originalFilename, ownedByMe, owners, parents, permissions, properties,
         quotaBytesUsed, shared, sharedWithMeTime, sharingUser, size, spaces,
         starred, thumbnailLink, trashed, version, videoMediaMetadata,
         viewedByMe, viewedByMeTime, viewersCanCopyContent, webContentLink,
         webViewLink, writersCanShare;

+ (NSDictionary *)propertyToJSONKeyMap {
  NSDictionary *map = @{
    @"descriptionProperty" : @"description",
    @"identifier" : @"id"
  };
  return map;
}

+ (NSDictionary *)arrayPropertyToClassMap {
  NSDictionary *map = @{
    @"owners" : [GTLDriveUser class],
    @"parents" : [NSString class],
    @"permissions" : [GTLDrivePermission class],
    @"spaces" : [NSString class]
  };
  return map;
}

+ (void)load {
  [self registerObjectClassForKind:@"drive#file"];
}

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileAppProperties
//

@implementation GTLDriveFileAppProperties

+ (Class)classForAdditionalProperties {
  return [NSString class];
}

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileCapabilities
//

@implementation GTLDriveFileCapabilities
@dynamic canComment, canCopy, canEdit, canReadRevisions, canShare;
@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileContentHints
//

@implementation GTLDriveFileContentHints
@dynamic indexableText, thumbnail;
@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileImageMediaMetadata
//

@implementation GTLDriveFileImageMediaMetadata
@dynamic aperture, cameraMake, cameraModel, colorSpace, exposureBias,
         exposureMode, exposureTime, flashUsed, focalLength, height, isoSpeed,
         lens, location, maxApertureValue, meteringMode, rotation, sensor,
         subjectDistance, time, whiteBalance, width;
@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileProperties
//

@implementation GTLDriveFileProperties

+ (Class)classForAdditionalProperties {
  return [NSString class];
}

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileVideoMediaMetadata
//

@implementation GTLDriveFileVideoMediaMetadata
@dynamic durationMillis, height, width;
@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileContentHintsThumbnail
//

@implementation GTLDriveFileContentHintsThumbnail
@dynamic image, mimeType;
@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileImageMediaMetadataLocation
//

@implementation GTLDriveFileImageMediaMetadataLocation
@dynamic altitude, latitude, longitude;
@end
