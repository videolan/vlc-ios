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
@protocol VLCMediaFileDownloaderDelegate;

@interface VLCMediaFileDownloader : NSObject

@property (nonatomic, readonly) BOOL downloadInProgress;
@property (nonatomic, retain) id<VLCMediaFileDownloaderDelegate> delegate;
@property (readonly, copy) NSString *downloadLocationPath;
@property (readonly, copy) NSString *filename;

- (void)cancelDownload;
- (NSString *)downloadFileFromVLCMedia:(VLCMedia *)media withName:(NSString *)name expectedDownloadSize:(unsigned long long)expectedDownloadSize;

@end

@protocol VLCMediaFileDownloaderDelegate <NSObject>
@required
- (void)mediaFileDownloaderDidStart:(VLCMediaFileDownloader *)downloader;
- (void)mediaFileDownloaderDidFinish:(VLCMediaFileDownloader *)downloader;
- (void)mediaFileDownloader:(VLCMediaFileDownloader *)downloader didFailWithDescription:(NSString *)description;

@optional
- (void)mediaFileDownloader:(VLCMediaFileDownloader *)downloader didUpdateReceivedBytes:(int64_t)receivedBytes expectedBytes:(int64_t)expectedBytes;

@end
