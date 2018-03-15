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
//  GTLDriveFile.h
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

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLDriveFileAppProperties;
@class GTLDriveFileCapabilities;
@class GTLDriveFileContentHints;
@class GTLDriveFileContentHintsThumbnail;
@class GTLDriveFileImageMediaMetadata;
@class GTLDriveFileImageMediaMetadataLocation;
@class GTLDriveFileProperties;
@class GTLDriveFileVideoMediaMetadata;
@class GTLDrivePermission;
@class GTLDriveUser;

// ----------------------------------------------------------------------------
//
//   GTLDriveFile
//

// The metadata for a file.

@interface GTLDriveFile : GTLObject

// A collection of arbitrary key-value pairs which are private to the requesting
// app.
// Entries with null values are cleared in update and copy requests.
@property (nonatomic, retain) GTLDriveFileAppProperties *appProperties;

// Capabilities the current user has on the file.
@property (nonatomic, retain) GTLDriveFileCapabilities *capabilities;

// Additional information about the content of the file. These fields are never
// populated in responses.
@property (nonatomic, retain) GTLDriveFileContentHints *contentHints;

// The time at which the file was created (RFC 3339 date-time).
@property (nonatomic, retain) GTLDateTime *createdTime;

// A short description of the file.
// Remapped to 'descriptionProperty' to avoid NSObject's 'description'.
@property (nonatomic, copy) NSString *descriptionProperty;

// Whether the file has been explicitly trashed, as opposed to recursively
// trashed from a parent folder.
@property (nonatomic, retain) NSNumber *explicitlyTrashed;  // boolValue

// The final component of fullFileExtension. This is only available for files
// with binary content in Drive.
@property (nonatomic, copy) NSString *fileExtension;

// The color for a folder as an RGB hex string. The supported colors are
// published in the folderColorPalette field of the About resource.
// If an unsupported color is specified, the closest color in the palette will
// be used instead.
@property (nonatomic, copy) NSString *folderColorRgb;

// The full file extension extracted from the name field. May contain multiple
// concatenated extensions, such as "tar.gz". This is only available for files
// with binary content in Drive.
// This is automatically updated when the name field changes, however it is not
// cleared if the new name does not contain a valid extension.
@property (nonatomic, copy) NSString *fullFileExtension;

// The ID of the file's head revision. This is currently only available for
// files with binary content in Drive.
@property (nonatomic, copy) NSString *headRevisionId;

// A static, unauthenticated link to the file's icon.
@property (nonatomic, copy) NSString *iconLink;

// The ID of the file.
// identifier property maps to 'id' in JSON (to avoid Objective C's 'id').
@property (nonatomic, copy) NSString *identifier;

// Additional metadata about image media, if available.
@property (nonatomic, retain) GTLDriveFileImageMediaMetadata *imageMediaMetadata;

// Whether the file was created or opened by the requesting app.
@property (nonatomic, retain) NSNumber *isAppAuthorized;  // boolValue

// This is always drive#file.
@property (nonatomic, copy) NSString *kind;

// The last user to modify the file.
@property (nonatomic, retain) GTLDriveUser *lastModifyingUser;

// The MD5 checksum for the content of the file. This is only applicable to
// files with binary content in Drive.
@property (nonatomic, copy) NSString *md5Checksum;

// The MIME type of the file.
// Drive will attempt to automatically detect an appropriate value from uploaded
// content if no value is provided. The value cannot be changed unless a new
// revision is uploaded.
// If a file is created with a Google Doc MIME type, the uploaded content will
// be imported if possible. The supported import formats are published in the
// About resource.
@property (nonatomic, copy) NSString *mimeType;

// The last time the file was modified by the user (RFC 3339 date-time).
@property (nonatomic, retain) GTLDateTime *modifiedByMeTime;

// The last time the file was modified by anyone (RFC 3339 date-time).
// Note that setting modifiedTime will also update modifiedByMeTime for the
// user.
@property (nonatomic, retain) GTLDateTime *modifiedTime;

// The name of the file. This is not necessarily unique within a folder.
@property (nonatomic, copy) NSString *name;

// The original filename of the uploaded content if available, or else the
// original value of the name field. This is only available for files with
// binary content in Drive.
@property (nonatomic, copy) NSString *originalFilename;

// Whether the user owns the file.
@property (nonatomic, retain) NSNumber *ownedByMe;  // boolValue

// The owners of the file. Currently, only certain legacy files may have more
// than one owner.
@property (nonatomic, retain) NSArray *owners;  // of GTLDriveUser

// The IDs of the parent folders which contain the file.
// If not specified as part of a create request, the file will be placed
// directly in the My Drive folder. Update requests must use the addParents and
// removeParents parameters to modify the values.
@property (nonatomic, retain) NSArray *parents;  // of NSString

// The full list of permissions for the file. This is only available if the
// requesting user can share the file.
@property (nonatomic, retain) NSArray *permissions;  // of GTLDrivePermission

// A collection of arbitrary key-value pairs which are visible to all apps.
// Entries with null values are cleared in update and copy requests.
@property (nonatomic, retain) GTLDriveFileProperties *properties;

// The number of storage quota bytes used by the file. This includes the head
// revision as well as previous revisions with keepForever enabled.
@property (nonatomic, retain) NSNumber *quotaBytesUsed;  // longLongValue

// Whether the file has been shared.
@property (nonatomic, retain) NSNumber *shared;  // boolValue

// The time at which the file was shared with the user, if applicable (RFC 3339
// date-time).
@property (nonatomic, retain) GTLDateTime *sharedWithMeTime;

// The user who shared the file with the requesting user, if applicable.
@property (nonatomic, retain) GTLDriveUser *sharingUser;

// The size of the file's content in bytes. This is only applicable to files
// with binary content in Drive.
@property (nonatomic, retain) NSNumber *size;  // longLongValue

// The list of spaces which contain the file. The currently supported values are
// 'drive', 'appDataFolder' and 'photos'.
@property (nonatomic, retain) NSArray *spaces;  // of NSString

// Whether the user has starred the file.
@property (nonatomic, retain) NSNumber *starred;  // boolValue

// A short-lived link to the file's thumbnail, if available. Typically lasts on
// the order of hours.
@property (nonatomic, copy) NSString *thumbnailLink;

// Whether the file has been trashed, either explicitly or from a trashed parent
// folder. Only the owner may trash a file, and other users cannot see files in
// the owner's trash.
@property (nonatomic, retain) NSNumber *trashed;  // boolValue

// A monotonically increasing version number for the file. This reflects every
// change made to the file on the server, even those not visible to the user.
@property (nonatomic, retain) NSNumber *version;  // longLongValue

// Additional metadata about video media. This may not be available immediately
// upon upload.
@property (nonatomic, retain) GTLDriveFileVideoMediaMetadata *videoMediaMetadata;

// Whether the file has been viewed by this user.
@property (nonatomic, retain) NSNumber *viewedByMe;  // boolValue

// The last time the file was viewed by the user (RFC 3339 date-time).
@property (nonatomic, retain) GTLDateTime *viewedByMeTime;

// Whether users with only reader or commenter permission can copy the file's
// content. This affects copy, download, and print operations.
@property (nonatomic, retain) NSNumber *viewersCanCopyContent;  // boolValue

// A link for downloading the content of the file in a browser. This is only
// available for files with binary content in Drive.
@property (nonatomic, copy) NSString *webContentLink;

// A link for opening the file in a relevant Google editor or viewer in a
// browser.
@property (nonatomic, copy) NSString *webViewLink;

// Whether users with only writer permission can modify the file's permissions.
@property (nonatomic, retain) NSNumber *writersCanShare;  // boolValue

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileAppProperties
//

@interface GTLDriveFileAppProperties : GTLObject
// This object is documented as having more properties that are NSString. Use
// -additionalJSONKeys and -additionalPropertyForName: to get the list of
// properties and then fetch them; or -additionalProperties to fetch them all at
// once.
@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileCapabilities
//

@interface GTLDriveFileCapabilities : GTLObject

// Whether the user can comment on the file.
@property (nonatomic, retain) NSNumber *canComment;  // boolValue

// Whether the user can copy the file.
@property (nonatomic, retain) NSNumber *canCopy;  // boolValue

// Whether the user can edit the file's content.
@property (nonatomic, retain) NSNumber *canEdit;  // boolValue

// Whether the current user has read access to the Revisions resource of the
// file.
@property (nonatomic, retain) NSNumber *canReadRevisions;  // boolValue

// Whether the user can modify the file's permissions and sharing settings.
@property (nonatomic, retain) NSNumber *canShare;  // boolValue

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileContentHints
//

@interface GTLDriveFileContentHints : GTLObject

// Text to be indexed for the file to improve fullText queries. This is limited
// to 128KB in length and may contain HTML elements.
@property (nonatomic, copy) NSString *indexableText;

// A thumbnail for the file. This will only be used if Drive cannot generate a
// standard thumbnail.
@property (nonatomic, retain) GTLDriveFileContentHintsThumbnail *thumbnail;

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileImageMediaMetadata
//

@interface GTLDriveFileImageMediaMetadata : GTLObject

// The aperture used to create the photo (f-number).
@property (nonatomic, retain) NSNumber *aperture;  // floatValue

// The make of the camera used to create the photo.
@property (nonatomic, copy) NSString *cameraMake;

// The model of the camera used to create the photo.
@property (nonatomic, copy) NSString *cameraModel;

// The color space of the photo.
@property (nonatomic, copy) NSString *colorSpace;

// The exposure bias of the photo (APEX value).
@property (nonatomic, retain) NSNumber *exposureBias;  // floatValue

// The exposure mode used to create the photo.
@property (nonatomic, copy) NSString *exposureMode;

// The length of the exposure, in seconds.
@property (nonatomic, retain) NSNumber *exposureTime;  // floatValue

// Whether a flash was used to create the photo.
@property (nonatomic, retain) NSNumber *flashUsed;  // boolValue

// The focal length used to create the photo, in millimeters.
@property (nonatomic, retain) NSNumber *focalLength;  // floatValue

// The height of the image in pixels.
@property (nonatomic, retain) NSNumber *height;  // intValue

// The ISO speed used to create the photo.
@property (nonatomic, retain) NSNumber *isoSpeed;  // intValue

// The lens used to create the photo.
@property (nonatomic, copy) NSString *lens;

// Geographic location information stored in the image.
@property (nonatomic, retain) GTLDriveFileImageMediaMetadataLocation *location;

// The smallest f-number of the lens at the focal length used to create the
// photo (APEX value).
@property (nonatomic, retain) NSNumber *maxApertureValue;  // floatValue

// The metering mode used to create the photo.
@property (nonatomic, copy) NSString *meteringMode;

// The rotation in clockwise degrees from the image's original orientation.
@property (nonatomic, retain) NSNumber *rotation;  // intValue

// The type of sensor used to create the photo.
@property (nonatomic, copy) NSString *sensor;

// The distance to the subject of the photo, in meters.
@property (nonatomic, retain) NSNumber *subjectDistance;  // intValue

// The date and time the photo was taken (EXIF DateTime).
@property (nonatomic, copy) NSString *time;

// The white balance mode used to create the photo.
@property (nonatomic, copy) NSString *whiteBalance;

// The width of the image in pixels.
@property (nonatomic, retain) NSNumber *width;  // intValue

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileProperties
//

@interface GTLDriveFileProperties : GTLObject
// This object is documented as having more properties that are NSString. Use
// -additionalJSONKeys and -additionalPropertyForName: to get the list of
// properties and then fetch them; or -additionalProperties to fetch them all at
// once.
@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileVideoMediaMetadata
//

@interface GTLDriveFileVideoMediaMetadata : GTLObject

// The duration of the video in milliseconds.
@property (nonatomic, retain) NSNumber *durationMillis;  // longLongValue

// The height of the video in pixels.
@property (nonatomic, retain) NSNumber *height;  // intValue

// The width of the video in pixels.
@property (nonatomic, retain) NSNumber *width;  // intValue

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileContentHintsThumbnail
//

@interface GTLDriveFileContentHintsThumbnail : GTLObject

// The thumbnail data encoded with URL-safe Base64 (RFC 4648 section 5).
@property (nonatomic, copy) NSString *image;  // GTLBase64 can encode/decode (probably web-safe format)

// The MIME type of the thumbnail.
@property (nonatomic, copy) NSString *mimeType;

@end


// ----------------------------------------------------------------------------
//
//   GTLDriveFileImageMediaMetadataLocation
//

@interface GTLDriveFileImageMediaMetadataLocation : GTLObject

// The altitude stored in the image.
@property (nonatomic, retain) NSNumber *altitude;  // doubleValue

// The latitude stored in the image.
@property (nonatomic, retain) NSNumber *latitude;  // doubleValue

// The longitude stored in the image.
@property (nonatomic, retain) NSNumber *longitude;  // doubleValue

@end
