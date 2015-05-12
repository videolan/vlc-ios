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
- (void)downloadStarted;
- (void)downloadEnded;

@optional
- (void)downloadFailedWithErrorDescription:(NSString *)description;
- (void)progressUpdatedTo:(CGFloat)percentage receivedDataSize:(CGFloat)receivedDataSize  expectedDownloadSize:(CGFloat)expectedDownloadSize;

@end

@interface VLCHTTPFileDownloader : NSObject

@property (readonly, nonatomic) NSString *userReadableDownloadName;

@property (nonatomic, readonly) BOOL downloadInProgress;
@property (nonatomic, retain) id delegate;

- (void)cancelDownload;
- (void)downloadFileFromURL:(NSURL *)url;
- (void)downloadFileFromURL:(NSURL *)url withFileName:(NSString*) fileName;

@end
