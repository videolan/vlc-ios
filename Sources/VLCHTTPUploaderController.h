/*****************************************************************************
 * VLCHTTPUploaderViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Jean-Baptiste Kempf <jb # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@class HTTPServer;

@interface VLCHTTPUploaderController : NSObject

@property (nonatomic, readonly) HTTPServer *httpServer;

- (BOOL)changeHTTPServerState:(BOOL)state;
- (NSString *)currentIPAddress;

- (void)moveFileFrom:(NSString *)filepath;

@end
