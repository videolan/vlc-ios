/*****************************************************************************
 * NSURLSession+sharedMPTCPSession.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Anthony Doeraene <anthony.doeraene@hotmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

 #ifndef NSURLSession_sharedMPTCPSession_h
 #define NSURLSession_sharedMPTCPSession_h

 @interface NSURLSession (sharedMPTCPSession)
 + (NSURLSession *) sharedMPTCPSession;
 @end

 #endif /* NSURLSession_sharedMPTCPSession_h */
