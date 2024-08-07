/*****************************************************************************
  * NSURLSessionConfiguration+default.h
  * VLC for iOS
  *****************************************************************************
  *
  * Author: Anthony Doeraene <anthony.doeraene@hotmail.com>
  *
  *****************************************************************************/

 #ifndef NSURLSessionConfiguration_default_h
 #define NSURLSessionConfiguration_default_h
 // add a static var defaultMPTCPConfiguration to NSURLSessionConfiguration
 @interface NSURLSessionConfiguration (defaultMPTCPConfiguration)
 + (NSURLSessionConfiguration *) defaultMPTCPConfiguration;
 @end
 #endif /* NSURLSessionConfiguration_default_h */
