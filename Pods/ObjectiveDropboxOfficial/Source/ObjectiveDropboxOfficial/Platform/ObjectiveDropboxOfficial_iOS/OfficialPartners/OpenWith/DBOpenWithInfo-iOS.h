///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///
/// Information for returning to the official Dropbox app.
///
/// @note This logic is for official Dropbox partners only, and should not need
/// to be used by other third-party apps.
///
@interface DBOpenWithInfo : NSObject <NSCoding>

/// The Dropbox user ID of the current user.
@property (nonatomic, copy, readonly) NSString *userId;

/// The Dropbox revision for the file.
@property (nonatomic, copy, readonly) NSString *rev;

/// The Dropbox path for the file.
@property (nonatomic, copy, readonly) NSString *path;

/// The time the file was modified last.
@property (nonatomic, copy, readonly, nullable) NSDate *modifiedTime;

/// Whether the file is read only or not.
@property (nonatomic, readonly) BOOL readOnly;

/// The Dropbox verb associated with the file.
@property (nonatomic, copy, readonly) NSString *verb;

/// The Dropbox session ID associated with the file.
@property (nonatomic, copy, readonly, nullable) NSString *sessionId;

/// The Dropbox file ID associated with the file.
@property (nonatomic, copy, readonly, nullable) NSString *fileId;

/// Relevant Dropbox file data associated with the file.
@property (nonatomic, copy, readonly, nullable) NSData *fileData;

/// The source application from which the file content originated.
@property (nonatomic, copy, readonly, nullable) NSString *sourceApp;

///
/// Initializer containing the parameters that we were opened with. Some of these parameters are necessary to return to
/// the originating Dropbox app. There are now two Dropbox apps: the regular Dropbox app and the Dropbox EMM app. Either
/// can open with.
///
/// @note This logic is for official Dropbox partners only, and should not need to be used by other third-party apps.
///
/// @param userId The Dropbox user ID of the current user.
/// @param rev The Dropbox revision for the file.
/// @param path The Dropbox path for the file.
/// @param modifiedTime The time the file was modified last.
/// @param readOnly Whether the file is read only.
/// @param verb The action type to be taken on the file (e.g. EDIT) supplied by the official Dropbox app.
/// @param sessionId The Dropbox session ID supplied by the official app
/// @param fileId The Dropbox file ID associated with the file
/// @param fileData Relevant Dropbox file data associated with the file.
/// @param sourceApp The source application from which the file content originated.
///
- (id)initWithUserId:(NSString *)userId
                 rev:(NSString *)rev
                path:(NSString *)path
        modifiedTime:(nullable NSDate *)modifiedTime
            readOnly:(BOOL)readOnly
                verb:(NSString *)verb
           sessionId:(nullable NSString *)sessionId
              fileId:(nullable NSString *)fileId
            fileData:(nullable NSData *)fileData
           sourceApp:(nullable NSString *)sourceApp;

///
/// Saves open with info to disc.
///
/// @note This logic is for official Dropbox partners only, and should not need to be used by other third-party apps.
///
/// @param sessionId The Dropbox session ID supplied by the official app to be used as a storage lookup key.
///
- (void)writeToStorageForSession:(nullable NSString *)sessionId;

///
/// Retrieves open with info from disc.
///
/// @note This logic is for official Dropbox partners only, and should not need to be used by other third-party apps.
///
/// @param sessionId The Dropbox session ID supplied by the official app to be used as a storage lookup key.
///
+ (nullable DBOpenWithInfo *)popFromStorageForSession:(NSString *)sessionId;

@end

NS_ASSUME_NONNULL_END
