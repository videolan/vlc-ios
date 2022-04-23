/*****************************************************************************
 * VLCMediaFileDownloader.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2020-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@class VLCMedia;

@interface VLCMediaFileDownloader : NSObject

@property (nonatomic, readonly) BOOL downloadInProgress;
@property (nonatomic, retain) id delegate;
@property (readonly, copy) NSString *downloadLocationPath;

- (void)cancelDownload;
- (NSString *)downloadFileFromVLCMedia:(VLCMedia *)media withName:(NSString *)name expectedDownloadSize:(unsigned long long)expectedDownloadSize;

@end

@protocol VLCMediaFileDownloader <NSObject>
@required
- (void)mediaFileDownloadStarted:(VLCMediaFileDownloader *)theDownloader;
- (void)mediaFileDownloadEnded:(VLCMediaFileDownloader *)theDownloader;

@optional
- (void)downloadFailedWithErrorDescription:(NSString *)description forDownloader:(VLCMediaFileDownloader *)theDownloader;
- (void)progressUpdatedTo:(CGFloat)percentage receivedDataSize:(CGFloat)receivedDataSize  expectedDownloadSize:(CGFloat)expectedDownloadSize;

@end
