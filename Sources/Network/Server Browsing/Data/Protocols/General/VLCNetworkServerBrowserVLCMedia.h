/*****************************************************************************
 * VLCNetworkServerBrowserVLCMedia.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020, 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowser-Protocol.h"

NS_ASSUME_NONNULL_BEGIN
@interface VLCNetworkServerBrowserVLCMedia : NSObject <VLCNetworkServerBrowser>
- (instancetype)initWithMedia:(VLCMedia *)media options:(NSDictionary *)options;
- (instancetype)initWithMedia:(VLCMedia *)media options:(NSDictionary *)options mediaParser:(nullable VLCMediaParser *)mediaParser NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (VLCMediaParsedStatus)retrieveParsedStatus;
@end

@interface VLCNetworkServerBrowserItemVLCMedia : NSObject <VLCNetworkServerBrowserItem>
- (instancetype)initWithMedia:(VLCMedia *)media options:(NSDictionary *)mediaOptions mediaParser:(nullable VLCMediaParser *)mediaParser;
- (instancetype)initWithMedia:(VLCMedia *)media options:(NSDictionary *)mediaOptions;

@property (nonatomic, getter=isDownloadable, readonly) BOOL downloadable;
@property (nonatomic, readonly, nullable) NSURL *thumbnailURL;

@end

NS_ASSUME_NONNULL_END
