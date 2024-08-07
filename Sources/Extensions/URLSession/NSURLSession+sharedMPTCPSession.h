/*****************************************************************************
 * NSURLSession+sharedMPTCPSession.h
 * VLC for iOS
 *****************************************************************************
 *
 * Author: Anthony Doeraene <anthony.doeraene@hotmail.com>
 *
 *****************************************************************************/

#ifndef NSURLSession_sharedMPTCPSession_h
#define NSURLSession_sharedMPTCPSession_h

@interface NSURLSession (sharedMPTCPSession)
+ (NSURLSession *) sharedMPTCPSession;
@end

#endif /* NSURLSession_sharedMPTCPSession_h */
