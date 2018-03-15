///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Umbrella import for importing as a library
///

#import "TargetConditionals.h"

#import "DBSDKImportsShared.h"

#if TARGET_OS_IOS
#import "DBSDKImports-iOS.h"
#elif TARGET_OS_OSX
#import "DBSDKImports-macOS.h"
#endif
