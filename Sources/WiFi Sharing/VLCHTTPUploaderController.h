/*****************************************************************************
 * VLCHTTPUploaderController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Jean-Baptiste Kempf <jb # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@class MediaLibraryService;

@interface VLCHTTPUploaderController : NSObject

+ (nonnull instancetype)sharedInstance;

@property (readonly, nullable) NSString *nameOfUsedNetworkInterface;
@property (nonatomic, readonly) BOOL isReachable;
@property (nonatomic, readwrite, nullable) MediaLibraryService *medialibrary;

- (BOOL)changeHTTPServerState:(BOOL)state;
- (nonnull NSString *)httpStatus;
- (nonnull NSString *)addressToCopy;
- (BOOL)isServerRunning;
- (BOOL)isUsingEthernet;
- (nonnull NSString *)hostname;
- (nonnull NSString *)hostnamePort;

- (void)moveFileFrom:(nonnull NSString *)filepath;
- (void)cleanCache;
#if TARGET_OS_IOS
- (void)resetIdleTimer;
#endif

@end
