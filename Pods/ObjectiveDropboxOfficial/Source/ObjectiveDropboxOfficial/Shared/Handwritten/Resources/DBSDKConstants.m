///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

/// Constants for the SDK should go here.

#import <Foundation/Foundation.h>

#import "DBSDKConstants.h"

NSString *const kV2SDKVersion = @"3.2.0";
NSString *const kV2SDKDefaultUserAgentPrefix = @"OfficialDropboxObjCSDKv2";
NSString *const kForegroundSessionId = @"com.dropbox.dropbox_sdk_obj_c_foreground";
NSString *const kBackgroundSessionId = @"com.dropbox.dropbox_sdk_obj_c_background";

// BEGIN DEBUG CONSTANTS
BOOL const kSDKDebug = NO;           // Should never be `YES` in production
NSString *const kSDKDebugHost = nil; // `"dbdev"`, if using EC, or "{user_name}-dbx"`, if dev box.
                                     // Should never be non-`nil` in production.
// END DEBUG CONSTANTS
