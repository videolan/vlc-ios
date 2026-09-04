/*****************************************************************************
 * VLCURLAuthenticationHandler.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCURLAuthenticationHandler : NSObject

- (void)handleChallenge:(NSURLAuthenticationChallenge *)challenge
                 forURL:(nullable NSURL *)url
      completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler;

@end

NS_ASSUME_NONNULL_END
