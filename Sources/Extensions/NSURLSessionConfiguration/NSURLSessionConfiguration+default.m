/*****************************************************************************
 * NSURLSessionConfiguration+default.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Anthony Doeraene <anthony.doeraene@hotmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

 #import <Foundation/Foundation.h>
 #include "NSURLSessionConfiguration+default.h"

 @implementation NSURLSessionConfiguration (defaultMPTCPConfiguration)
 + (NSURLSessionConfiguration *) defaultMPTCPConfiguration {
     static NSURLSessionConfiguration *defaultMPTCPConfiguration = nil;
     static dispatch_once_t onceToken;
     dispatch_once(&onceToken, ^{
         NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
         #if TARGET_OS_IOS || TARGET_OS_VISION
             // multipath is only supported on iOS 11.0+ and visionOS
             if (@available(iOS 11.0, visionOS 1.0 , *)) {
                 conf.multipathServiceType = NSURLSessionMultipathServiceTypeHandover;
             }
         #endif
         // on other platforms, the defaultMPTCPConfiguration is simply [NSURLSessionConfiguration defaultSessionConfiguration], which is a standard TCP configuration

         defaultMPTCPConfiguration = conf;
     });
     return defaultMPTCPConfiguration;
 }
 @end
