/*****************************************************************************
 * VLCHTTPFileDownloader.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013, 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMediaFileDownloader.h"

@interface VLCHTTPFileDownloader : VLCMediaFileDownloader

- (void)cancelDownload;
- (NSString *)downloadFileFromVLCMedia:(VLCMedia *)media withName:(NSString *)name expectedDownloadSize:(unsigned long long)expectedDownloadSize;

@end
