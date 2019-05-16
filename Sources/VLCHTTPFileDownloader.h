/*****************************************************************************
 * VLCHTTPFileDownloader.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@protocol VLCHTTPFileDownloader <NSObject>
@required
- (void)downloadStartedWithIdentifier:(NSString *)identifier;
- (void)downloadEndedWithIdentifier:(NSString *)identifier;

@optional
- (void)downloadFailedWithIdentifier:(NSString *)identifier errorDescription:(NSString *)description;
- (void)progressUpdatedTo:(CGFloat)percentage receivedDataSize:(CGFloat)receivedDataSize  expectedDownloadSize:(CGFloat)expectedDownloadSize identifier:(NSString *)identifier;

@end

@interface VLCHTTPFileDownloader : NSObject

@property (nonatomic, readonly) BOOL downloadInProgress;
@property (nonatomic, retain) id delegate;

- (void)cancelDownloadWithIdentifier:(NSString *)identifier;
- (NSString *)downloadFileFromURL:(NSURL *)url;
- (NSString *)downloadFileFromURL:(NSURL *)url withFileName:(NSString*)fileName;

@end
