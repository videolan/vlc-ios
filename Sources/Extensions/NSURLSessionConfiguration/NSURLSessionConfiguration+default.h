/*****************************************************************************
 * NSURLSessionConfiguration+default.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Anthony Doeraene <anthony.doeraene@hotmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

 #ifndef NSURLSessionConfiguration_default_h
 #define NSURLSessionConfiguration_default_h
 // add a static var defaultMPTCPConfiguration to NSURLSessionConfiguration
 @interface NSURLSessionConfiguration (defaultMPTCPConfiguration)
 + (NSURLSessionConfiguration *) defaultMPTCPConfiguration;
 @end
 #endif /* NSURLSessionConfiguration_default_h */
