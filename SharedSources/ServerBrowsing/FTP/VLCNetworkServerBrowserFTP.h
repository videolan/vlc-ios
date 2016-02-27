/*****************************************************************************
 * VLCNetworkServerBrowserFTP.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowser-Protocol.h"
#import "VLCNetworkServerLoginInformation.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLCNetworkServerBrowserFTP : NSObject <VLCNetworkServerBrowser>
- (instancetype)initWithLogin:(VLCNetworkServerLoginInformation *)login;
- (instancetype)initWithFTPServer:(NSString *)serverAddress userName:(nullable NSString *)username andPassword:(nullable NSString *)password atPath:(NSString *)path;
- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface VLCNetworkServerBrowserItemFTP : NSObject <VLCNetworkServerBrowserItem>

- (instancetype)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL subtitleURL:(NSURL *)subtitleURL;

@property (nonatomic, readwrite) NSArray<id<VLCNetworkServerBrowserItem>> *items;
@property (nonatomic, getter=isDownloadable, readonly) BOOL downloadable;
@property (nonatomic, readonly, nullable) NSURL *subtitleURL;

@end

NS_ASSUME_NONNULL_END
