///
///  Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

@class DBOpenWithInfo;

NS_ASSUME_NONNULL_BEGIN

///
/// Manages returning to the official Dropbox app.
///
/// @note This logic is for official Dropbox partners only, and should not need
/// to be used by other third-party apps.
///
@interface DBOfficialAppConnector : NSObject

///
/// Full constructor.
///
/// @param appKey The consumer app key of the current third-party API app.
/// @param canOpenURLWrapper A wrapper around the `[UIApplication canOpenURL]` method call to ensure the SDK is
/// app-extension safe.
/// @param openURLWrapper A wrapper around the [UIApplication openURL] method call to ensure the SDK is app-extension
/// safe.
///
/// @return An initialized instance.
///
- (instancetype)initWithAppKey:(NSString *)appKey
             canOpenURLWrapper:(BOOL (^)(NSURL *))canOpenURLWrapper
                openURLWrapper:(void (^)(NSURL *))openURLWrapper;

///
/// Returns to the Dropbox app specified by app
///
/// @note This logic is for official Dropbox partners only, and should not need to be used by other third-party apps.
///
/// @param openWithInfo Information retrieved from a shared `UIPasteboard` that is used to return to the official
/// Dropbox app.
/// @param changesPending Whether there are changes pending in Dropbox for the file.
///
- (void)returnToDropboxApp:(DBOpenWithInfo *)openWithInfo changesPending:(BOOL)changesPending;

///
/// Returns to the Dropbox app specified by app passing along the error and a dictionary of extra information.
///
/// @note This logic is for official Dropbox partners only, and should not need to be used by other third-party apps.
///
/// @param openWithInfo Information retrieved from a shared `UIPasteboard` that is used to return to the official
/// Dropbox app.
/// @param changesPending Whether there are changes pending in Dropbox for the file.
/// @param errorName The error encoutered to pass back to the official Dropbox app.
/// @param extras Extra information to pass back to the official Dropbox app.
///
- (void)returnToDropboxApp:(DBOpenWithInfo *)openWithInfo
            changesPending:(BOOL)changesPending
                 errorName:(nullable NSString *)errorName
                    extras:(nullable NSDictionary *)extras;

///
/// Parses the url from the official Dropbox app into a `DBOpenWithInfo` object.
///
/// @param url The url from the official Dropbox app used to open the SDK.
///
/// @return Structured data parsed from the supplied url.
///
- (nullable DBOpenWithInfo *)openWithInfoFromURL:(NSURL *)url;

///
/// Determines whether an official Dropbox app is installed.
///
/// @return Whether an official Dropbox app is installed.
///
- (BOOL)isRequiredDropboxAppInstalled;

///
/// Retrieves from a shared `UIPasteboard` information used to return to the official Dropbox app.
///
/// @note This logic is for official Dropbox partners only, and should not need to be used by other third-party apps.
///
/// @return @c DBOpenWithInfo object that wraps the relevant information for returning to the official Dropbox app.
///
+ (nullable DBOpenWithInfo *)retriveOfficialDropboxAppOpenWithInfo;

@end

NS_ASSUME_NONNULL_END
